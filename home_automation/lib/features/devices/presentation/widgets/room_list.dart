import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/rooms/presentation/providers/room_providers.dart';
import 'package:go_router/go_router.dart';

class RoomList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRoomsAsyncValue = ref.watch(userRoomsProvider);

    return SizedBox(
      height: 50, // Adjust this value as needed
      child: userRoomsAsyncValue.when(
        data: (rooms) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => context.push('/room-details/${room.id}'),
                  child: Chip(
                    label: Text(room.name),
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading rooms: $error')),
      ),
    );
  }
}