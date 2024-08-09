import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/shared/widgets/warning_message.dart';
import 'package:home_automation/features/rooms/presentation/providers/room_providers.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';

class RoomsPage extends ConsumerWidget {
  static const String route = '/rooms';

  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsyncValue = ref.watch(roomListStreamProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MainPageHeader(
            icon: FlickyAnimatedIcons(
              icon: FlickyAnimatedIconOptions.barrooms,
              size: FlickyAnimatedIconSizes.large,
              isSelected: true,
            ),
            title: 'My Rooms',
          ),
          Expanded(
            child: Padding(
              padding: HomeAutomationStyles.mediumPadding,
              child: roomsAsyncValue.when(
                data: (rooms) {
                  if (rooms.isEmpty) {
                    return const WarningMessage(message: 'No available rooms');
                  }
                  return ListView.builder(
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Icon(Icons.room, color: Colors.grey),
                          title: Text(room.name),
                          subtitle: Text('${room.deviceCount} Devices'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.air, color: Colors.green),
                              SizedBox(width: 8),
                              Icon(Icons.lightbulb_outline, color: Colors.grey),
                            ],
                          ),
                          onTap: () => context.push('/room-details/${room.id}'),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoomDetailsPage extends ConsumerWidget {
  static const String route = '/room-details/:id';

  final String roomId;

  const RoomDetailsPage({required this.roomId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsyncValue = ref.watch(roomProvider(roomId));

    return Scaffold(
      appBar: AppBar(title: Text('Room Details')),
      body: Padding(
        padding: HomeAutomationStyles.largePadding,
        child: SafeArea(
          child: roomAsyncValue.when(
            data: (room) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 16),
                Text(
                  'Room Devices',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      DeviceListTile(
                        icon: Icons.air,
                        title: 'Fan',
                        isOn: true,
                        onToggle: (value) {
                          // Handle fan toggle
                        },
                      ),
                      DeviceListTile(
                        icon: Icons.lightbulb_outline,
                        title: 'Light',
                        isOn: false,
                        onToggle: (value) {
                          // Handle light toggle
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
      bottomSheet: Padding(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          child: Text('Remove this Room'),
          onPressed: () {
            // Handle room removal
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }
}

class DeviceListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isOn;
  final Function(bool) onToggle;

  const DeviceListTile({
    required this.icon,
    required this.title,
    required this.isOn,
    required this.onToggle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isOn ? Colors.green : Colors.grey),
      title: Text(title),
      trailing: Switch(
        value: isOn,
        onChanged: onToggle,
      ),
    );
  }
}