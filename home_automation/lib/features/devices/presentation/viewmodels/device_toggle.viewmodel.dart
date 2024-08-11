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
    state = true;
    try {
      print("Toggling device: ${selectedDevice.toJson()}");
      if (selectedDevice.id.isEmpty) {
        throw Exception("Cannot toggle device with empty ID");
      }
      final updatedDevice = selectedDevice.copyWith(isSelected: !selectedDevice.isSelected);
      print("Updated device state: ${updatedDevice.toJson()}");
      final response = await ref.read(deviceServiceProvider).toggleDevice(updatedDevice);
      
      if (response.success) {
        await Future.delayed(500.milliseconds);
        try {
          await ref.read(deviceRepositoryProvider).updateDevice(updatedDevice.roomId, updatedDevice.outletId, updatedDevice);
          ref.read(selectedDeviceProvider.notifier).state = updatedDevice;
          
          // Update the device in the device list
          ref.read(deviceListVMProvider.notifier).updateDevice(updatedDevice);
          
          print("Device toggled successfully: ${updatedDevice.toJson()}");
        } catch (updateError) {
          print("Error updating device in Firestore: $updateError");
          // Revert the toggle if update fails
          ref.read(selectedDeviceProvider.notifier).state = selectedDevice;
        }
      } else {
        print("Failed to toggle device: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in toggleDevice: $e");
    } finally {
      state = false;
    }
  }
}