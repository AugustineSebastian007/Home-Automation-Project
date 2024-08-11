import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/devices/presentation/widgets/devices_list.dart';
import 'package:home_automation/features/rooms/presentation/providers/room_providers.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/presentation/widgets/device_row_item.dart';
import 'package:home_automation/features/devices/presentation/widgets/device_details_panel.dart';

class RoomDetailsPage extends ConsumerWidget {
  static const String route = '/room-details/:id';

  final String roomId;

  const RoomDetailsPage({required this.roomId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsyncValue = ref.watch(roomProvider(roomId));

    // Create dummy devices
    final dummyDevices = [
      DeviceModel(
        id: 'dummy1',
        label: 'Dummy Device 1',
        iconOption: FlickyAnimatedIconOptions.lightbulb,
        isSelected: true,
        outlet: 1,
      ),
      DeviceModel(
        id: 'dummy2',
        label: 'Dummy Device 2',
        iconOption: FlickyAnimatedIconOptions.fan,
        isSelected: true,
        outlet: 2,
      ),
    ];

    return Scaffold(
      body: roomAsyncValue.when(
        data: (room) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MainPageHeader(
              icon: FlickyAnimatedIcons(
                icon: FlickyAnimatedIconOptions.barrooms,
                size: FlickyAnimatedIconSizes.large,
                isSelected: true,
              ),
              title: room.name,
            ),
            Expanded(
              child: Padding(
                padding: HomeAutomationStyles.mediumPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: dummyDevices.length,
                        itemBuilder: (context, index) {
                          return DeviceRowItem(
                            device: dummyDevices[index],
                            onTapDevice: (device) {
                              ref.read(selectedDeviceProvider.notifier).state = device;
                            },
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final selectedDevice = ref.watch(selectedDeviceProvider);
                          if (selectedDevice != null) {
                            return DeviceDetailsPanel(device: selectedDevice);
                          } else {
                            return const Center(child: Text('No device selected'));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add device functionality
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}