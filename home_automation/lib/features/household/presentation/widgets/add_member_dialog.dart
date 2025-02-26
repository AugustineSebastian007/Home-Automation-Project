import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:home_automation/features/household/presentation/providers/household_providers.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' show WriteBuffer;

class AddMemberDialog extends ConsumerStatefulWidget {
  final CameraController controller;

  const AddMemberDialog({required this.controller});

  @override
  _AddMemberDialogState createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<AddMemberDialog> {
  final _nameController = TextEditingController();
  bool _isCapturing = false;
  Face? _detectedFace;
  Map<String, List<double>> faceDataMap = {};
  int _captureCount = 0;
  Timer? _captureTimer;
  
  @override
  void dispose() {
    _nameController.dispose();
    _captureTimer?.cancel();
    super.dispose();
  }

  Future<void> _startCapturing() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    setState(() {
      _isCapturing = true;
      _captureCount = 0;
      faceDataMap = {};
    });

    final faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
        enableTracking: true,
      ),
    );

    try {
      _captureTimer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
        if (_captureCount >= 20) {
          _stopCapturing();
          return;
        }

        try {
          final XFile photo = await widget.controller.takePicture();
          final inputImage = InputImage.fromFilePath(photo.path);
          final faces = await faceDetector.processImage(inputImage);

          if (faces.isNotEmpty && mounted) {
            final face = faces.first;
            
            if (_isFaceValid(face)) {
              setState(() {
                _detectedFace = face;
                final boundingBox = face.boundingBox;
                
                List<double> faceVector = [
                  boundingBox.left,
                  boundingBox.top,
                  boundingBox.width,
                  boundingBox.height,
                ];
                
                faceDataMap['face_$_captureCount'] = faceVector;
                _captureCount++;
              });
            }
          }
          
          await File(photo.path).delete();
          
        } catch (e) {
          print('Face capture error: $e');
        }
      });

    } catch (e) {
      _stopCapturing();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _stopCapturing() {
    _captureTimer?.cancel();
    setState(() {
      _isCapturing = false;
    });

    if (_captureCount >= 20) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      ref.read(householdMemberRepositoryProvider)
         .addHouseholdMember(_nameController.text, faceDataMap)
         .then((_) {
           Navigator.of(context).pop(); // Remove loading indicator
           Navigator.of(context).pop(); // Close dialog
         })
         .catchError((e) {
           Navigator.of(context).pop(); // Remove loading indicator
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error saving member: $e')),
           );
         });
    }
  }

  bool _isFaceValid(Face face) {
    final headEulerAngleY = face.headEulerAngleY ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0;
    final leftEyeOpenProbability = face.leftEyeOpenProbability ?? 0;
    final rightEyeOpenProbability = face.rightEyeOpenProbability ?? 0;

    return headEulerAngleY.abs() < 20 && 
           headEulerAngleZ.abs() < 20 && 
           leftEyeOpenProbability > 0.3 &&
           rightEyeOpenProbability > 0.3;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add New Member', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Member Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            if (_isCapturing) ...[
              Container(
                height: 400,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CameraPreview(widget.controller),
                    ),
                    if (_detectedFace != null)
                      CustomPaint(
                        painter: FaceBoxPainter(_detectedFace!),
                      ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Captured: $_captureCount/20',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isCapturing ? _stopCapturing : _startCapturing,
              child: Text(_isCapturing ? 'Stop Capture' : 'Start Capture'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(200, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FaceBoxPainter extends CustomPainter {
  final Face face;

  FaceBoxPainter(this.face);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.green;

    canvas.drawRect(face.boundingBox, paint);
  }

  @override
  bool shouldRepaint(FaceBoxPainter oldDelegate) => true;
}

