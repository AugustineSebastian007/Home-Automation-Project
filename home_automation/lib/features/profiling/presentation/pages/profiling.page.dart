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
import 'package:home_automation/helpers/utils.dart';
import 'package:home_automation/features/profiling/presentation/widgets/add_profile_sheet.dart';
import 'package:home_automation/features/profiling/presentation/providers/add_profile_providers.dart';

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
                data: (profiles) => _buildProfileList(context, ref, profiles),
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
            const AddProfileSheet(),
            onDismissed: () {
              ref.read(saveAddProfileProvider.notifier).resetValues();
            }
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildProfileList(BuildContext context, WidgetRef ref, List<ProfileModel> profiles) {
    return ListView.builder(
      itemCount: profiles.length,
      padding: HomeAutomationStyles.mediumPadding,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return _buildProfileTile(context, ref, profile, index)
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

  Widget _buildProfileTile(BuildContext context, WidgetRef ref, ProfileModel profile, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: HomeAutomationStyles.smallSize),
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
        color: colorScheme.secondary.withOpacity(0.15),
        child: InkWell(
          onTap: () => context.push('/profile-details/${profile.id}/${profile.memberId}'),
          splashColor: colorScheme.secondary.withOpacity(0.25),
          highlightColor: colorScheme.secondary.withOpacity(0.25),
          child: Padding(
            padding: HomeAutomationStyles.mediumPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Material(
                    color: colorScheme.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
                    child: InkWell(
                      onTap: () => _showDeleteConfirmation(context, ref, profile),
                      borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
                      splashColor: colorScheme.error.withOpacity(0.2),
                      highlightColor: colorScheme.error.withOpacity(0.1),
                      child: Icon(
                        Icons.delete_rounded,
                        color: colorScheme.error,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: Switch(
                    value: profile.isActive,
                    onChanged: (value) async {
                      try {
                        await ref.read(profileRepositoryProvider)
                            .toggleAllDevicesInProfile(profile.memberId, profile.id, value, ref);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to toggle profile: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    activeColor: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, ProfileModel profile) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.delete_rounded,
              color: colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              'Delete Profile',
              style: TextStyle(
                color: colorScheme.error,
              ),
            ),
          ],
        ),
        content: Text('Are you sure you want to delete "${profile.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Deleting profile...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
                
                // Delete the profile
                await ref.read(profileRepositoryProvider).deleteProfile(profile.memberId, profile.id);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile "${profile.name}" deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete profile: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}