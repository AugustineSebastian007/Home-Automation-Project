import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/features/devices/presentation/widgets/device_tile.dart';
import 'package:home_automation/features/navigation/presentation/widgets/main_appbar.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';

class DevicesPage extends ConsumerWidget {
  static const String route = '/devices/:roomId/:outletId';
  final String roomId;
  final String outletId;

  const DevicesPage({Key? key, required this.roomId, required this.outletId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsyncValue = ref.watch(deviceListStreamProvider((roomId: roomId, outletId: outletId)));

    return Scaffold(
      appBar: HomeAutomationAppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/room-details/$roomId');
          },
        ),
        title: 'Devices',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MainPageHeader(
            icon: FlickyAnimatedIcons(
              icon: FlickyAnimatedIconOptions.bardevices,
              size: FlickyAnimatedIconSizes.large,
              isSelected: true,
            ),
            title: 'My Devices',
          ),
          Expanded(
            child: devicesAsyncValue.when(
              data: (devices) => ListView.builder(
                itemCount: devices.length,
                padding: HomeAutomationStyles.mediumPadding,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return DeviceTile(device: device);
                },
              ),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}