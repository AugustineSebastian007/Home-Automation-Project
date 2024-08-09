import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/outlets/data/models/outlet.model.dart';
import 'package:home_automation/features/outlets/data/repositories/outlet_repository.dart';

final outletRepositoryProvider = Provider<OutletRepository>((ref) => OutletRepository());

final outletListProvider = FutureProvider.family<List<OutletModel>, String>((ref, roomId) async {
  final repository = ref.watch(outletRepositoryProvider);
  return repository.getOutlets(roomId);
});
