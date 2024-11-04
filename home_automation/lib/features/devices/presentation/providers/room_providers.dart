import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/rooms/data/models/room.model.dart';
import 'package:home_automation/features/rooms/data/repositories/room_repository.dart';
import 'package:home_automation/features/shared/providers/shared_providers.dart' as shared;
import 'package:home_automation/features/outlets/presentation/providers/outlet_providers.dart';

final roomRepositoryProvider = Provider((ref) {
  final firestoreService = ref.read(shared.firestoreServiceProvider);
  final outletRepository = ref.read(outletRepositoryProvider);
  return RoomRepository(firestoreService, outletRepository);
});

final roomListProvider = FutureProvider<List<RoomModel>>((ref) async {
  final repository = ref.read(roomRepositoryProvider);
  return await repository.getRooms();
});

final roomValueProvider = StateProvider<RoomModel?>((ref) => null);

final roomProvider = FutureProvider.family<RoomModel, String>((ref, roomId) async {
  final repository = ref.read(roomRepositoryProvider);
  return await repository.getRoom(roomId);
});
