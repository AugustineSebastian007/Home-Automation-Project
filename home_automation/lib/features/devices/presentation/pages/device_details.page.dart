import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/presentation/widgets/device_details_panel.dart';
import 'package:home_automation/features/navigation/presentation/widgets/main_appbar.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';

class DeviceDetailsPage extends ConsumerWidget {
  
  static const String route = '/device_details';
  const DeviceDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceData = ref.watch(selectedDeviceProvider);
    print("DeviceDetailsPage build method called");
    print("Selected device data: ${deviceData?.toJson()}");

    if (deviceData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const HomeAutomationAppBar(),
      body: Padding(
        padding: HomeAutomationStyles.largePadding,
        child: SafeArea(
          child: DeviceDetailsPanel(device: deviceData),
        ),
      )
    );
  }
}