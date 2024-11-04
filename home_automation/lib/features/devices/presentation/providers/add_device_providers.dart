import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/outlets/data/models/outlet.model.dart';
import 'package:home_automation/features/devices/data/repositories/devices.repository.dart';
import 'package:home_automation/features/outlets/data/repositories/outlet_repository.dart';
import 'package:home_automation/features/devices/presentation/viewmodels/devicelist.viewmodel.dart';
import 'package:home_automation/features/devices/presentation/viewmodels/add_device_type.viewmodel.dart';
import 'package:home_automation/features/devices/presentation/viewmodels/add_device_save.viewmodel.dart';
import 'package:home_automation/features/shared/services/firestore.service.dart';
import 'package:home_automation/helpers/enums.dart'; // Adjust the path as needed
import 'package:flutter/material.dart';
import 'package:home_automation/features/rooms/data/models/room.model.dart';


final deviceNameFieldProvider = Provider((ref) => TextEditingController());

final deviceNameValueProvider = StateProvider<String>((ref) => '');

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final deviceRepositoryProvider = Provider((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return DevicesRepository(firestoreService);
});

final outletRepositoryProvider = Provider((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return OutletRepository(firestoreService);
});

final outletListProvider = FutureProvider.family<List<OutletModel>, String>((ref, roomId) {
  final outletRepository = ref.read(outletRepositoryProvider);
  return outletRepository.getOutlets(roomId);
});

final outletValueProvider = StateProvider<String?>((ref) => null);

final deviceTypeListProvider = Provider<List<DeviceModel>>((ref) {
  return [
    DeviceModel(
      id: 'ac_type',
      iconOption: FlickyAnimatedIconOptions.ac,
      label: 'Air\nConditioning',
      isSelected: false,
      outlet: 0,
      roomId: '',
      outletId: '',
    ),
    DeviceModel(
      id: 'personal_item_type',
      iconOption: FlickyAnimatedIconOptions.hairdryer,
      label: 'Personal\nItem',
      isSelected: false,
      outlet: 0,
      roomId: '',
      outletId: '',
    ),
    DeviceModel(
      id: 'fan_type',
      iconOption: FlickyAnimatedIconOptions.fan,
      label: 'Fan',
      isSelected: false,
      outlet: 0,
      roomId: '',
      outletId: '',
    ),
    DeviceModel(
      id: 'light_fixture_type',
      iconOption: FlickyAnimatedIconOptions.lightbulb,
      label: 'Light\nFixture',
      isSelected: false,
      outlet: 0,
      roomId: '',
      outletId: '',
    ),
    DeviceModel(
      id: 'other_type',
      iconOption: FlickyAnimatedIconOptions.bolt,
      label: 'Other',
      isSelected: false,
      outlet: 0,
      roomId: '',
      outletId: '',
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

final roomValueProvider = StateProvider<RoomModel?>((ref) => null);