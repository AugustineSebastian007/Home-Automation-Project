import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';

class SettingsPage extends ConsumerWidget {
  static const String route = '/settings';

  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final colorScheme = Theme.of(context).colorScheme;
    // final textTheme = Theme.of(context).textTheme;

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
                    _buildSettingsTile(context, 'Theme', 'System Default', Icons.palette),
                    _buildSettingsTile(context, 'Notifications', 'On', Icons.notifications),
                  ],
                ),
                HomeAutomationStyles.mediumVGap,
                _buildSettingsSection(
                  context,
                  'Account',
                  Icons.account_circle,
                  [
                    _buildSettingsTile(context, 'Profile', 'Augustine', Icons.person),
                    _buildSettingsTile(context, 'Email', 'augustine@example.com', Icons.email),
                    _buildSettingsTile(context, 'Password', '********', Icons.lock),
                  ],
                ),
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

  Widget _buildSettingsTile(BuildContext context, String title, String value, IconData icon) {
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
        onTap: () {
          // TODO: Implement settings action
        },
      ),
    );
  }
}