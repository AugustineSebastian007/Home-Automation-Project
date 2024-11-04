import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/rooms/data/models/room.model.dart';
import 'package:home_automation/features/rooms/presentation/providers/room_providers.dart';
import 'package:home_automation/features/outlets/data/models/outlet.model.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:uuid/uuid.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/features/outlets/presentation/providers/outlet_providers.dart';

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
              onPressed: () async {
                final roomName = _roomNameController.text.trim();
                if (roomName.isNotEmpty) {
                  final roomId = const Uuid().v4(); // Generate a unique ID for each new room
                  final defaultOutlet = _createDefaultOutlet(roomId);
                  final newRoom = RoomModel(
                    id: roomId,
                    name: roomName,
                    deviceCount: 5,
                  );
                  try {
                    await ref.read(roomRepositoryProvider).addRoom(newRoom);
                    await ref.read(outletRepositoryProvider).addOutlet(roomId, defaultOutlet);
                    await _addDefaultDevices(ref, roomId, defaultOutlet.id);
                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding room: $e')),
                    );
                  }
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

  OutletModel _createDefaultOutlet(String roomId) {
    return OutletModel(
      id: const Uuid().v4(), // Generate a unique ID for each new outlet
      label: 'ESP32',
      ip: '192.168.1.100', // You may want to make this configurable
      roomId: roomId,
    );
  }

  Future<void> _addDefaultDevices(WidgetRef ref, String roomId, String outletId) async {
    final deviceRepository = ref.read(deviceRepositoryProvider);
    final devices = [
      DeviceModel(
        id: Uuid().v4(),
        iconOption: FlickyAnimatedIconOptions.lightbulb,
        label: 'Light 1',
        isSelected: false,
        outlet: 1,
        roomId: roomId,
        outletId: outletId,
      ),
      DeviceModel(
        id: Uuid().v4(),
        iconOption: FlickyAnimatedIconOptions.lightbulb,
        label: 'Light 2',
        isSelected: false,
        outlet: 2,
        roomId: roomId,
        outletId: outletId,
      ),
      DeviceModel(
        id: Uuid().v4(),
        iconOption: FlickyAnimatedIconOptions.lightbulb,
        label: 'Light 3',
        isSelected: false,
        outlet: 3,
        roomId: roomId,
        outletId: outletId,
      ),
      DeviceModel(
        id: Uuid().v4(),
        iconOption: FlickyAnimatedIconOptions.lightbulb,
        label: 'Light 4',
        isSelected: false,
        outlet: 4,
        roomId: roomId,
        outletId: outletId,
      ),
      DeviceModel(
        id: Uuid().v4(),
        iconOption: FlickyAnimatedIconOptions.fan,
        label: 'Fan',
        isSelected: false,
        outlet: 5,
        roomId: roomId,
        outletId: outletId,
      ),
    ];

    for (var device in devices) {
      await deviceRepository.addDevice(roomId, outletId, device);
    }
  }
}
