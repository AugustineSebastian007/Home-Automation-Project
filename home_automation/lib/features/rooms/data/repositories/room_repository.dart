import 'package:home_automation/features/rooms/data/models/room.model.dart';
import 'package:home_automation/features/shared/services/firestore.service.dart';

class RoomRepository {
  final FirestoreService _firestoreService;

  RoomRepository(this._firestoreService);

  Future<List<RoomModel>> getRooms() async {
    return await _firestoreService.getRooms();
  }

  Stream<RoomModel> streamRoom(String roomId) {
    return _firestoreService.streamRoom(roomId);
  }

  Future<RoomModel> getRoom(String roomId) async {
    return await _firestoreService.getRoom(roomId);
  }

  Future<void> addRoom(RoomModel room) async {
    await _firestoreService.addRoom(room);
  }

  Stream<List<RoomModel>> streamRooms(String userId) {
    return _firestoreService.streamRooms(userId);
  }

  Future<void> removeRoom(String roomId) async {
    await _firestoreService.removeRoom(roomId);
  }
}