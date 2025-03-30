// import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/devices/presentation/providers/add_device_providers.dart';
import 'package:home_automation/features/devices/presentation/widgets/add_device_sheet.dart';
import 'package:home_automation/features/landing/data/models/home_tile_option.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/helpers/utils.dart';

class HomeTileOptionsViewmodel extends StateNotifier<List<HomeTileOption>> {

  final Ref ref;
  HomeTileOptionsViewmodel(super.state, this.ref);

  void onTileSelected(HomeTileOption option) {
    switch(option.option) {
      case HomeTileOptions.addDevice:
        Utils.showUIModal(
          Utils.mainNav.currentContext!,
          const AddDeviceSheet(),
          onDismissed: () {
            ref.read(saveAddDeviceVMProvider.notifier).resetAllValues();
          }
        );
        break;
      case HomeTileOptions.manageDevices:
        Utils.mainNav.currentContext!.go('/rooms');
        break;
      case HomeTileOptions.energySaving:
        Utils.mainNav.currentContext!.go('/energy-saving');
        break;
      // case HomeTileOptions.testConnection:
      //   break;
      default:
        // Do nothing for unhandled options
        break;
    }
  }
}