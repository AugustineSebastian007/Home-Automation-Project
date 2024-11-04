import 'package:home_automation/features/outlets/data/models/outlet.model.dart';
import 'package:home_automation/features/shared/services/firestore.service.dart';

class OutletRepository {
  final FirestoreService _firestoreService;

  OutletRepository(this._firestoreService);

  Future<List<OutletModel>> getOutlets(String roomId) async {
    return await _firestoreService.getOutlets(roomId);
  }

  Future<void> addOutlet(String roomId, OutletModel outlet) async {
    await _firestoreService.addOutlet(roomId, outlet);
  }

  Stream<List<OutletModel>> streamOutlets(String roomId) {
    return _firestoreService.streamOutlets(roomId);
  }

  Future<void> removeOutlet(String roomId, String outletId) async {
    await _firestoreService.deleteDocument('outlets', outletId);
  }

  Future<void> removeAllOutlets(String roomId) async {
    await _firestoreService.removeAllOutlets(roomId);
  }

  Future<OutletModel> getMainOutlet() async {
    return OutletModel(
      id: 'esp32',
      label: 'ESP32',
      ip: '192.168.1.100',
      roomId: 'main_room',
    );
  }
}
