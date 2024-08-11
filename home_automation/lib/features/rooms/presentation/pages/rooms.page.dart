import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/rooms/presentation/widgets/rooms_list.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:go_router/go_router.dart';

class RoomsPage extends ConsumerWidget {
  static const String route = '/rooms';

  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
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
          const Expanded(
            child: RoomsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-room'),
        child: const Icon(Icons.add),
      ),
    );
  }
}