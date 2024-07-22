import 'package:flutter/material.dart';
import 'package:home_automation/features/decives/presentation/pages/devices.page.dart';
import 'package:home_automation/features/landing/presentation/pages/home.page.dart';
import 'package:home_automation/features/navigation/data/models/bottom_bar_nav_item.dart';
import 'package:home_automation/features/rooms/presentation/rooms.page.dart';
import 'package:home_automation/features/settings/presentation/pages/settings.page.dart';
import 'package:home_automation/styles/flicky_icons_icons.dart';

class BottomNavBarRepository {

  List<BottomBarNavItemModel> getBottomBarNavItems(){
    return const [
      BottomBarNavItemModel(
        iconOption : Icons.home,
        route : HomePage.route,
        isSelected: true,
      ),
      BottomBarNavItemModel(
        iconOption : FlickyIcons.room,
        route : RoomsPage.route,
      ),
      BottomBarNavItemModel(
        iconOption : FlickyIcons.heater,
        route : DevicesPage.route,
      ),
      BottomBarNavItemModel(
        iconOption : Icons.build,
        route : SettingsPage.route,
      ),
    ];
  }
}