import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/presentation/providers/add_device_providers.dart';
// import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/helpers/enums.dart';

class AddDeviceSaveViewModel extends StateNotifier<AddDeviceStates> {

  final Ref ref;
  AddDeviceSaveViewModel(super.state, this.ref);

  Future<void> saveDevice() async {
    final label = ref.read(deviceNameValueProvider);
    final deviceType = ref.read(deviceTypeSelectionVMProvider).firstWhere((d) => d.isSelected);
    final outlet = ref.read(outletValueProvider);
    // final existingDevice = ref.read(selectedDeviceProvider);

    final DeviceModel deviceToSave = DeviceModel(
      id: '', // Leave empty for new devices
      iconOption: deviceType.iconOption,
      label: label,
      isSelected: false,
      outlet: outlet ?? 0,
    );

    try {
      final newDeviceId = await ref.read(deviceRepositoryProvider).addDevice(deviceToSave);
      final newDevice = deviceToSave.copyWith(id: newDeviceId);
      ref.read(deviceListVMProvider.notifier).addDevice(newDevice);

      state = AddDeviceStates.saved;
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      print('Error saving device: $e');
      state = AddDeviceStates.none;
      rethrow;
    }
  }

  Future<bool> saveDeviceList() async {
    final updatedList = ref.read(deviceListVMProvider);
    await ref.read(deviceRepositoryProvider).saveDeviceList(updatedList);
    return true;
  }

  void resetAllValues() {
    state = AddDeviceStates.none;

    ref.read(deviceNameFieldProvider).clear();
    ref.read(deviceNameValueProvider.notifier).state = '';
    ref.read(outletValueProvider.notifier).state = null;
    var rawList = ref.read(deviceTypeListProvider);
    ref.read(deviceTypeSelectionVMProvider.notifier).state = rawList;
  }
}