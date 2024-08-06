import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/shared/providers/shared_providers.dart';
import 'package:home_automation/helpers/enums.dart';

class DevicesRepository {

  final Ref ref;
  DevicesRepository(this.ref);
  
  Future<List<DeviceModel>> getListOfDevices() async {
    final devices = await ref.read(firestoreServiceProvider).getDeviceList();
    print("Devices from Firestore: ${devices.map((d) => d.toJson())}");
    return devices;
  }

  Future<void> saveDeviceList(List<DeviceModel> deviceList) async {
    await ref.read(firestoreServiceProvider).storeDeviceList(deviceList);
  }

  Future<void> addDevice(DeviceModel newDevice) async {
    try {
      final docRef = await ref.read(firestoreServiceProvider).addDevice(newDevice.toJson());
      print("Added device with ID: ${docRef.id}");
    } catch (e) {
      print('Error in addDevice: $e');
      throw Exception('Failed to add device');
    }
  }

  Future<DeviceModel> getDeviceDetails(String deviceId) async {
    if (deviceId.isEmpty) {
      print("Error: Received empty device ID");
      return DeviceModel(
        id: 'error',
        iconOption: FlickyAnimatedIconOptions.bolt,
        label: 'Error: Empty ID',
        isSelected: false,
        outlet: 0
      );
    }
    final devices = await getListOfDevices();
    final device = devices.firstWhere(
      (device) => device.id == deviceId,
      orElse: () {
        print("Device not found with ID: $deviceId");
        return DeviceModel(
          id: 'not_found',
          iconOption: FlickyAnimatedIconOptions.bolt,
          label: 'Device Not Found',
          isSelected: false,
          outlet: 0
        );
      }
    );
    print("Device details: ${device.toJson()}");
    return device;
  }
}