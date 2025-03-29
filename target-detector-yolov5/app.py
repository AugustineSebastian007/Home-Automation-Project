from flask import Flask, render_template, Response
import cv2
import torch
import numpy as np
import pygame
import warnings
import os
from firebase_admin import credentials, firestore, initialize_app, auth
from email.mime.text import MIMEText
from email.mime.image import MIMEImage
from email.mime.multipart import MIMEMultipart
import smtplib
import io
import time

app = Flask(__name__)

@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    return response

warnings.filterwarnings('ignore', category=FutureWarning)

# Get the absolute path to the script's directory
import os
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Initialize global variables with absolute paths
path_alarm = os.path.join(BASE_DIR, "Alarm", "alarm.wav")
video_path = os.path.join(BASE_DIR, "TestVideos", "thief_video.mp4")
service_account_path = os.path.join(BASE_DIR, "serviceAccountKey.json")

# Initialize pygame
pygame.init()
pygame.mixer.music.load(path_alarm)

# Initialize Firebase with absolute path
cred = credentials.Certificate(service_account_path)
initialize_app(cred)
db = firestore.client()

# Loading the model and forcing CPU usage
model = torch.hub.load('ultralytics/yolov5', 'yolov5s', pretrained=True)
model = model.to('cpu')  # Force CPU usage
model.eval()  # Set model to evaluation mode

target_classes = ['car', 'bus', 'truck', 'person']
pts = []
count = 0
number_of_photos = 3

# Initialize video capture with lower resolution
cap = cv2.VideoCapture(video_path)
fps = cap.get(cv2.CAP_PROP_FPS)
frame_interval = 2  # Process every nth frame

# Add at the top with other global variables
detected_frames = []
last_email_time = time.time()
EMAIL_INTERVAL = 15  # seconds to collect images before sending
MAX_IMAGES = 5  # maximum number of images to collect

def inside_polygon(point, polygon):
    result = cv2.pointPolygonTest(polygon, (point[0], point[1]), False)
    return result == 1

def preprocess(img):
    # Reduce resolution for faster processing
    height, width = img.shape[:2]
    ratio = height / width
    img = cv2.resize(img, (640, int(640 * ratio)))
    return img

def get_camera_boundary(feed_path='feed1', user_id='1R05PQZRwPdB7mYnqiCOefAv5Jb2'):
    """Fetch camera boundary points from Firestore"""
    try:
        print("Attempting to fetch boundaries...")
        
        doc_ref = db.collection('users').document(user_id)\
                   .collection('camera').document(feed_path)\
                   .collection('boundaries').document('main')
        doc = doc_ref.get()
        
        if doc.exists:
            data = doc.to_dict()
            points_dict = data.get('points', [])
            # Just store the original points, we'll scale them later
            points = [[int(p['x']), int(p['y'])] for p in points_dict]
            print("Successfully fetched boundary points:", points)
            return points
        else:
            print(f"Document not found at path: users/{user_id}/camera/{feed_path}/boundaries/main")
            return []
    except Exception as e:
        print(f"Error fetching boundary points: {str(e)}")
        print(f"Full error details: {type(e).__name__}")
        return []

def scale_points(points, original_size, new_size):
    """Scale points according to new image dimensions and adjust offset"""
    if not points:
        return points
        
    scale_x = new_size[0] / original_size[0]
    scale_y = new_size[1] / original_size[1]
    
    # Add offset adjustment (you can tune these values)
    offset_x = 90  # pixels to move right
    offset_y = 70  # pixels to move down
    
    scaled_points = [[int(p[0] * scale_x + offset_x), int(p[1] * scale_y + offset_y)] for p in points]
    return scaled_points

def get_user_email(user_id):
    """Fetch user's email directly from Firebase Auth"""
    try:
        print(f"Attempting to fetch email for user ID: {user_id}")
        
        # Get user data directly from Firebase Auth
        user = auth.get_user(user_id)
        email = user.email
        
        if not email:
            print("No email found for user")
            return None
            
        print(f"Successfully retrieved email: {email}")
        return email
        
    except auth.AuthError as e:
        print(f"Firebase Auth Error: {str(e)}")
        print(f"Full error details: {type(e).__name__}")
        return None
    except Exception as e:
        print(f"Error fetching user email: {str(e)}")
        print(f"Full error details: {type(e).__name__}")
        return None

