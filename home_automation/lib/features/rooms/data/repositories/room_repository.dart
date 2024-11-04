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
    if (room.defaultOutlet != null) {
      await _outletRepository.addOutlet(room.id, room.defaultOutlet!);
    }
  }

  Stream<List<RoomModel>> streamRooms(String userId) {
    return _firestoreService.streamRooms(userId);
  }

  Future<void> removeRoom(String roomId) async {
    await _firestoreService.removeRoom(roomId);
  }

  Future<RoomModel> getMainRoom() async {
    const String mainRoomId = 'main_room';
    final existingRoom = await _firestoreService.getRoom(mainRoomId);
    if (existingRoom != null) {
      return existingRoom;
    }

    final mainRoom = RoomModel(
      id: mainRoomId,
      name: 'Main Room',
      deviceCount: 5,
      defaultOutlet: OutletModel(
        id: 'esp32',
        label: 'ESP32',
        ip: '192.168.1.100',
        roomId: mainRoomId,
      ),
    );
    await _firestoreService.addRoom(mainRoom);
    await _outletRepository.addOutlet(mainRoomId, mainRoom.defaultOutlet!);
    return mainRoom;
  }
}
