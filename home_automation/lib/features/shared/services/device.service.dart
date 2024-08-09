import 'dart:async';

// import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:home_automation/features/devices/presentation/providers/add_device_providers.dart';
import 'package:home_automation/helpers/utils.dart';
// import 'package:http/http.dart' as http;
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/shared/models/device_response.model.dart';
// import 'package:collection/collection.dart';
// import 'package:home_automation/features/devices/presentation/providers/room_providers.dart';
// import 'package:home_automation/features/devices/data/models/outlet.model.dart';

class DeviceService {

  final Ref ref;
  const DeviceService(this.ref);

  Future<DeviceResponse> toggleDevice(DeviceModel device) async {
    try {
      final newState = !device.isSelected;
      print("Toggling device: ${device.id}, New state: $newState");
      
      // Simulate a successful toggle for now
      await Future.delayed(Duration(milliseconds: 500));
      
      return DeviceResponse(statusCode: 200, success: true);
    } on Exception catch (e) {
      print("Exception during toggle for device ${device.id}: $e");
      Utils.showMessageOnSnack('Issue during toggle.', 'Please try again.');
      return DeviceResponse(statusCode: 0, success: false);
    }
  }
}