def send_email_alert(frames, user_email):
    """Send email alert with multiple detected images"""
    try:
        print(f"Attempting to send email alert with {len(frames)} images to: {user_email}")
        
        sender_email = os.environ.get('EMAIL_ADDRESS', 'intellihome6@gmail.com')
        sender_password = os.environ.get('EMAIL_APP_PASSWORD', 'hzev acdz fcax bepz')
        
        msg = MIMEMultipart()
        msg['Subject'] = f'Security Alert - {len(frames)} Detections!'
        msg['From'] = sender_email
        msg['To'] = user_email
        
        # Add text
        text = MIMEText(f"Multiple detections occurred in your monitored area.\nTotal detections: {len(frames)}")
        msg.attach(text)
        
        # Attach all images
        print("Processing and attaching images...")
        for i, frame in enumerate(frames):
            _, img_encoded = cv2.imencode('.jpg', frame)
            img_bytes = io.BytesIO(img_encoded.tobytes())
            image = MIMEImage(img_bytes.read())
            image.add_header('Content-Disposition', f'attachment; filename="detection_{i+1}.jpg"')
            msg.attach(image)
        
        print("Connecting to SMTP server...")
        with smtplib.SMTP('smtp.gmail.com', 587) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.send_message(msg)
            
        print("Email alert with multiple images sent successfully!")
    except Exception as e:
        print(f"Error sending email: {str(e)}")
        print(f"Full error details: {type(e).__name__}")
        print(f"Error occurred at line: {e.__traceback__.tb_lineno}")

def generate_frames():
    global count, detected_frames, last_email_time
    frame_count = 0
    
    # Get original frame size
    ret, first_frame = cap.read()
    if not ret:
        return
    original_size = first_frame.shape[1::-1]  # width, height
    cap.set(cv2.CAP_PROP_POS_FRAMES, 0)  # Reset video to start
    
    # Fetch boundary points once at the start
    boundary_points = get_camera_boundary()
    if boundary_points:
        print("Original boundary points:", boundary_points)
    else:
        print("No boundary points available - detection area not defined")
    
    while True:
        ret, frame = cap.read()
        if not ret:
            cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
            continue
            
        frame_count += 1
        if frame_count % frame_interval != 0:
            continue
            
        frame_detected = frame.copy()
        frame = preprocess(frame)
        current_size = frame.shape[1::-1]  # width, height
        
        # Scale boundary points according to current frame size
        scaled_boundary_points = scale_points(boundary_points, original_size, current_size)
        
        # Convert to RGB for model inference
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Force CPU tensor and reduce precision
        with torch.no_grad():  # Disable gradient calculation
            results = model(frame_rgb, size=320)  # Reduced inference size further

        for index, row in results.pandas().xyxy[0].iterrows():
            center_x = None
            center_y = None

            if row['name'] in target_classes:
                name = str(row['name'])
                x1 = int(row['xmin'])
                y1 = int(row['ymin'])
                x2 = int(row['xmax'])
                y2 = int(row['ymax'])

                center_x = int((x1 + x2) / 2)
                center_y = int((y1 + y2) / 2)
                
                cv2.rectangle(frame, (x1, y1), (x2, y2), (255, 255, 0), 3)
                cv2.putText(frame, name, (x1, y1), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 0), 2)
                cv2.circle(frame, (center_x, center_y), 5, (0, 0, 255), -1)

            if scaled_boundary_points:
                frame_copy = frame.copy()
                cv2.fillPoly(frame_copy, np.array([scaled_boundary_points]), (0, 255, 0))
                frame = cv2.addWeighted(frame_copy, 0.1, frame, 0.9, 0)
                
                if center_x is not None and center_y is not None:
                    if inside_polygon((center_x, center_y), np.array([scaled_boundary_points])) and name == 'person':
                        # Create mask and get detected portion
                        mask = np.zeros_like(frame_detected)
                        points = np.array([[x1, y1], [x1, y2], [x2, y2], [x2, y1]])
                        points = points.reshape((-1, 1, 2))
                        mask = cv2.fillPoly(mask, [points], (255, 255, 255))             
                        frame_detected = cv2.bitwise_and(frame_detected, mask)
                        
                        current_time = time.time()
                        
                        # Add frame to collection if we haven't reached max
                        if len(detected_frames) < MAX_IMAGES:
                            detected_frames.append(frame_detected)
                            print(f"Added detection {len(detected_frames)} of {MAX_IMAGES}")
                        
                        # Send email if we've collected enough images or enough time has passed
                        if (len(detected_frames) >= MAX_IMAGES or 
                            (current_time - last_email_time >= EMAIL_INTERVAL and detected_frames)):
                            print("\nSending collected detections...")
                            user_email = get_user_email('1R05PQZRwPdB7mYnqiCOefAv5Jb2')
                            if user_email:
                                send_email_alert(detected_frames, user_email)
                                detected_frames = []  # Clear the collection
                                last_email_time = current_time
                            else:
                                print("Could not retrieve user email - skipping alert")
                        
                        # Play alarm sound
                        if not pygame.mixer.music.get_busy():
                            pygame.mixer.music.play()
                        
                        # Add visual indicators
                        cv2.putText(frame, "Target", (center_x, center_y), 
                                  cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
                        cv2.putText(frame, "Person Detected", (20, 20), 
                                  cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
                        cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 0, 255), 3)

        ret, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
        frame = buffer.tobytes()
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/video_feed')
def video_feed():
    return Response(generate_frames(), 
                    mimetype='multipart/x-mixed-replace; boundary=frame')


if __name__ == '__main__':
    if not os.path.exists('Detected Photos'):
        os.makedirs('Detected Photos')
    app.run(host='0.0.0.0', port=5000, debug=True) 