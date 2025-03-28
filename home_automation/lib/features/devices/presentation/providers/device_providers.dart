import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/data/repositories/devices.repository.dart';
import 'package:home_automation/features/devices/presentation/viewmodels/device_toggle.viewmodel.dart';
import 'package:home_automation/features/devices/presentation/viewmodels/devicelist.viewmodel.dart';
import 'package:home_automation/features/shared/services/firestore.service.dart';
import 'package:home_automation/features/rooms/presentation/providers/room_providers.dart' show mainRoomProvider;

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final deviceRepositoryProvider = Provider((ref) => DevicesRepository(ref.read(firestoreServiceProvider)));

final deviceListStreamProvider = StreamProvider.family<List<DeviceModel>, ({String roomId, String outletId})>((ref, params) {
  final repository = ref.read(deviceRepositoryProvider);
  return repository.streamDevices(params.roomId, params.outletId);
});

/*final deviceListRetrievalProvider = FutureProvider<bool>((ref) async {
  try {
    if (ref.read(deviceListVMProvider).isEmpty) {
      final devices = await ref.read(deviceRepositoryProvider).getListOfDevices();
      ref.read(deviceListVMProvider.notifier).initializeState(devices);
    }

    return true;
  }
  on Exception {
    return false;
  }
});*/

final deviceListVMProvider = StateNotifierProvider<DeviceListViewModel, List<DeviceModel>>((ref) {
  return DeviceListViewModel([], ref);
});

final selectedDeviceProvider = StateProvider<DeviceModel?>((ref) => null);

final deviceToggleVMProvider = StateNotifierProvider<DeviceToggleViewModel, bool>((ref) {
  return DeviceToggleViewModel(false, ref);
});

final selectedDeviceStreamProvider = StreamProvider.family<DeviceModel, String>((ref, deviceId) {
  return ref.watch(deviceRepositoryProvider).listenToDevices().map((devices) => 
    devices.firstWhere((device) => device.id == deviceId, 
      orElse: () => throw Exception('Device not found')
    )
  );
});

final deviceStreamProvider = StreamProvider.family<DeviceModel, ({String roomId, String outletId, String deviceId})>((ref, params) {
  final repository = ref.read(deviceRepositoryProvider);
  return repository.streamDevice(params.roomId, params.outletId, params.deviceId);
});

final mainRoomDevicesProvider = FutureProvider<List<DeviceModel>>((ref) async {
  final mainRoom = await ref.watch(mainRoomProvider.future);
  
  // Return empty list if main room doesn't exist
  if (mainRoom == null) {
    return [];
  }
  
  final repository = ref.read(deviceRepositoryProvider);
  final outletId = mainRoom.defaultOutlet?.id;
  
  // Return empty list if no default outlet
  if (outletId == null) {
    return [];
  }
  
  return await repository.getDevices(mainRoom.id, outletId);
});

final mainRoomDeviceStreamProvider = StreamProvider.family<DeviceModel?, String>((ref, deviceId) {
  final repository = ref.read(deviceRepositoryProvider);
  try {
    return repository.streamMainRoomDevice(deviceId);
  } catch (e) {
    // Return a stream with null if the main room or device doesn't exist
    return Stream.value(null);
  }
});

final mainRoomDevicesStreamProvider = StreamProvider<List<DeviceModel>>((ref) {
  final repository = ref.read(deviceRepositoryProvider);
  try {
    return repository.streamMainRoomDevices();
  } catch (e) {
    // Return an empty list if the main room doesn't exist
    return Stream.value([]);
  }
});
