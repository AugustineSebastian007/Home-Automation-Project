import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/presentation/providers/add_device_providers.dart';
// import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/features/shared/providers/shared_providers.dart';

class DeviceToggleViewModel extends StateNotifier<bool> {

  final Ref ref;
  DeviceToggleViewModel(super.state, this.ref);

  Future<void> toggleDevice(DeviceModel selectedDevice) async {
    if (state) return; // Prevent multiple simultaneous toggles
    
    state = true;
    try {
      print("Toggling device: ${selectedDevice.toJson()}");
      if (selectedDevice.id.isEmpty) {
        throw Exception("Cannot toggle device with empty ID");
      }
      
      // Create the updated device with the opposite of its current state
      final updatedDevice = selectedDevice.copyWith(isSelected: !selectedDevice.isSelected);
      print("Updated device state: ${updatedDevice.toJson()}");
      
      // Send the actual current state to the service
      final response = await ref.read(deviceServiceProvider).toggleDevice(updatedDevice);
      
      if (response.success) {
        await Future.delayed(300.milliseconds);
        // Update the local storage with the new state
        await ref.read(deviceRepositoryProvider).updateDevice(
          updatedDevice.roomId,
          updatedDevice.outletId,
          updatedDevice
        );
        
        // Update the UI with the new state
        ref.read(deviceListVMProvider.notifier).updateDevice(updatedDevice);
        
        print("Device toggled successfully: ${updatedDevice.toJson()}");
      } else {
        throw Exception("Failed to toggle device: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in toggleDevice: $e");
      throw e;
    } finally {
      state = false;
    }
  }
  
  // Method to directly set a device state without toggling it
  Future<void> setDeviceState(DeviceModel device) async {
    if (state) return; // Prevent multiple simultaneous toggles
    
    state = true;
    try {
      print("Setting device state: ${device.toJson()}");
      if (device.id.isEmpty) {
        throw Exception("Cannot set state of device with empty ID");
      }
      
      // Send the device state to the service
      final response = await ref.read(deviceServiceProvider).toggleDevice(device);
      
      if (response.success) {
        await Future.delayed(300.milliseconds);
        // Update the local storage with the new state
        await ref.read(deviceRepositoryProvider).updateDevice(
          device.roomId,
          device.outletId,
          device
        );
        
        // Update the UI with the new state
        ref.read(deviceListVMProvider.notifier).updateDevice(device);
        
        print("Device state set successfully: ${device.toJson()}");
      } else {
        throw Exception("Failed to set device state: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in setDeviceState: $e");
      throw e;
    } finally {
      state = false;
    }
  }
}
