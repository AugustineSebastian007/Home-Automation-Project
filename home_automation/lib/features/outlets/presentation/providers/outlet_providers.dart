import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/outlets/data/models/outlet.model.dart';
import 'package:home_automation/features/outlets/data/repositories/outlet_repository.dart';
import 'package:home_automation/features/shared/providers/shared_providers.dart';

final outletRepositoryProvider = Provider((ref) => OutletRepository(ref.read(firestoreServiceProvider)));

final outletListStreamProvider = StreamProvider.family<List<OutletModel>, String>((ref, roomId) {
  final repository = ref.read(outletRepositoryProvider);
  return repository.streamOutlets(roomId);
});

final mainOutletProvider = FutureProvider<OutletModel>((ref) async {
  final repository = ref.read(outletRepositoryProvider);
  return await repository.getMainOutlet();
});
