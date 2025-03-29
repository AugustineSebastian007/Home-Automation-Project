from sklearn.neighbors import KNeighborsClassifier
import cv2
import pickle
import numpy as np
import os
import csv
import time
from datetime import datetime
from flask import Flask, Response, render_template, request
import threading
import firebase_admin
from firebase_admin import firestore
from firebase_admin import credentials

from win32com.client import Dispatch

app = Flask(__name__)

# Global variable to control video streaming
video_streaming = True

# Get absolute path to serviceAccountKey.json
import os
current_dir = os.path.dirname(os.path.abspath(__file__))
service_account_path = os.path.join(current_dir, 'serviceAccountKey.json')

# Initialize Firebase with absolute path
cred = credentials.Certificate(service_account_path)
firebase_admin.initialize_app(cred)
db = firestore.client()

# Initialize Firebase collection references
attendance_ref = db.collection('users').document('1R05PQZRwPdB7mYnqiCOefAv5Jb2').collection('attendance')
household_members_ref = db.collection('users').document('1R05PQZRwPdB7mYnqiCOefAv5Jb2').collection('household_members')

attendance_marked = False  # Global variable to track attendance marking
attendance_type = None  # Will store 'entry' or 'exit'

def speak(str1):
    speak=Dispatch(("SAPI.SpVoice"))
    speak.Speak(str1)

# Get absolute paths
current_dir = os.path.dirname(os.path.abspath(__file__))
cascade_path = os.path.join(current_dir, 'data', 'haarcascade_frontalface_default.xml')

video = cv2.VideoCapture(0)
facedetect = cv2.CascadeClassifier(cascade_path)

def load_firebase_face_data():
    """Load face data and names from Firebase household_members collection"""
    faces = []
    names = []
    
    # Get all household members
    members = household_members_ref.stream()
    
    for member in members:
        member_data = member.to_dict()
        if 'faceData' in member_data:
            # Convert face data arrays to numpy arrays
            face_arrays = []
            for key in member_data['faceData']:
                if key.startswith('face_'):
                    face_array = np.array(member_data['faceData'][key])
                    face_arrays.append(face_array)
            
            # Add all face variations for this person
            faces.extend(face_arrays)
            # Add the name for each face variation
            names.extend([member_data['name']] * len(face_arrays))
    
    return np.array(faces), np.array(names)

try:
    FACES, LABELS = load_firebase_face_data()
    if len(FACES) == 0 or len(LABELS) == 0:
        raise ValueError("No face data found in Firebase")
        
    print('Number of faces:', len(FACES))
    print('Number of labels:', len(LABELS))
    
    # Make sure FACES and LABELS have the same length
    min_length = min(len(FACES), len(LABELS))
    FACES = FACES[:min_length]
    LABELS = LABELS[:min_length]
    
    print('Shape of Faces matrix --> ', FACES.shape)
    
    knn = KNeighborsClassifier(n_neighbors=5)
    knn.fit(FACES, LABELS)
    
except Exception as e:
    print(f"Error loading face data: {str(e)}")
    # Handle the error appropriately

COL_NAMES = ['NAME', 'TIME']

def generate_frames():
    global video_streaming, attendance_marked
    while video_streaming:
        ret, frame = video.read()
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = facedetect.detectMultiScale(gray, 1.3, 5)
        for (x,y,w,h) in faces:
            # Instead of resizing to 50x50, just use the face coordinates
            face_features = np.array([x, y, w, h]).reshape(1, -1)
            output = knn.predict(face_features)
            ts = time.time()
            date = datetime.fromtimestamp(ts).strftime("%d-%m-%Y")
            timestamp = datetime.fromtimestamp(ts).strftime("%H:%M-%S")
            
            if attendance_marked:
                record_attendance(str(output[0]), ts)
                attendance_marked = False
            
            cv2.rectangle(frame, (x,y), (x+w, y+h), (0,0,255), 1)
            cv2.rectangle(frame,(x,y),(x+w,y+h),(50,50,255),2)
            cv2.rectangle(frame,(x,y-40),(x+w,y),(50,50,255),-1)
            cv2.putText(frame, str(output[0]), (x,y-15), cv2.FONT_HERSHEY_COMPLEX, 1, (255,255,255), 1)
            cv2.rectangle(frame, (x,y), (x+w, y+h), (50,50,255), 1)
            attendance=[str(output[0]), str(timestamp)]
        # imgBackground[162:162 + 480, 55:55 + 640] = frame
        
        # Instead, directly show the frame
        ret, buffer = cv2.imencode('.jpg', frame)
        frame = buffer.tobytes()
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/video_feed')
def video_feed():
    return Response(generate_frames(), mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/mark_attendance', methods=['POST'])
def mark_attendance():
    global attendance_marked, attendance_type
    attendance_marked = True
    data = request.get_json()
    attendance_type = data.get('type', 'entry')
    return '', 204

def record_attendance(name, timestamp):
    """Record attendance and update profile status in Firebase"""
    try:
        # Record attendance as before
        date = datetime.fromtimestamp(timestamp).strftime("%Y-%m-%d")
        date_ref = attendance_ref.document(date)
        
        # Find the household member by name to get their ID
        members = household_members_ref.where('name', '==', name).stream()
        member_id = None
        
        for member in members:
            member_id = member.id
            break
            
        if member_id:
            # Get the member's profiles collection
            profiles_ref = household_members_ref.document(member_id).collection('profiles')
            profiles = profiles_ref.stream()
            
            # Update all profiles for this member
            for profile in profiles:
                profile_ref = profiles_ref.document(profile.id)
                profile_ref.update({
                    'isActive': attendance_type == 'entry'  # True for entry, False for exit
                })
        
        # Record attendance data
        doc = date_ref.get()
        if doc.exists:
            attendance_data = doc.to_dict()
            if name not in attendance_data:
                attendance_data[name] = {
                    'first_entry': timestamp if attendance_type == 'entry' else None,
                    'last_exit': timestamp if attendance_type == 'exit' else None,
                    'entries': 1 if attendance_type == 'entry' else 0,
                    'exits': 1 if attendance_type == 'exit' else 0,
                    'current_status': 'in' if attendance_type == 'entry' else 'out'
                }
            else:
                if attendance_type == 'entry':
                    attendance_data[name]['entries'] += 1
                    attendance_data[name]['last_entry'] = timestamp
                    attendance_data[name]['current_status'] = 'in'
                else:  # exit
                    attendance_data[name]['exits'] += 1
                    attendance_data[name]['last_exit'] = timestamp
                    attendance_data[name]['current_status'] = 'out'
            
            date_ref.update(attendance_data)
        else:
            date_ref.set({
                name: {
                    'first_entry': timestamp if attendance_type == 'entry' else None,
                    'last_exit': timestamp if attendance_type == 'exit' else None,
                    'entries': 1 if attendance_type == 'entry' else 0,
                    'exits': 1 if attendance_type == 'exit' else 0,
                    'current_status': 'in' if attendance_type == 'entry' else 'out'
                }
            })
            
        # Add voice feedback
        speak(f"{name} {'entered' if attendance_type == 'entry' else 'exited'} the house")
        print(f"{attendance_type.capitalize()} recorded for {name}")
        
    except Exception as e:
        print(f"Error recording attendance: {str(e)}")

@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    return response

if __name__ == '__main__':
    threading.Thread(target=app.run, kwargs={'host': '0.0.0.0', 'port': 5004}).start()
    # Start the video capture
    video = cv2.VideoCapture(0)
    app.run(host='0.0.0.0', port=5004)
