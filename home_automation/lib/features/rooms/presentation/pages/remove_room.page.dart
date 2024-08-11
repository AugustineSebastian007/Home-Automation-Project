import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/rooms/presentation/providers/room_providers.dart';
import 'package:home_automation/features/navigation/presentation/widgets/main_appbar.dart';
import 'package:home_automation/styles/styles.dart';

class RemoveRoomPage extends ConsumerWidget {
  static const String route = '/remove-room';

  const RemoveRoomPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRoomsAsyncValue = ref.watch(userRoomsProvider);

    return Scaffold(
      appBar: HomeAutomationAppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/rooms'),
        ),
        title: 'Remove Room',
      ),
      body: Padding(
        padding: HomeAutomationStyles.mediumPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a room to remove:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Expanded(
              child: userRoomsAsyncValue.when(
                data: (rooms) => ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.room, color: Theme.of(context).colorScheme.primary),
                        title: Text(room.name),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showRemoveConfirmationDialog(context, ref, room.id),
                        ),
                      ),
                    );
                  },
                ),
                loading: () => Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error loading rooms: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveConfirmationDialog(BuildContext context, WidgetRef ref, String roomId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Removal'),
          content: Text('Are you sure you want to remove this room?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Remove'),
              onPressed: () {
                Navigator.of(context).pop();
                _removeRoom(context, ref, roomId);
              },
            ),
          ],
        );
      },
    );
  }

  void _removeRoom(BuildContext context, WidgetRef ref, String roomId) {
    ref.read(roomRepositoryProvider).removeRoom(roomId).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room removed successfully')),
      );
      context.go('/rooms'); // Navigate back to the rooms list
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing room: $error')),
      );
    });
  }
}