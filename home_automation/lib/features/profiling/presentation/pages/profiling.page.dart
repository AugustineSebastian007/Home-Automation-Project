import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';

class ProfilingPage extends ConsumerWidget {
  static const String route = '/profiling';

  const ProfilingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = [
      ('Morning', 3),
      ('Evening', 2),
      ('Night', 4),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MainPageHeader(
              icon: FlickyAnimatedIcons(
                icon: FlickyAnimatedIconOptions.bardevices,
                size: FlickyAnimatedIconSizes.large,
                isSelected: true,
              ),
              title: 'My Profiles',
            ),
            Expanded(
              child: ListView.builder(
                itemCount: profiles.length,
                padding: HomeAutomationStyles.mediumPadding,
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  return _buildProfileTile(context, profile.$1, profile.$2, index)
                    .animate(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context, String name, int deviceCount, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = index == 0; // For demonstration, we'll select the first item

    final selectedColor = isSelected
        ? colorScheme.primary
        : colorScheme.secondary;

    final bgColor = selectedColor.withOpacity(0.15);
    final splashColor = selectedColor.withOpacity(0.25);

    return Container(
      margin: const EdgeInsets.only(bottom: HomeAutomationStyles.smallSize),
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
        color: bgColor,
        child: InkWell(
          onTap: () {
            // TODO: Implement profile selection
          },
          splashColor: splashColor,
          highlightColor: splashColor,
          child: Padding(
            padding: HomeAutomationStyles.mediumPadding,
            child: Row(
              children: [
                FlickyAnimatedIcons(
                  icon: FlickyAnimatedIconOptions.lightbulb,
                  isSelected: isSelected,
                ),
                HomeAutomationStyles.smallHGap,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: textTheme.labelMedium!.copyWith(
                          color: selectedColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$deviceCount Devices',
                        style: textTheme.bodySmall!.copyWith(
                          color: selectedColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: selectedColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}