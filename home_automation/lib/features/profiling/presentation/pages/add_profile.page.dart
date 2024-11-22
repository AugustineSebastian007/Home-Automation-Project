import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/profiling/data/models/profile.model.dart';
import 'package:home_automation/features/profiling/presentation/providers/profile_providers.dart';
import 'package:home_automation/styles/styles.dart';

class AddProfilePage extends ConsumerWidget {
  static const String route = '/add-profile';

  AddProfilePage({Key? key}) : super(key: key);

  final TextEditingController _profileNameController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Add New Profile')),
      body: Padding(
        padding: HomeAutomationStyles.largePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _profileNameController,
              decoration: InputDecoration(
                labelText: 'Profile Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final profileName = _profileNameController.text.trim();
                if (profileName.isNotEmpty) {
                  final newProfile = ProfileModel(
                    id: DateTime.now().toString(),
                    name: profileName,
                    deviceIds: [],
                  );
                  ref.read(profileRepositoryProvider).addProfile(newProfile);
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