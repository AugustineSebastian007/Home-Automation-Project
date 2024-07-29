import 'package:flutter/material.dart';
import 'package:home_automation/features/devices/presentation/widgets/device_details_panel.dart';
import 'package:home_automation/features/navigation/presentation/widgets/main_appbar.dart';
import 'package:home_automation/styles/styles.dart';

class DeviceDetailsPage extends StatelessWidget {
  
  static const String route = '/device_details';
  const DeviceDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {

    return const Scaffold(
      appBar: HomeAutomationAppBar(),
      body: Padding(
        padding: HomeAutomationStyles.largePadding,
        child: SafeArea(
          child: DeviceDetailsPanel(),
        ),
      )
    );
  }
}