import 'package:home_automation/features/household/data/models/household_member.model.dart';
import 'package:home_automation/features/shared/services/firestore.service.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart';
import 'dart:ui' as ui;

class HouseholdMemberRepository {
  final FirestoreService _firestoreService;
  final _auth = FirebaseAuth.instance;

  HouseholdMemberRepository(this._firestoreService);

  Stream<List<HouseholdMemberModel>> streamHouseholdMembers() {
    final user = _auth.currentUser;
    if (user == null) {
      // Return empty stream if user is not authenticated
      return Stream.value([]);
    }
    return _firestoreService.streamHouseholdMembers();
  }

  Future<void> addHouseholdMember(String name, Map<String, List<double>> faceData) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to add household members');
    }

    try {
      final member = HouseholdMemberModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        faceData: faceData,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addHouseholdMember(member);
    } catch (e) {
      print('Error adding household member: $e');
      throw Exception('Failed to add household member: $e');
    }
  }

  Future<void> deleteMember(String memberId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to delete household members');
    }

    try {
      await _firestoreService.deleteHouseholdMember(memberId);
    } catch (e) {
      print('Error deleting household member: $e');
      throw Exception('Failed to delete household member: $e');
    }
  }

  Future<List<List<double>>> captureFaceData(CameraController controller) async {
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      await Permission.camera.request();
    }
    if (!cameraStatus.isGranted) {
      throw Exception('Camera permission not granted');
    }

    List<List<double>> faceData = [];
    final faceDetector = GoogleMlKit.vision.faceDetector();
    int attempts = 0;

    try {
      while (faceData.length < 20) {
        attempts++;
        
        if (attempts % 10 == 0) { // Same as Python implementation
          // Wait for camera to be ready
          await Future.delayed(Duration(milliseconds: 500));
          
          try {
            final xFile = await controller.takePicture();
            final inputImage = InputImage.fromFilePath(xFile.path);
            final faces = await faceDetector.processImage(inputImage);

            if (faces.isNotEmpty) {
              final face = faces.first;
              final boundingBox = face.boundingBox;
              
              List<double> faceVector = [
                boundingBox.left,
                boundingBox.top,
                boundingBox.width,
                boundingBox.height,
              ];
              faceData.add(faceVector);
              
              // Clean up
              await File(xFile.path).delete();
            }
          } catch (e) {
            print('Capture attempt error: $e');
            await Future.delayed(Duration(milliseconds: 100));
            continue;
          }
        }
        
        // Small delay between attempts
        await Future.delayed(Duration(milliseconds: 100));
      }
    } finally {
      await faceDetector.close();
    }

    if (faceData.isEmpty) {
      throw Exception('No faces detected');
    }

    return faceData;
  }

  bool _isFaceValid(Face face) {
    // More lenient face validation
    final headEulerAngleY = face.headEulerAngleY ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0;
    final headEulerAngleX = face.headEulerAngleX ?? 0;
    
    final leftEyeOpenProbability = face.leftEyeOpenProbability ?? 0;
    final rightEyeOpenProbability = face.rightEyeOpenProbability ?? 0;

    return headEulerAngleY.abs() < 20 && // More tolerant angle
           headEulerAngleZ.abs() < 20 && // More tolerant angle
           headEulerAngleX.abs() < 20 && // More tolerant angle
           leftEyeOpenProbability > 0.3 && // More tolerant eye opening
           rightEyeOpenProbability > 0.3; // More tolerant eye opening
  }

  Future<void> linkMemberToProfile(String memberId, String profileId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to link members to profiles');
    }

    try {
      await _firestoreService.updateHouseholdMember(
        memberId, 
        {'profileId': profileId}
      );
    } catch (e) {
      throw Exception('Failed to link member to profile: $e');
    }
  }
}
