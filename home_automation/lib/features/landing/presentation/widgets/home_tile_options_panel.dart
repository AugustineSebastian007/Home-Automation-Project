import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/landing/presentation/providers/landing_providers.dart';
import 'package:home_automation/features/landing/presentation/widgets/home_page_tile.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:go_router/go_router.dart';

class HomeTileOptionsPanel extends ConsumerWidget {
  const HomeTileOptionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final homeTiles = ref.watch(homeTileOptionsVMProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: HomeAutomationStyles.mediumSize),
            child: Row(
              children: [
                Icon(Icons.grid_view_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                HomeAutomationStyles.xsmallHGap,
                Text('Quick Actions',
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  )
                )
              ],
            ),
          ).animate(
            delay: 200.ms,
          )
          .slideX(
            begin: 0.25, end: 0,
            duration: 0.5.seconds,
            curve: Curves.easeInOut
          ).fadeIn(
            duration: 0.5.seconds,
            curve: Curves.easeInOut
          ),
          HomeAutomationStyles.xsmallVGap,
          SizedBox(
            height: 150,
            child: ListView(
              padding: const EdgeInsets.only(left: HomeAutomationStyles.mediumSize),
              scrollDirection: Axis.horizontal,
              children: [
                for(final tile in homeTiles)
                  if (tile.label != 'Test Connection')
                    HomePageTile(
                      tileOption: tile,
                      onTap: (selectedTile, context) {
                        if (selectedTile.label == 'Manage Devices') {
                          context.go('/rooms');
                        } else {
                          ref.read(homeTileOptionsVMProvider.notifier).onTileSelected(selectedTile);
                        }
                      },
                    )
              ].animate(
                interval: 200.ms
              ).scaleXY(
                begin: 0.5, end: 1,
                duration: 0.5.seconds,
                curve: Curves.easeInOut
              ).fadeIn(
                duration: 0.5.seconds,
                curve: Curves.easeInOut
              ),
            ),
          ),
        ],
      ),
    );
  }
}