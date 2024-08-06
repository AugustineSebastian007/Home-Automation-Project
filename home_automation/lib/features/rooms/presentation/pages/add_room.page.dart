import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/rooms/data/models/room.model.dart';
import 'package:home_automation/features/rooms/presentation/providers/room_providers.dart';
import 'package:home_automation/styles/styles.dart';

class AddRoomPage extends ConsumerWidget {
  static const String route = '/add-room';

  AddRoomPage({Key? key}) : super(key: key);

  final TextEditingController _roomNameController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Add New Room')),
      body: Padding(
        padding: HomeAutomationStyles.largePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _roomNameController,
              decoration: InputDecoration(
                labelText: 'Room Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final roomName = _roomNameController.text.trim();
                if (roomName.isNotEmpty) {
                  final newRoom = RoomModel(
                    id: DateTime.now().toString(),
                    name: roomName,
                  );
                  ref.read(roomRepositoryProvider).addRoom(newRoom);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add Room'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                textStyle: textTheme.labelLarge,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}