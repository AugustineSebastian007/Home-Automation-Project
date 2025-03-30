import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/presentation/providers/add_device_providers.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart' as device_providers;
import 'package:home_automation/helpers/enums.dart';
import 'package:collection/collection.dart';

class AddDeviceSaveViewModel extends StateNotifier<AddDeviceStates> {

  final Ref ref;
  AddDeviceSaveViewModel(super.state, this.ref);

  Future<void> saveDevice() async {
    state = AddDeviceStates.saving;

    final label = ref.read(deviceNameValueProvider);
    final deviceTypes = ref.read(deviceTypeSelectionVMProvider);
    final deviceType = deviceTypes.firstWhereOrNull((d) => d.isSelected);
    final outlet = ref.read(outletValueProvider);
    final room = ref.read(roomValueProvider);

    if (label.isEmpty || deviceType == null || outlet == null || room == null) {
      state = AddDeviceStates.none;
      throw Exception('Invalid device data');
    }

    final DeviceModel deviceToSave = DeviceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      iconOption: deviceType.iconOption,
      label: label,
      isSelected: false,
      outlet: int.tryParse(outlet) ?? 0,  // Convert outlet to int
      roomId: room.id,
      outletId: outlet,
    );

    try {
      await ref.read(device_providers.deviceRepositoryProvider).addDevice(room.id, outlet, deviceToSave);
      ref.read(device_providers.deviceListVMProvider.notifier).addDevice(deviceToSave);

      state = AddDeviceStates.saved;
    } catch (e) {
      print('Error saving device: $e');
      state = AddDeviceStates.none;
      rethrow;
    }
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