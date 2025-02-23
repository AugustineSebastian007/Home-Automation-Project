import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/profiling/presentation/providers/profile_providers.dart';
import 'package:home_automation/features/profiling/data/models/profile.model.dart';
import 'package:go_router/go_router.dart';

class ProfilingPage extends ConsumerWidget {
  static const String route = '/profiling';

  const ProfilingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsyncValue = ref.watch(profileListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MainPageHeader(
              icon: FlickyAnimatedIcons(
                icon: FlickyAnimatedIconOptions.lightbulb,
                size: FlickyAnimatedIconSizes.large,
                isSelected: true,
              ),
              title: 'My Profiles',
            ),
            Expanded(
              child: profilesAsyncValue.when(
                data: (profiles) => _buildProfileList(context, profiles),
                loading: () => Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-profile'),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildProfileList(BuildContext context, List<ProfileModel> profiles) {
    return ListView.builder(
      itemCount: profiles.length,
      padding: HomeAutomationStyles.mediumPadding,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return _buildProfileTile(context, profile, index)
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
    );
  }

  Widget _buildProfileTile(BuildContext context, ProfileModel profile, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: HomeAutomationStyles.smallSize),
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
        color: colorScheme.secondary.withOpacity(0.15),
        child: InkWell(
          onTap: () => context.push('/profile-details/${profile.id}'),
          splashColor: colorScheme.secondary.withOpacity(0.25),
          highlightColor: colorScheme.secondary.withOpacity(0.25),
          child: Padding(
            padding: HomeAutomationStyles.mediumPadding,
            child: Row(
              children: [
                FlickyAnimatedIcons(
                  icon: FlickyAnimatedIconOptions.lightbulb,
                  isSelected: profile.isActive,
                ),
                HomeAutomationStyles.smallHGap,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: textTheme.labelMedium!.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${profile.deviceIds.length} Devices',
                        style: textTheme.bodySmall!.copyWith(
                          color: colorScheme.secondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: profile.isActive,
                  onChanged: (value) {
                    // TODO: Implement profile activation
                  },
                  activeColor: colorScheme.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}