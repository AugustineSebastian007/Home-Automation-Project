import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/shared/models/device_response.model.dart';
import 'package:home_automation/features/shared/services/device.service.dart';
import 'package:home_automation/features/shared/services/firestore.service.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final deviceServiceProvider = Provider((ref) {
  return DeviceService(ref);
});

final deviceServiceFutureProvider = FutureProvider.family<DeviceResponse, DeviceModel>((ref, DeviceModel device) async {
  if (device.outlet >= 0) {
    final response = await ref.read(deviceServiceProvider).toggleDevice(device);
    return response;
  }

  return DeviceResponse(statusCode: 200, success: true);
});