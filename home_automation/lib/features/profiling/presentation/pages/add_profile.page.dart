import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/profiling/data/models/profile.model.dart';
import 'package:home_automation/features/profiling/presentation/providers/profile_providers.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/household/presentation/providers/household_providers.dart';

class AddProfilePage extends ConsumerStatefulWidget {
  static const String route = '/add-profile';

  @override
  _AddProfilePageState createState() => _AddProfilePageState();
}

class _AddProfilePageState extends ConsumerState<AddProfilePage> {
  final TextEditingController _profileNameController = TextEditingController();
  String? selectedMemberId;

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(householdMembersProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Add New Profile')),
      body: Padding(
        padding: HomeAutomationStyles.largePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            membersAsync.when(
              data: (members) => DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Household Member',
                  border: OutlineInputBorder(),
                ),
                value: selectedMemberId,
                items: members.map((member) {
                  return DropdownMenuItem(
                    value: member.id,
                    child: Text(member.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMemberId = value;
                  });
                },
              ),
              loading: () => CircularProgressIndicator(),
              error: (error, _) => Text('Error: $error'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _profileNameController,
              decoration: InputDecoration(
                labelText: 'Profile Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedMemberId == null ? null : () {
                final profileName = _profileNameController.text.trim();
                if (profileName.isNotEmpty) {
                  final newProfile = ProfileModel(
                    id: DateTime.now().toString(),
                    name: profileName,
                    deviceIds: [],
                    memberId: selectedMemberId!,
                  );
                  ref.read(profileRepositoryProvider)
                     .addProfile(selectedMemberId!, newProfile);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                textStyle: textTheme.labelLarge,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}