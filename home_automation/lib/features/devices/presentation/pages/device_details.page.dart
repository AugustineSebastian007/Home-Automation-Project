import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/presentation/widgets/device_details_panel.dart';
import 'package:home_automation/features/navigation/presentation/widgets/main_appbar.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';

class DeviceDetailsPage extends ConsumerWidget {
  static const String route = 'device_details';
  final DeviceModel device;
  const DeviceDetailsPage({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceStream = ref.watch(selectedDeviceStreamProvider(device.id));

    return Scaffold(
      appBar: const HomeAutomationAppBar(),
      body: Padding(
        padding: HomeAutomationStyles.largePadding,
        child: SafeArea(
          child: deviceStream.when(
            data: (device) => DeviceDetailsPanel(device: device),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
    );
  }
}