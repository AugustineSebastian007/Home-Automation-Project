
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:home_automation/features/navigation/data/models/side_menu_item.dart';

class SideMenuRepository {

  void signUserout(){
    FirebaseAuth.instance.signOut();
  }

  List<SideMenuItem> getSideMenuItems() {
    return [
      SideMenuItem(
        icon: Icons.info,
        label: 'About',
        route: '/login',
        onPressed: signUserout,
      ),
      SideMenuItem(
        icon: Icons.home,
        label: 'My Home',
        route: '/landing',
        onPressed: () {
        },
      ),
      SideMenuItem(
        icon: Icons.podcasts,
        label: 'My Network',
        route: '/network',
        onPressed: () {
        },
      ),
    ];
  }
}