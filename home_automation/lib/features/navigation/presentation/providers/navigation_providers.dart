import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/navigation/data/models/bottom_bar_nav_item.dart';
import 'package:home_automation/features/navigation/data/repository/bottom_nav_bar.repository.dart';
import 'package:home_automation/features/navigation/presentation/viewmodels/bottom_bar.viewmodel.dart';

final bottomBarRepositoryProvider = Provider((ref){
  return BottomNavBarRepository();
});

final bottomBarVMProvider = StateNotifierProvider<BottomBarViewModel,List<BottomBarNavItemModel>>((ref){
  final navItems = ref.read(bottomBarRepositoryProvider).getBottomBarNavItems();
  return BottomBarViewModel(navItems,ref);
});