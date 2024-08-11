import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/rooms/presentation/providers/room_providers.dart';
import 'package:home_automation/features/rooms/presentation/widgets/rooms_list.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/features/auth/presentation/providers/auth_providers.dart';


class RoomsPage extends ConsumerWidget {
  static const String route = '/rooms';

  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRoomsAsyncValue = ref.watch(userRoomsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
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
              child: userRoomsAsyncValue.when(
                data: (rooms) => RoomsList(rooms: rooms),
                loading: () => Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () => context.push('/add-room'),
              child: Icon(Icons.add),
              heroTag: 'addRoom',
            ),
            SizedBox(width: 16),
            FloatingActionButton(
              onPressed: () => _showRemoveRoomDialog(context, ref),
              child: Icon(Icons.remove),
              heroTag: 'removeRoom',
              backgroundColor: Colors.red,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showRemoveRoomDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Room'),
          content: Text('Are you sure you want to remove a room?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Remove'),
              onPressed: () {
                Navigator.of(context).pop();
                context.goNamed('remove-room');
              },
            ),
          ],
        );
      },
    );
  }
}