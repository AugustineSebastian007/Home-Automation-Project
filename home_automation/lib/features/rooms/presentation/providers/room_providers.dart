import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/rooms/data/models/room.model.dart';
import 'package:home_automation/features/rooms/data/repositories/room_repository.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) => RoomRepository());

final roomListStreamProvider = StreamProvider<List<RoomModel>>((ref) {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getRoomsStream();
});

final roomProvider = FutureProvider.family<RoomModel, String>((ref, roomId) async {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getRoom(roomId);
});

final roomValueProvider = StateProvider<RoomModel?>((ref) => null);