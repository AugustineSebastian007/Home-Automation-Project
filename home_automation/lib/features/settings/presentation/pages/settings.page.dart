import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:home_automation/features/household/presentation/widgets/household_members_section.dart';

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class SettingsPage extends ConsumerWidget {
  static const String route = '/settings';

  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'No email found';
    final userName = user?.displayName ?? 'No name set';
    
    String getThemeString(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.light:
          return 'Light';
        case ThemeMode.dark:
          return 'Dark';
        case ThemeMode.system:
          return 'System Default';
      }
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MainPageHeader(
            icon: FlickyAnimatedIcons(
              icon: FlickyAnimatedIconOptions.barsettings,
              size: FlickyAnimatedIconSizes.large,
              isSelected: true,
            ),
            title: 'Settings',
          ),
          Expanded(
            child: ListView(
              padding: HomeAutomationStyles.mediumPadding,
              children: [
                _buildSettingsSection(
                  context,
                  'General',
                  Icons.settings,
                  [
                    _buildSettingsTile(context, 'Language', 'English', Icons.language),
                    _buildSettingsTile(
                      context, 
                      'Theme', 
                      getThemeString(currentTheme), 
                      Icons.palette,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Theme'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('Light'),
                                  leading: const Icon(Icons.light_mode),
                                  onTap: () {
                                    ref.read(themeProvider.notifier).state = ThemeMode.light;
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  title: const Text('Dark'),
                                  leading: const Icon(Icons.dark_mode),
                                  onTap: () {
                                    ref.read(themeProvider.notifier).state = ThemeMode.dark;
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  title: const Text('System Default'),
                                  leading: const Icon(Icons.settings_system_daydream),
                                  onTap: () {
                                    ref.read(themeProvider.notifier).state = ThemeMode.system;
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(context, 'Notifications', 'On', Icons.notifications),
                  ],
                ),
                HomeAutomationStyles.mediumVGap,
                _buildSettingsSection(
                  context,
                  'Account',
                  Icons.account_circle,
                  [
                    _buildSettingsTile(context, 'Profile', userName, Icons.person),
                    _buildSettingsTile(context, 'Email', userEmail, Icons.email),
                  ],
                ),
                HomeAutomationStyles.mediumVGap,
                HouseholdMembersSection(),
                HomeAutomationStyles.mediumVGap,
                _buildSettingsSection(
                  context,
                  'About',
                  Icons.info,
                  [
                    _buildSettingsTile(context, 'Version', '1.0.0', Icons.info_outline),
                    _buildSettingsTile(context, 'Terms of Service', '', Icons.description),
                    _buildSettingsTile(context, 'Privacy Policy', '', Icons.privacy_tip),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            HomeAutomationStyles.smallHGap,
            Text(
              title,
              style: textTheme.titleMedium!.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        HomeAutomationStyles.smallVGap,
        ...children,
      ],
    );
  }

  Widget _buildSettingsTile(BuildContext context, String title, String value, IconData icon, {VoidCallback? onTap}) {
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
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(
          title,
          style: textTheme.bodyLarge!.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: value.isNotEmpty
            ? Text(
                value,
                style: textTheme.bodyMedium!.copyWith(
                  color: colorScheme.secondary,
                ),
              )
            : Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.secondary,
                size: HomeAutomationStyles.smallIconSize,
              ),
        onTap: onTap ?? () {
          // Default empty implementation
        },
      ),
    );
  }
}