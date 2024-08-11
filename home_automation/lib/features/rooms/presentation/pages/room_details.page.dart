import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/navigation/presentation/widgets/main_appbar.dart';
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
import 'package:home_automation/features/devices/presentation/providers/add_device_providers.dart';
import 'package:home_automation/features/outlets/presentation/providers/outlet_providers.dart';

class RoomDetailsPage extends ConsumerWidget {
  static const String route = '/room-details/:id';

  final String roomId;

  const RoomDetailsPage({required this.roomId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsyncValue = ref.watch(roomStreamProvider(roomId));
    final outletsAsyncValue = ref.watch(outletListStreamProvider(roomId));

    return Scaffold(
      appBar: HomeAutomationAppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/rooms');
          },
        ),
        title: 'Room Details',
      ),
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
              child: outletsAsyncValue.when(
                data: (outlets) => ListView.builder(
                  itemCount: outlets.length,
                  itemBuilder: (context, index) {
                    final outlet = outlets[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: Icon(Icons.power, color: Theme.of(context).colorScheme.primary),
                        title: Text(outlet.label),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () => context.goNamed(
                          'devices',
                          pathParameters: {'roomId': room.id, 'outletId': outlet.id},
                        ),
                      ),
                    );
                  },
                ),
                loading: () => Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error loading outlets: $error')),
              ),
            ),
          ],
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => context.goNamed('add-outlet', pathParameters: {'roomId': roomId}),
            child: Icon(Icons.add),
            heroTag: 'addOutlet',
          ),
          SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () => _showRemoveOutletDialog(context, ref),
            child: Icon(Icons.remove),
            heroTag: 'removeOutlet',
            backgroundColor: Colors.red,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showRemoveOutletDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Outlet'),
          content: Text('Are you sure you want to remove an outlet?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Remove'),
              onPressed: () {
                Navigator.of(context).pop();
                _removeOutlet(context, ref);
              },
            ),
          ],
        );
      },
    );
  }

  void _removeOutlet(BuildContext context, WidgetRef ref) {
    context.goNamed('remove-outlet', pathParameters: {'roomId': roomId});
  }
}