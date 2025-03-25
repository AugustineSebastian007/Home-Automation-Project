import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/household/data/models/household_member.model.dart';
import 'package:home_automation/features/household/presentation/providers/household_providers.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:camera/camera.dart';
import 'package:home_automation/features/household/presentation/widgets/add_member_dialog.dart';
import 'package:home_automation/features/profiling/presentation/providers/profile_providers.dart';

class HouseholdMembersSection extends ConsumerWidget {
  const HouseholdMembersSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(householdMembersProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, color: colorScheme.primary),
            HomeAutomationStyles.smallHGap,
            Text(
              'Household Members',
              style: textTheme.titleMedium!.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        HomeAutomationStyles.smallVGap,
        membersAsync.when(
          data: (members) => Column(
            children: [
              ...members.map((member) => _buildMemberTile(context, member, ref)),
              _buildAddMemberTile(context, ref),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        ),
      ],
    );
  }

  Widget _buildMemberTile(BuildContext context, HouseholdMemberModel member, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    final tileColor = brightness == Brightness.dark
        ? Color.fromARGB(255, 49, 49, 49)
        : Colors.grey[200];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(Icons.person, color: colorScheme.primary),
        title: Text(
          member.name,
          style: textTheme.bodyLarge!.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: member.profileId != null
            ? Text(
                'Linked to profile',
                style: textTheme.bodySmall!.copyWith(
                  color: colorScheme.secondary,
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: colorScheme.secondary,
          size: HomeAutomationStyles.smallIconSize,
        ),
        onTap: () => _showMemberOptions(context, member, ref),
      ),
    );
  }

  Widget _buildAddMemberTile(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    final tileColor = brightness == Brightness.dark
        ? Color.fromARGB(255, 49, 49, 49)
        : Colors.grey[200];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(Icons.person_add, color: colorScheme.primary),
        title: Text(
          'Add New Member',
          style: textTheme.bodyLarge!.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: colorScheme.secondary,
          size: HomeAutomationStyles.smallIconSize,
        ),
        onTap: () => _showAddMemberDialog(context, ref),
      ),
    );
  }

  Future<void> _showMemberOptions(BuildContext context, HouseholdMemberModel member, WidgetRef ref) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.link),
              title: Text(member.profileId != null ? 'Change Profile' : 'Link to Profile'),
              onTap: () {
                Navigator.pop(context);
                _showProfileSelectionDialog(context, ref, member);
              },
            ),
            if (member.profileId != null)
              ListTile(
                leading: Icon(Icons.link_off),
                title: Text('Unlink from Profile'),
                onTap: () async {
                  try {
                    Navigator.pop(context);
                    await ref.read(householdMemberRepositoryProvider)
                        .unlinkMemberFromProfile(member.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Profile unlinked successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error unlinking profile: $e')),
                    );
                  }
                },
              ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Remove Member', style: TextStyle(color: Colors.red)),
              onTap: () async {
                try {
                  Navigator.pop(context);
                  await ref.read(householdMemberRepositoryProvider).deleteMember(member.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Member removed successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error removing member: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProfileSelectionDialog(BuildContext context, WidgetRef ref, HouseholdMemberModel member) async {
    final profilesAsync = ref.watch(profileListProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Profile'),
        content: profilesAsync.when(
          data: (profiles) {
            if (profiles.isEmpty) {
              return Text('No profiles available. Create a profile first.');
            }
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: profiles.length,
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  return ListTile(
                    title: Text(profile.name),
                    selected: member.profileId == profile.id,
                    onTap: () async {
                      try {
                        Navigator.pop(context);
                        await ref.read(householdMemberRepositoryProvider)
                            .linkMemberToProfile(member.id, profile.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Profile linked successfully')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error linking profile: $e')),
                        );
                      }
                    },
                  );
                },
              ),
            );
          },
          loading: () => Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error loading profiles: $error'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMemberDialog(BuildContext context, WidgetRef ref) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => AddMemberDialog(controller: controller),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}