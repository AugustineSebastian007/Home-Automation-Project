import 'package:home_automation/features/outlets/data/models/outlet.model.dart';
import 'package:home_automation/features/shared/services/firestore.service.dart';

class OutletsRepository {
  final FirestoreService _firestoreService;
  OutletsRepository(this._firestoreService);

  Future<List<OutletModel>> getOutlets(String roomId) {
    return _firestoreService.getOutlets(roomId);
  }
}