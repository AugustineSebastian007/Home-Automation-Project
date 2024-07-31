import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/data/models/outlet.model.dart';
import 'package:home_automation/features/devices/presentation/providers/add_device_providers.dart';

class OutletsRepository {
  final Ref ref;
  OutletsRepository(this.ref);

  Future<List<OutletModel>> getAvailableOutlets() async {
    final firestoreService = ref.read(firestoreServiceProvider);
    return await firestoreService.getOutlets();
  }
}