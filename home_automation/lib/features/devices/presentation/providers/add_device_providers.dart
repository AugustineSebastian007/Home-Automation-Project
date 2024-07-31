import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/data/models/outlet.model.dart';
import 'package:home_automation/features/devices/data/repositories/devices.repository.dart';
import 'package:home_automation/features/devices/data/repositories/outlets.repository.dart';
import 'package:home_automation/features/devices/presentation/viewmodels/devicelist.viewmodel.dart';
import 'package:home_automation/features/devices/presentation/viewmodels/add_device_type.viewmodel.dart';
import 'package:home_automation/features/devices/presentation/viewmodels/add_device_save.viewmodel.dart';
import 'package:home_automation/features/shared/services/firestore.service.dart';
import 'package:home_automation/helpers/enums.dart'; // Adjust the path as needed
import 'package:flutter/material.dart';


final deviceNameFieldProvider = Provider((ref) => TextEditingController());

final deviceNameValueProvider = StateProvider<String>((ref) => '');

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final deviceRepositoryProvider = Provider((ref) => DevicesRepository(ref));

final outletRepositoryProvider = Provider((ref) => OutletsRepository(ref));

final outletListProvider = FutureProvider<List<OutletModel>>((ref) async {
  final outletRepository = ref.read(outletRepositoryProvider);
  return await outletRepository.getAvailableOutlets();
});

final outletValueProvider = StateProvider<OutletModel?>((ref) => null);

final deviceTypeListProvider = Provider<List<DeviceModel>>((ref) {
  return const [
    DeviceModel(
      iconOption: FlickyAnimatedIconOptions.ac,
      label: 'Air\nConditioning',
      isSelected: false,
      outlet: 0
    ),
    DeviceModel(
      iconOption: FlickyAnimatedIconOptions.hairdryer,
      label: 'Personal/nItem',
      isSelected: false,
      outlet: 0
    ),
    DeviceModel(
      iconOption: FlickyAnimatedIconOptions.fan,
      label: 'Fan',
      isSelected: false,
      outlet: 0
    ),
    DeviceModel(
      iconOption: FlickyAnimatedIconOptions.lightbulb,
      label: 'Light\nFixture',
      isSelected: false,
      outlet: 0
    ),
    DeviceModel(
      iconOption: FlickyAnimatedIconOptions.bolt,
      label: 'Other',
      isSelected: false,
      outlet: 0
    ),
  ];
});

final deviceExistsValidatorProvider = Provider<bool>((ref) {
  var deviceName = ref.watch(deviceNameValueProvider);
  return ref.read(deviceListVMProvider.notifier).deviceExists(deviceName);
});

final deviceTypeSelectionVMProvider = StateNotifierProvider<AddDeviceTypeViewModel, List<DeviceModel>>((ref) {
  final deviceTypesList = ref.read(deviceTypeListProvider);
  return AddDeviceTypeViewModel(deviceTypesList, ref);
});

final formValidationProvider = Provider<bool>((ref) {
  final deviceName = ref.watch(deviceNameValueProvider);
  final deviceTypes = ref.watch(deviceTypeSelectionVMProvider);
  final hasSelectedType = deviceTypes.any((device) => device.isSelected);

  return deviceName.isNotEmpty && hasSelectedType;
});

final saveAddDeviceVMProvider = StateNotifierProvider<AddDeviceSaveViewModel, AddDeviceStates>((ref) {
  return AddDeviceSaveViewModel(AddDeviceStates.none, ref);
});

final deviceListVMProvider = StateNotifierProvider<DeviceListViewModel, List<DeviceModel>>((ref) {
  return DeviceListViewModel([], ref);
});

final selectedDeviceProvider = StateProvider<DeviceModel?>((ref) => null);