import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:home_automation/features/shared/providers/shared_providers.dart';

// Provider for boundary points used in camera settings
final boundaryPointsProvider = StateNotifierProvider.family<BoundaryPointsNotifier, List<Offset>, String>(
  (ref, cameraUrl) => BoundaryPointsNotifier(ref, cameraUrl),
);

// Provider for camera status information
final cameraStatusProvider = Provider.family<Stream<Map<String, dynamic>>, String>((ref, cameraType) {
  final userId = '1R05PQZRwPdB7mYnqiCOefAv5Jb2'; // This should ideally come from an auth provider
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('camera_status')
      .doc(cameraType)
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists) {
      return snapshot.data() ?? {};
    } else {
      return {
        'isOnline': false,
        'ipAddress': '',
        'port': 0,
        'url': '',
        'lastUpdated': null
      };
    }
  });
});

// Provider that returns the current URL for a camera
final cameraUrlProvider = FutureProvider.family<String, String>((ref, cameraType) async {
  final userId = '1R05PQZRwPdB7mYnqiCOefAv5Jb2'; // This should ideally come from an auth provider
  
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('camera_status')
      .doc(cameraType)
      .get();
      
  if (snapshot.exists) {
    final data = snapshot.data();
    final bool isOnline = data?['isOnline'] ?? false;
    final String? url = data?['url'];
    
    if (isOnline && url != null) {
      return url;
    }
  }
  
  return '';
});

class BoundaryPointsNotifier extends StateNotifier<List<Offset>> {
  final Ref ref;
  final String feedPath;

  BoundaryPointsNotifier(this.ref, this.feedPath) : super([]);

  void addPoint(Offset point) {
    state = [...state, point];
    
    // If 4 points are added, automatically save
    if (state.length >= 4) {
      saveBoundary();
    }
  }

  void removeLastPoint() {
    if (state.isNotEmpty) {
      state = state.sublist(0, state.length - 1);
    }
  }

  void clearPoints() {
    state = [];
  }
  
  Future<void> saveBoundary() async {
    if (state.length >= 4) {
      final points = state.map((point) => [point.dx, point.dy]).toList();
      
      try {
        await ref.read(firestoreServiceProvider).saveCameraBoundaryPoints(feedPath, points);
        print('Boundary saved for $feedPath: $points');
      } catch (e) {
        print('Error saving boundary points in notifier: $e');
      }
    }
  }

  void loadPointsFromFirestore(List<Offset> points) {
    state = points;
  }
}