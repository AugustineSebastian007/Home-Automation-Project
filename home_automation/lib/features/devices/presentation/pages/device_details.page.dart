import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/features/devices/presentation/widgets/device_details_panel.dart';
import 'package:home_automation/features/navigation/presentation/widgets/main_appbar.dart';
import 'package:home_automation/styles/styles.dart';

class DeviceDetailsPage extends ConsumerWidget {
  static const String route = '/device-details/:roomId/:outletId';
  final String roomId;
  final String outletId;
  final DeviceModel device;

  const DeviceDetailsPage({
    Key? key,
    required this.roomId,
    required this.outletId,
    required this.device,
  }) : super(key: key);

  @override
Widget build(BuildContext context, WidgetRef ref) {
final deviceAsyncValue = ref.watch(deviceStreamProvider((roomId: roomId, outletId: outletId, deviceId: device.id)));
return Scaffold(
appBar: HomeAutomationAppBar(
leading: IconButton(
icon: Icon(Icons.arrow_back),
onPressed: () => context.pop(),
),
title: device.label,
),
body: SafeArea(
child: Padding(
padding: HomeAutomationStyles.largePadding,
child: deviceAsyncValue.when(
data: (updatedDevice) => DeviceDetailsPanel(device: updatedDevice),
loading: () => Center(child: CircularProgressIndicator()),
error: (error, stack) => Center(child: Text('Error: $error')),
),
),
),
);
}
}