import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/shared/widgets/warning_message.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/rooms/presentation/widgets/room_tile.dart';
import 'package:home_automation/features/rooms/data/models/room.model.dart';

class RoomsList extends StatelessWidget {
  final List<RoomModel> rooms;

  const RoomsList({super.key, required this.rooms});

  @override
  Widget build(BuildContext context) {
    final List<Widget> roomWidgets = [
      ...rooms.map((room) => _buildRoomTile(context, room)),
      _buildDummyRoomTile(context),
    ];

    return roomWidgets.isNotEmpty
      ? ListView(
          padding: HomeAutomationStyles.mediumPadding,
          children: roomWidgets,
        )
      : const WarningMessage(message: "No available rooms");
  }

  Widget _buildRoomTile(BuildContext context, RoomModel room) {
    return RoomTile(
      room: room,
      onTap: () => context.push('/room-details/${room.id}'),
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
      room: RoomModel(id: 'dummy', name: 'Dummy Main Hall', deviceCount: 5),
      onTap: () => context.push('/dummy-main-hall'),
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
}
