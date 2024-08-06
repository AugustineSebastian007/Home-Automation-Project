import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home_automation/features/devices/data/models/room.model.dart';

class RoomRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<RoomModel>> getRooms() async {
    try {
      final querySnapshot = await _firestore.collection('rooms').get();
      return querySnapshot.docs
          .map((doc) => RoomModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching rooms: $e');
      return [];
    }
  }

  Future<RoomModel> getRoom(String roomId) async {
    try {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      if (doc.exists) {
        return RoomModel.fromJson(doc.data()!);
      } else {
        throw Exception('Room not found');
      }
    } catch (e) {
      print('Error fetching room: $e');
      throw e;
    }
  }
}