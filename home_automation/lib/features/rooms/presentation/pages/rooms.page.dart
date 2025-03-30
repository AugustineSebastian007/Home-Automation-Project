import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/rooms/presentation/providers/add_room_providers.dart';
import 'package:home_automation/features/rooms/presentation/providers/room_providers.dart';
import 'package:home_automation/features/rooms/presentation/widgets/add_room_sheet.dart';
import 'package:home_automation/features/rooms/presentation/widgets/rooms_list.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/helpers/utils.dart';

class RoomsPage extends ConsumerWidget {
  static const String route = '/rooms';

  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRoomsAsyncValue = ref.watch(userRoomsProvider);
    
    // Refresh device counts when the page builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refresh(updateAllRoomDeviceCountsProvider);
    });

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Utils.showUIModal(
            context,
            const AddRoomSheet(),
            onDismissed: () {
              ref.read(saveAddRoomProvider.notifier).resetAllValues();
            }
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
