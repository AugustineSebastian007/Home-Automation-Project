import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/data/models/outlet.model.dart';

class OutletListViewModel extends StateNotifier<List<OutletModel>> {
  final Ref ref;
  OutletListViewModel(List<OutletModel> initialState, this.ref) : super(initialState);

  void initializeList(List<OutletModel> outletList) {
    state = outletList;
  }

  void selectOutlet(OutletModel outlet) {
    state = state.map((o) => o.id == outlet.id ? outlet.copyWith(isTaken: true) : o).toList();
  }

  void unselectOutlet(OutletModel outlet) {
    state = state.map((o) => o.id == outlet.id ? outlet.copyWith(isTaken: false) : o).toList();
  }
}