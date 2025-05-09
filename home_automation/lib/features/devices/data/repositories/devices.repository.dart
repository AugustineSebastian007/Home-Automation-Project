import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/shared/services/firestore.service.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/features/rooms/data/models/room.model.dart';
import 'package:home_automation/features/outlets/data/models/outlet.model.dart';

class DevicesRepository {
  final FirestoreService _firestoreService;

  DevicesRepository(this._firestoreService);

  Future<List<DeviceModel>> getDevices(String roomId, String outletId) async {
    return await _firestoreService.getDevices(roomId, outletId);
  }

  Future<void> addDevice(String roomId, String outletId, DeviceModel device) async {
    await _firestoreService.addDevice(roomId, outletId, device);
  }

  Future<void> updateDevice(String roomId, String outletId, DeviceModel device) async {
    await _firestoreService.updateDevice(roomId, outletId, device);
  }

  Future<void> removeDevice(String roomId, String outletId, String deviceId) async {
    await _firestoreService.removeDevice(roomId, outletId, deviceId);
  }

  Stream<List<DeviceModel>> listenToDevices() {
    return _firestoreService.listenToDevices();
  }

  Future<List<DeviceModel>> getListOfDevices() async {
    return await _firestoreService.getListOfDevices();
  }

  Future<DeviceModel> getDeviceDetails(String deviceId) async {
    return await _firestoreService.getDeviceDetails(deviceId);
  }

  Stream<DeviceModel> streamDevice(String roomId, String outletId, String deviceId) {
    return _firestoreService.streamDevice(roomId, outletId, deviceId);
  }

  Stream<List<DeviceModel>> streamDevices(String roomId, String outletId) {
    return _firestoreService.streamDevices(roomId, outletId);
  }

  Stream<List<DeviceModel>> streamAllDevices() {
    return _firestoreService.streamAllDevices();
  }

  Future<List<DeviceModel>> getMainRoomDevices() async {
    const String mainRoomId = 'main_room';
    const String mainOutletId = 'esp32';

    final existingDevices = await _firestoreService.getDevices(mainRoomId, mainOutletId);
    return existingDevices; // Just return whatever exists, don't create new ones
  }

  Stream<DeviceModel?> streamMainRoomDevice(String deviceId) {
    const String mainRoomId = 'main_room';
    const String mainOutletId = 'esp32';
    
    try {
      return _firestoreService.streamDevice(mainRoomId, mainOutletId, deviceId);
    } catch (e) {
      // Return a stream with null if the main room doesn't exist
      return Stream.value(null);
    }
  }

  Stream<List<DeviceModel>> streamMainRoomDevices() {
    const String mainRoomId = 'main_room';
    const String mainOutletId = 'esp32';
    
    try {
      return _firestoreService.streamDevices(mainRoomId, mainOutletId);
    } catch (e) {
      // Return an empty list if the main room doesn't exist
      return Stream.value([]);
    }
  }

  Future<void> ensureMainRoomDevices(String roomId, String outletId) async {
    final existingDevices = await _firestoreService.getDevices(roomId, outletId);
    if (existingDevices.isEmpty) {
      final devices = [
        DeviceModel(id: 'light1', iconOption: FlickyAnimatedIconOptions.lightbulb, label: 'Light 1', isSelected: false, outlet: 1, roomId: roomId, outletId: outletId),
        DeviceModel(id: 'light2', iconOption: FlickyAnimatedIconOptions.lightbulb, label: 'Light 2', isSelected: false, outlet: 2, roomId: roomId, outletId: outletId),
        DeviceModel(id: 'light3', iconOption: FlickyAnimatedIconOptions.lightbulb, label: 'Light 3', isSelected: false, outlet: 3, roomId: roomId, outletId: outletId),
        DeviceModel(id: 'light4', iconOption: FlickyAnimatedIconOptions.lightbulb, label: 'Light 4', isSelected: false, outlet: 4, roomId: roomId, outletId: outletId),
        DeviceModel(id: 'fan', iconOption: FlickyAnimatedIconOptions.fan, label: 'Fan', isSelected: false, outlet: 5, roomId: roomId, outletId: outletId),
      ];
      for (var device in devices) {
        await _firestoreService.addDevice(roomId, outletId, device);
      }
    }
  }
}
