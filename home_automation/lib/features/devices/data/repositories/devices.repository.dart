import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/shared/services/firestore.service.dart';

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
}