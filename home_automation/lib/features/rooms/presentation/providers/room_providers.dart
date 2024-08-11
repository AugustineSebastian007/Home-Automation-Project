import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/rooms/data/models/room.model.dart';
import 'package:home_automation/features/rooms/data/repositories/room_repository.dart';
import 'package:home_automation/features/shared/services/firestore.service.dart';
import 'package:home_automation/features/auth/presentation/providers/auth_providers.dart' show authStateProvider;

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final roomRepositoryProvider = Provider((ref) => RoomRepository(ref.read(firestoreServiceProvider)));

final roomListStreamProvider = StreamProvider.family<List<RoomModel>, String>((ref, userId) {
  final repository = ref.read(roomRepositoryProvider);
  return repository.streamRooms(userId);
});

final roomStreamProvider = StreamProvider.family<RoomModel, String>((ref, roomId) {
  final repository = ref.read(roomRepositoryProvider);
  return repository.streamRoom(roomId);
});

final userRoomsProvider = Provider<AsyncValue<List<RoomModel>>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) {
        return const AsyncValue.data([]);
      }
      return ref.watch(roomListStreamProvider(user.uid));
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});