import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/features/household/presentation/widgets/household_members_section.dart';

class HouseholdMembersPage extends ConsumerWidget {
  static const String route = '/household-members';

  const HouseholdMembersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              title: 'Household Members',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: HouseholdMembersSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}