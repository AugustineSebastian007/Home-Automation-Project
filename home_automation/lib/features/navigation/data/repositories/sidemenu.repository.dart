import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/navigation/data/models/side_menu_item.dart';
import 'package:home_automation/helpers/utils.dart';

class SideMenuRepository {

  void signUserout(){
    FirebaseAuth.instance.signOut();
  }

  List<SideMenuItem> getSideMenuItems() {
    final context = Utils.mainNav.currentContext!;
    
    return [
      SideMenuItem(
        icon: Icons.dashboard,
        label: 'Dashboard',
        route: '/home', 
        onPressed: () {
          Navigator.pop(context);
          GoRouter.of(context).go('/home');
        },
      ),
      SideMenuItem(
        icon: Icons.home,
        label: 'My Home',
        route: '/rooms',
        onPressed: () {
          Navigator.pop(context);
          GoRouter.of(context).go('/rooms');
        },
      ),
      SideMenuItem(
        icon: Icons.schedule,
        label: 'My Schedule',
        route: '/profiling',
        onPressed: () {
          Navigator.pop(context);
          GoRouter.of(context).go('/profiling');
        },
      ),
    ];
  }
}