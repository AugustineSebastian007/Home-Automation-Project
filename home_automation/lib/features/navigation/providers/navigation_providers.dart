import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/navigation/data/models/bottom_bar_nav_item.dart';
import 'package:home_automation/features/navigation/data/models/side_menu_item.dart';
import 'package:home_automation/features/navigation/data/repositories/bottomnavbar.repository.dart';
import 'package:home_automation/features/navigation/data/repositories/sidemenu.repository.dart';
import 'package:home_automation/features/navigation/presentation/viewmodels/bottombar.viewmodel.dart';


final bottomBarVMProvider = StateNotifierProvider<BottomBarViewModel, List<BottomBarNavItemModel>>((ref) {
  final navItems = ref.read(bottomBarRepositoryProvider).getBottomBarNavItems();
  return BottomBarViewModel(navItems, ref);
});

final bottomBarRepositoryProvider = Provider((ref) {
  return BottomNavBarRepository();
});

final sideMenuRepositoryProvider = Provider((ref) {
  return SideMenuRepository();
});

final sideMenuProvider = Provider<List<SideMenuItem>>((ref) {
  return ref.read(sideMenuRepositoryProvider).getSideMenuItems();
});

