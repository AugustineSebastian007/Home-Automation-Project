import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/data/models/outlet.model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'devices';

  Future<void> storeDeviceList(List<DeviceModel> devices) async {
    final batch = _firestore.batch();
    final devicesRef = _firestore.collection(_collection);

    // Delete existing devices
    final existingDocs = await devicesRef.get();
    for (var doc in existingDocs.docs) {
      batch.delete(doc.reference);
    }

    // Add new devices
    for (var device in devices) {
      final newDocRef = devicesRef.doc();
      batch.set(newDocRef, device.toJson());
    }

    await batch.commit();
  }

  Future<List<DeviceModel>> getDeviceList() async {
    final snapshot = await _firestore.collection('devices').get();
    print("Raw Firestore data: ${snapshot.docs.map((doc) => doc.data())}");
    return snapshot.docs.map((doc) => DeviceModel.fromJson({...doc.data(), 'id': doc.id})).toList();
  }

  Future<DocumentReference> addDevice(Map<String, dynamic> deviceData) async {
    return await _firestore.collection('devices').add(deviceData);
  }

  Future<void> removeDevice(String deviceId) async {
    await _firestore.collection(_collection).doc(deviceId).delete();
  }

  Future<List<OutletModel>> getOutlets() async {
    final snapshot = await _firestore.collection('outlets').get();
    return snapshot.docs.map((doc) => OutletModel.fromJson(doc.data())).toList();
  }
}