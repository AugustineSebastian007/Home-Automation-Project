import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:home_automation/features/profiling/data/models/profile.model.dart';
import 'package:home_automation/features/rooms/data/models/room.model.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/outlets/data/models/outlet.model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser!.uid;

  // Rooms
  Future<List<RoomModel>> getRooms() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .get();
    return snapshot.docs.map((doc) => RoomModel.fromJson(doc.data())).toList();
  }

  Future<void> addRoom(RoomModel room) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(room.id)
        .set(room.toJson());
  }

  Future<RoomModel> getRoom(String roomId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .get();
    if (doc.exists) {
      return RoomModel.fromJson(doc.data()!);
    } else {
      throw Exception('Room not found');
    }
  }

  Stream<List<RoomModel>> streamRooms(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomModel.fromJson(doc.data()))
            .toList());
  }

  Stream<RoomModel> streamRoom(String roomId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((snapshot) => RoomModel.fromJson(snapshot.data()!));
  }

  // Outlets
  Future<List<OutletModel>> getOutlets(String roomId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .collection('outlets')
        .get();
    return snapshot.docs
        .map((doc) => OutletModel.fromJson(doc.data()))
        .toList();
  }

  Future<void> addOutlet(String roomId, OutletModel outlet) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .collection('outlets')
        .doc(outlet.id)
        .set(outlet.toJson());
  }

  Stream<List<OutletModel>> streamOutlets(String roomId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .collection('outlets')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OutletModel.fromJson(doc.data()))
            .toList());
  }

  Future<void> removeOutlet(String roomId, String outletId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .collection('outlets')
        .doc(outletId)
        .delete();
  }

  Future<void> removeAllOutlets(String roomId) async {
    final outletsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .collection('outlets')
        .get();

    final batch = _firestore.batch();
    for (var doc in outletsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Devices
  Future<List<DeviceModel>> getDevices(String roomId, String outletId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .collection('outlets')
        .doc(outletId)
        .collection('devices')
        .get();
    return snapshot.docs
        .map((doc) => DeviceModel.fromJson(doc.data()))
        .toList();
  }

  Future<void> addDevice(
      String roomId, String outletId, DeviceModel device) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .collection('outlets')
        .doc(outletId)
        .collection('devices')
        .doc(device.id)
        .set(device.toJson());
  }

  Future<void> updateDevice(
      String roomId, String outletId, DeviceModel device) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .collection('outlets')
        .doc(outletId)
        .collection('devices')
        .doc(device.id)
        .update(device.toJson());
  }

  Future<void> removeDevice(
      String roomId, String outletId, String deviceId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .collection('outlets')
        .doc(outletId)
        .collection('devices')
        .doc(deviceId)
        .delete();
  }

  Stream<List<DeviceModel>> streamDevices(String roomId, String outletId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .collection('outlets')
        .doc(outletId)
        .collection('devices')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeviceModel.fromJson(doc.data()))
            .toList());
  }

  Stream<DeviceModel> streamDevice(
      String roomId, String outletId, String deviceId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .collection('outlets')
        .doc(outletId)
        .collection('devices')
        .doc(deviceId)
        .snapshots()
        .map((snapshot) => DeviceModel.fromJson(snapshot.data()!));
  }

  Stream<List<DeviceModel>> streamAllDevices() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .snapshots()
        .asyncMap((roomSnapshot) async {
      List<DeviceModel> allDevices = [];
      for (var roomDoc in roomSnapshot.docs) {
        final outletSnapshot = await roomDoc.reference.collection('outlets').get();
        for (var outletDoc in outletSnapshot.docs) {
          final deviceSnapshot = await outletDoc.reference.collection('devices').get();
          allDevices.addAll(deviceSnapshot.docs.map((doc) => DeviceModel.fromJson(doc.data())));
        }
      }
      return allDevices;
    });
  }

  Future<List<DeviceModel>> getListOfDevices() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .get();
    return snapshot.docs
        .map((doc) => DeviceModel.fromJson(doc.data()))
        .toList();
  }

  Future<DeviceModel> getDeviceDetails(String deviceId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(deviceId)
        .get();
    if (doc.exists) {
      return DeviceModel.fromJson(doc.data()!);
    } else {
      throw Exception('Device not found');
    }
  }

  Stream<List<DeviceModel>> listenToDevices() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .snapshots()
        .asyncMap((roomSnapshot) async {
      List<DeviceModel> allDevices = [];
      for (var roomDoc in roomSnapshot.docs) {
        final outletSnapshot = await roomDoc.reference.collection('outlets').get();
        for (var outletDoc in outletSnapshot.docs) {
          final deviceSnapshot = await outletDoc.reference.collection('devices').snapshots().first;
          allDevices.addAll(deviceSnapshot.docs.map((doc) => DeviceModel.fromJson(doc.data())));
        }
      }
      return allDevices;
    });
  }

  Future<ProfileModel> getProfile(String profileId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .doc(profileId)
        .get();
    return ProfileModel.fromJson(doc.data()!);
  }

  Future<void> deleteDocument(String collection, String documentId) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  Future<void> removeRoom(String roomId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .doc(roomId)
        .delete();
  }

  // Profiles
  Stream<List<ProfileModel>> streamProfiles() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProfileModel.fromJson(doc.data()))
            .toList());
  }

  Stream<ProfileModel> streamProfile(String profileId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .doc(profileId)
        .snapshots()
        .map((snapshot) => ProfileModel.fromJson(snapshot.data()!));
  }

  Future<void> addProfile(ProfileModel profile) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .doc(profile.id)
        .set(profile.toJson());
  }

  Future<void> updateProfile(ProfileModel profile) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .doc(profile.id)
        .update(profile.toJson());
  }
  Future<void> deleteProfile(String profileId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .doc(profileId)
        .delete();
  }
}
