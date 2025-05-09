import 'package:flutter/material.dart';
import 'package:home_automation/features/landing/data/models/home_tile_option.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/flicky_icons_icons.dart';

class HomeTileOptionsRepository {

  List<HomeTileOption> getHomeTileOptions() {
    return [
      HomeTileOption(
        icon: Icons.add_circle_outline, 
        label: 'Add New Device', 
        option: HomeTileOptions.addDevice,
      ),
      HomeTileOption(
        icon: FlickyIcons.oven,
        label: 'Manage Devices', 
        option: HomeTileOptions.manageDevices,
      ),
      HomeTileOption(
        icon: Icons.energy_savings_leaf,
        label: 'Energy Saving', 
        option: HomeTileOptions.energySaving,
      ),
      // HomeTileOption(
      //   icon: Icons.sensors,
      //   label: 'Test Connectivity', 
      //   option: HomeTileOptions.testConnection,
      // ),
    ];
  }
}