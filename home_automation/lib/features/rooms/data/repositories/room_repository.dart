import 'package:home_automation/features/rooms/data/models/room.model.dart';
import 'package:home_automation/features/shared/services/firestore.service.dart';
import 'package:home_automation/features/outlets/data/repositories/outlet_repository.dart';
import 'package:home_automation/features/outlets/data/models/outlet.model.dart';

class RoomRepository {
  final FirestoreService _firestoreService;
  final OutletRepository _outletRepository;

  RoomRepository(this._firestoreService, this._outletRepository);

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

  Future<RoomModel?> getMainRoom() async {
    const String mainRoomId = 'main_room';
    try {
      final existingRoom = await _firestoreService.getRoom(mainRoomId);
      return existingRoom;
    } catch (e) {
      // Main room doesn't exist, just return null instead of creating it
      return null;
    }
  }
}
