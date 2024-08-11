import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/rooms/presentation/providers/room_providers.dart';
import 'package:home_automation/features/shared/widgets/warning_message.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/rooms/presentation/widgets/room_tile.dart';
import 'package:home_automation/features/rooms/data/models/room.model.dart';

class RoomsList extends StatelessWidget {
  final List<RoomModel> rooms;

  const RoomsList({super.key, required this.rooms});

  @override
  Widget build(BuildContext context) {
    return rooms.isNotEmpty 
      ? ListView.builder(
          itemCount: rooms.length,
          padding: HomeAutomationStyles.mediumPadding,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return RoomTile(
              room: room,
              onTap: () => context.push('/room-details/${room.id}'),
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
  }
}