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
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs.map((doc) => DeviceModel.fromJson(doc.data())).toList();
  }

  Future<List<OutletModel>> getOutlets() async {
    final snapshot = await _firestore.collection('outlets').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return OutletModel(
        id: (data['id'] ?? '').toString(),
        label: data['name'] as String? ?? '',
        ip: data['ip'] as String? ?? '0.0.0.0',
        isTaken: data['isTaken'] as bool? ?? false,
      );
    }).toList();
  }
}