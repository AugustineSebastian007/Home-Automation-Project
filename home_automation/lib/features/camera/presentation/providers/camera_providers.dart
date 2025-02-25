import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/shared/providers/shared_providers.dart';

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

final boundaryPointsProvider = StateNotifierProvider.family<BoundaryPointsNotifier, List<Offset>, String>(
  (ref, feedPath) => BoundaryPointsNotifier(ref, feedPath),
);