import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/presentation/widgets/device_details_panel.dart';
import 'package:home_automation/features/navigation/presentation/widgets/main_appbar.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';

class DeviceDetailsPage extends ConsumerStatefulWidget {
  static const String route = 'device_details';
  final DeviceModel device;
  const DeviceDetailsPage({super.key, required this.device});

  @override
  ConsumerState<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends ConsumerState<DeviceDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(selectedDeviceProvider)?.id != widget.device.id) {
        ref.read(selectedDeviceProvider.notifier).state = widget.device;
        print("DeviceDetailsPage initState: ${widget.device.toJson()}");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceData = ref.watch(selectedDeviceProvider) ?? widget.device;

    return Scaffold(
      appBar: const HomeAutomationAppBar(),
      body: Padding(
        padding: HomeAutomationStyles.largePadding,
        child: SafeArea(
          child: DeviceDetailsPanel(device: deviceData),
        ),
      ),
    );
  }
}