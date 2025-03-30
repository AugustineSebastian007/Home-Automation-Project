import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:home_automation/features/profiling/data/models/profile.model.dart';
import 'package:home_automation/features/rooms/data/models/room.model.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/outlets/data/models/outlet.model.dart';
import 'package:home_automation/features/household/data/models/household_member.model.dart';
import 'package:rxdart/rxdart.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

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
    
    // Update the room's device count
    await updateRoomDeviceCount(roomId);
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
    
    // Update the room's device count
    await updateRoomDeviceCount(roomId);
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
    final membersSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('household_members')
        .get();

    for (var memberDoc in membersSnapshot.docs) {
      final profileDoc = await memberDoc.reference
          .collection('profiles')
          .doc(profileId)
          .get();

      if (profileDoc.exists) {
        final data = profileDoc.data()!;
        data['memberId'] = memberDoc.id;
        data['id'] = profileId;
        return ProfileModel.fromJson(data);
      }
    }
    throw Exception('Profile not found');
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
        .collection('household_members')
        .snapshots()
        .switchMap((memberSnapshot) {
          final profileStreams = memberSnapshot.docs.map((memberDoc) {
            return memberDoc.reference
                .collection('profiles')
                .snapshots()
                .map((profileSnapshot) {
                  return profileSnapshot.docs.map((profileDoc) {
                    final data = profileDoc.data();
                    data['memberId'] = memberDoc.id;
                    data['id'] = profileDoc.id;
                    return ProfileModel.fromJson(data);
                  }).toList();
                });
          });

          if (profileStreams.isEmpty) {
            return Stream.value(<ProfileModel>[]);
          }

          return Rx.combineLatestList(profileStreams).map((listOfProfileLists) {
            return listOfProfileLists.expand((profiles) => profiles).toList();
          });
        });
  }

  Stream<ProfileModel> streamProfile(String memberId, String profileId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('household_members')
        .doc(memberId)
        .collection('profiles')
        .doc(profileId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            throw Exception('Profile not found');
          }
          final data = snapshot.data()!;
          data['memberId'] = memberId;
          data['id'] = profileId;
          return ProfileModel.fromJson(data);
        });
  }

  Future<void> addProfile(String memberId, ProfileModel profile) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('household_members')
        .doc(memberId)
        .collection('profiles')
        .doc(profile.id)
        .set(profile.toJson());
  }

  Future<void> updateProfile(String memberId, ProfileModel profile) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('household_members')
        .doc(memberId)
        .collection('profiles')
        .doc(profile.id)
        .update(profile.toJson());
  }

  Future<void> deleteProfile(String memberId, String profileId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('household_members')
        .doc(memberId)
        .collection('profiles')
        .doc(profileId)
        .delete();
  }

  Future<void> saveCameraBoundaryPoints(String feedPath, List<List<double>> points) async {
    try {
      // Ensure user is authenticated
      if (_auth.currentUser == null) {
        print('No authenticated user');
        return;
      }

      // Split the feed path and create a proper nested collection path
      final pathSegments = feedPath.split('/');
      
      // Construct a reference that ensures an even number of segments
      DocumentReference docRef = _firestore.collection('users').doc(userId);
      for (int i = 0; i < pathSegments.length; i++) {
        docRef = docRef.collection(pathSegments[i]).doc(pathSegments[++i] ?? 'default');
      }

      await docRef.collection('boundaries').doc('main').set({
        'points': points.map((point) => {
          'x': point[0],
          'y': point[1],
        }).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Boundary points saved successfully for $feedPath');
    } catch (e) {
      print('Error saving boundary points: $e');
      throw Exception('Failed to save boundary points: $e');
    }
  }

  Stream<List<List<double>>> streamCameraBoundaryPoints(String feedPath) {
    try {
      // Split the feed path and create a proper nested collection path
      final pathSegments = feedPath.split('/');
      
      // Construct a reference that ensures an even number of segments
      DocumentReference docRef = _firestore.collection('users').doc(userId);
      for (int i = 0; i < pathSegments.length; i++) {
        docRef = docRef.collection(pathSegments[i]).doc(pathSegments[++i] ?? 'default');
      }

      return docRef.collection('boundaries').doc('main').snapshots().map((snapshot) {
        if (!snapshot.exists || !snapshot.data()!.containsKey('points')) {
          return [];
        }
        
        final List<dynamic> points = snapshot.data()!['points'] as List<dynamic>;
        return points.map<List<double>>((point) {
          final Map<String, dynamic> pointData = point as Map<String, dynamic>;
          return [
            (pointData['x'] as num).toDouble(),
            (pointData['y'] as num).toDouble(),
          ];
        }).toList();
      });
    } catch (e) {
      print('Error streaming boundary points: $e');
      return Stream.value([]);
    }
  }

  Stream<List<HouseholdMemberModel>> streamHouseholdMembers() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('household_members')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HouseholdMemberModel.fromJson(doc.data()))
            .toList());
  }

  Future<void> addHouseholdMember(HouseholdMemberModel member) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('household_members')
        .doc(member.id)
        .set(member.toJson());
  }

  Future<void> updateHouseholdMember(String memberId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('household_members')
        .doc(memberId)
        .update(data);
  }

  Future<void> deleteHouseholdMember(String memberId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('household_members')
        .doc(memberId)
        .delete();
  }

  // Update room device count
  Future<void> updateRoomDeviceCount(String roomId) async {
    try {
      // Get all outlets in the room
      final outlets = await getOutlets(roomId);
      
      // Count all devices across all outlets
      int totalDevices = 0;
      for (var outlet in outlets) {
        final devices = await getDevices(roomId, outlet.id);
        totalDevices += devices.length;
      }
      
      // Get the current room data
      final roomDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('rooms')
          .doc(roomId)
          .get();
      
      if (roomDoc.exists) {
        final room = RoomModel.fromJson(roomDoc.data()!);
        
        // Only update if the count is different
        if (room.deviceCount != totalDevices) {
          // Update the room with the new device count
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('rooms')
              .doc(roomId)
              .update({'deviceCount': totalDevices});
          
          print('Updated device count for room $roomId to $totalDevices');
        }
      }
    } catch (e) {
      print('Error updating room device count: $e');
    }
  }
}
