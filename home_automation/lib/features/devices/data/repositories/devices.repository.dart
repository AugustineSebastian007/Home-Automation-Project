import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/shared/providers/shared_providers.dart' as shared_providers;
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/features/devices/presentation/providers/add_device_providers.dart';

class DevicesRepository {

  final Ref ref;
  DevicesRepository(this.ref);
  
  Future<List<DeviceModel>> getListOfDevices() async {
    final devices = await ref.read(shared_providers.firestoreServiceProvider).getDeviceList();
    print("Devices from Firestore: ${devices.map((d) => d.toJson())}");
    return devices;
  }

  Future<void> saveDeviceList(List<DeviceModel> deviceList) async {
    await ref.read(shared_providers.firestoreServiceProvider).storeDeviceList(deviceList);
  }

  Future<String> addDevice(DeviceModel newDevice) async {
    try {
      print("Adding new device: ${newDevice.toJson()}");
      
      // Ensure the ID is empty when adding a new device
      final deviceToAdd = newDevice.copyWith(id: '');
      
      // Add the new device to Firestore
      final newDeviceId = await ref.read(shared_providers.firestoreServiceProvider).addDevice(deviceToAdd.toJson());
      
      print("Added new device with ID: $newDeviceId");
      
      // Add the device to the local list
      final updatedDevice = deviceToAdd.copyWith(id: newDeviceId);
      ref.read(deviceListVMProvider.notifier).addDevice(updatedDevice);

      return newDeviceId;
    } catch (e) {
      print('Error in addDevice: $e');
      throw Exception('Failed to add new device: $e');
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
    final deviceDoc = await ref.read(shared_providers.firestoreServiceProvider).getDeviceById(deviceId);
    if (deviceDoc != null) {
      final data = deviceDoc.data() as Map<String, dynamic>? ?? {};
      final device = DeviceModel.fromJson({...data, 'id': deviceId});
      print("Device details: ${device.toJson()}");
      return device;
    } else {
      print("Device not found with ID: $deviceId");
      return DeviceModel(
        id: 'not_found',
        iconOption: FlickyAnimatedIconOptions.bolt,
        label: 'Device Not Found',
        isSelected: false,
        outlet: 0
      );
    }
  }

  Future<void> removeDevice(String deviceId) async {
    try {
      await ref.read(shared_providers.firestoreServiceProvider).removeDevice(deviceId);
      print("Removed device with ID: $deviceId");
    } catch (e) {
      print('Error in removeDevice: $e');
      throw Exception('Failed to remove device');
    }
  }

  Future<void> updateDevice(DeviceModel updatedDevice) async {
    try {
      print("Attempting to update device: ${updatedDevice.toJson()}");
      if (updatedDevice.id.isEmpty) {
        throw Exception('Device ID is empty');
      }
      await ref.read(shared_providers.firestoreServiceProvider).updateDevice(updatedDevice.toJson());
      print("Updated device in Firestore: ${updatedDevice.toJson()}");
      
      // Update the device in the local list
      ref.read(deviceListVMProvider.notifier).updateDevice(updatedDevice);
    } catch (e) {
      print('Error in updateDevice: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to update device: $e');
    }
  }

  Stream<DeviceModel> listenToDevice(String deviceId) {
    return ref.read(shared_providers.firestoreServiceProvider).listenToDevice(deviceId);
  }

  Stream<List<DeviceModel>> listenToDevices() {
    return ref.read(shared_providers.firestoreServiceProvider).listenToDevices();
  }
}