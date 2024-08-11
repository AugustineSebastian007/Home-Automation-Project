import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/presentation/providers/add_device_providers.dart';
import 'package:home_automation/helpers/utils.dart';
import 'package:home_automation/features/devices/presentation/pages/device_details.page.dart';

class DeviceListViewModel extends StateNotifier<List<DeviceModel>> {
  final Ref ref;
  bool _isNavigating = false;
  StreamSubscription<List<DeviceModel>>? _deviceSubscription;

  DeviceListViewModel(List<DeviceModel> initialState, this.ref) : super(initialState) {
    _listenToDevices();
  }

  void _listenToDevices() {
    _deviceSubscription?.cancel();
    _deviceSubscription = ref.read(deviceRepositoryProvider).listenToDevices().listen((devices) {
      state = devices;
      print("Devices updated: ${devices.map((d) => d.toJson())}");
      
      // Update selectedDeviceProvider if the current selected device has changed
      final currentSelectedDevice = ref.read(selectedDeviceProvider);
      if (currentSelectedDevice != null) {
        final updatedSelectedDevice = devices.firstWhere(
          (d) => d.id == currentSelectedDevice.id,
          orElse: () => currentSelectedDevice,
        );
        if (updatedSelectedDevice != currentSelectedDevice) {
          ref.read(selectedDeviceProvider.notifier).state = updatedSelectedDevice;
        }
      }
    });
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    super.dispose();
  }

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
    print("Adding device to local list: ${device.toJson()}");
    state = [...state, device];
    print("Updated local list: ${state.map((d) => d.toJson())}");
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
    if (detailedDevice.id.isNotEmpty && detailedDevice.id != 'error' && detailedDevice.id != 'not_found') {
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
      print("Error: Invalid device data. Full device data: ${detailedDevice.toJson()}");
    }

    _isNavigating = false;
  }

  Future<void> removeDevice(DeviceModel deviceData) async {
    try {
      await ref.read(deviceRepositoryProvider).removeDevice(deviceData.roomId, deviceData.outletId, deviceData.id);
      
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

  void updateDevice(DeviceModel updatedDevice) {
    state = [
      for (final device in state)
        if (device.id == updatedDevice.id) updatedDevice else device
    ];
  }
}