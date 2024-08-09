import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/presentation/providers/add_device_providers.dart';
import 'package:home_automation/helpers/utils.dart';
import 'package:home_automation/features/devices/presentation/pages/device_details.page.dart';

class DeviceListViewModel extends StateNotifier<List<DeviceModel>> {
  final Ref ref;
  bool _isNavigating = false;

  DeviceListViewModel(List<DeviceModel> initialState, this.ref) : super(initialState);

  Future<void> fetchDevices() async {
    final devices = await ref.read(deviceRepositoryProvider).getListOfDevices();
    print("Fetched devices: ${devices.map((d) => d.toJson())}");
    if (devices.any((d) => d.id.isEmpty)) {
      print("Warning: Some devices have empty IDs");
    }
    state = devices;
  }

  void toggleDevice(DeviceModel selectedDevice) async {
    state = [
      for(final device in state)
        if (device == selectedDevice) 
          device.copyWith(isSelected: !device.isSelected)
        else  
          device
    ];

    ref.read(selectedDeviceProvider.notifier).state = state.where((d) => d.outlet == selectedDevice.outlet).first;
  }

  void addDevice(DeviceModel device) {
    state = [
      ...state, device
    ];
  }

  bool deviceExists(String deviceName) {
    return state.any((d) => d.label.trim().toLowerCase() == deviceName.trim().toLowerCase());
  }

  Future<void> showDeviceDetails(DeviceModel device) async {
    if (_isNavigating) return;
    _isNavigating = true;

    print("Showing details for device: ${device.toJson()}");
    if (device.id.isEmpty) {
      print("Warning: Device ID is empty. Full device data: ${device.toJson()}");
      _isNavigating = false;
      return;
    }
    
    ref.read(selectedDeviceProvider.notifier).state = device;
    
    print("Fetching detailed device information");
    final detailedDevice = await ref.read(deviceRepositoryProvider).getDeviceDetails(device.id);
    
    print("Updating selected device with detailed information: ${detailedDevice.toJson()}");
    if (detailedDevice.id.isNotEmpty) {
      ref.read(selectedDeviceProvider.notifier).state = detailedDevice;
      
      if (Utils.isMobile()) {
        print("Attempting to navigate to DeviceDetailsPage");
        try {
          await GoRouter.of(Utils.mainNav.currentContext!).pushNamed(
            DeviceDetailsPage.route,
            extra: detailedDevice,
          );
          print("Navigation to DeviceDetailsPage successful");
        } catch (e) {
          print("Error navigating to DeviceDetailsPage: $e");
        }
      } else {
        print("Not navigating: Not on mobile");
      }
    } else {
      print("Error: Detailed device has an empty ID. Full device data: ${detailedDevice.toJson()}");
    }

    _isNavigating = false;
  }

  Future<void> removeDevice(DeviceModel deviceData) async {
    try {
      await ref.read(deviceRepositoryProvider).removeDevice(deviceData.id);
      
      state = [
        for(final device in state)
          if (device.id != deviceData.id)
            device
      ];

      if (Utils.isMobile()) {
        GoRouter.of(Utils.mainNav.currentContext!).pop();
      }

      ref.read(selectedDeviceProvider.notifier).state = null;
    } catch (e) {
      print('Error removing device: $e');
      Utils.showMessageOnSnack('Error removing device', 'Please try again');
    }
  }
}