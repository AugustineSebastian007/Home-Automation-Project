import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/shared/widgets/warning_message.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/rooms/presentation/widgets/room_tile.dart';
import 'package:home_automation/features/rooms/data/models/room.model.dart';
import 'package:home_automation/features/rooms/presentation/providers/room_providers.dart';

class RoomsList extends ConsumerWidget {
  final List<RoomModel> rooms;

  const RoomsList({super.key, required this.rooms});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Refresh device counts when rooms list is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refresh(updateAllRoomDeviceCountsProvider);
    });
    
    final List<Widget> roomWidgets = [
      ...rooms.map((room) => _buildRoomTile(context, ref, room)),
      _buildDummyRoomTile(context),
    ];

    return roomWidgets.isNotEmpty
      ? ListView(
          padding: HomeAutomationStyles.mediumPadding,
          children: roomWidgets,
        )
      : const WarningMessage(message: "No available rooms");
  }

  Widget _buildRoomTile(BuildContext context, WidgetRef ref, RoomModel room) {
    return RoomTile(
      room: room,
      onTap: () => context.push('/room-details/${room.id}'),
      onDelete: room.id == 'dummy' ? null : () => _showDeleteConfirmation(context, ref, room),
    ).animate(
      delay: (rooms.indexOf(room) * 0.125).seconds,
    ).slideY(
      begin: 0.5, end: 0,
      duration: 0.5.seconds,
      curve: Curves.easeInOut
    ).fadeIn(
      duration: 0.5.seconds,
      curve: Curves.easeInOut
    );
  }

  Widget _buildDummyRoomTile(BuildContext context) {
    return RoomTile(
      room: RoomModel(id: 'dummy', name: 'Main Hall', deviceCount: 5),
      onTap: () => context.push('/dummy-main-hall'),
      onDelete: null, // No delete option for dummy room
    ).animate(
      delay: (rooms.length * 0.125).seconds,
    ).slideY(
      begin: 0.5, end: 0,
      duration: 0.5.seconds,
      curve: Curves.easeInOut
    ).fadeIn(
      duration: 0.5.seconds,
      curve: Curves.easeInOut
    );
  }
  
  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, RoomModel room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Room'),
        content: Text('Are you sure you want to delete ${room.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final repository = ref.read(roomRepositoryProvider);
                await repository.removeRoom(room.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${room.name} has been deleted')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting room: $e')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
