import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/rooms/presentation/providers/room_providers.dart';
import 'package:home_automation/features/shared/widgets/warning_message.dart';
import 'package:home_automation/styles/styles.dart';

class RoomsList extends ConsumerWidget {
  const RoomsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsyncValue = ref.watch(roomListStreamProvider);
    
    return roomsAsyncValue.when(
      data: (rooms) {
        return rooms.isNotEmpty 
          ? ListView.builder(
              itemCount: rooms.length,
              padding: HomeAutomationStyles.mediumPadding,
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
                ).animate(
                  delay: (index * 0.125).seconds,
                ).slideY(
                  begin: 0.5, end: 0,
                  duration: 0.5.seconds,
                  curve: Curves.easeInOut
                ).fadeIn(
                  duration: 0.5.seconds,
                  curve: Curves.easeInOut
                );
              },
            )
          : const WarningMessage(message: "No available rooms");
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading rooms: $error')),
    );
  }
}
