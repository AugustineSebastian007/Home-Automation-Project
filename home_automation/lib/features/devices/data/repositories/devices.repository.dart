import 'dart:convert';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/shared/providers/shared_providers.dart';

class DevicesRepository {

  final Ref ref;
  DevicesRepository(this.ref);
  
  Future<List<DeviceModel>> getListOfDevices() async {
    return await ref.read(firestoreServiceProvider).getDeviceList();
  }

  Future<void> saveDeviceList(List<DeviceModel> deviceList) async {
    await ref.read(firestoreServiceProvider).storeDeviceList(deviceList);
  }

  Future<void> addDevice(DeviceModel newDevice) async {
    try {
      final currentDevices = await getListOfDevices();
      currentDevices.add(newDevice);
      await saveDeviceList(currentDevices);
    } catch (e) {
      print('Error in addDevice: $e');
      throw Exception('Failed to add device');
    }
  }
}