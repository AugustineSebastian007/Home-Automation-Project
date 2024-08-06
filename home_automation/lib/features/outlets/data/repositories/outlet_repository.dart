import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home_automation/features/outlets/data/models/outlet.model.dart';

class OutletRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<OutletModel>> getOutlets(String roomId) async {
    try {
      final querySnapshot = await _firestore
          .collection('outlets')
          .where('roomId', isEqualTo: roomId)
          .get();
      return querySnapshot.docs
          .map((doc) => OutletModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching outlets: $e');
      return [];
    }
  }

  Future<void> addOutlet(OutletModel outlet) async {
    try {
      await _firestore.collection('outlets').doc(outlet.id).set(outlet.toJson());
    } catch (e) {
      print('Error adding outlet: $e');
      throw e;
    }
  }
}
