import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:home_automation/features/landing/presentation/responsiveness/landing_page_responsive.config.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePageHeader extends StatelessWidget {
  const HomePageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final config = LandingPageResponsiveConfig.landingPageConfig(context);
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

    return Padding(
      padding: HomeAutomationStyles.mediumPadding.copyWith(
        bottom: 0,
        left: HomeAutomationStyles.mediumSize,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (config.showBoltOnHeader)
            const FlickyAnimatedIcons(
              icon: FlickyAnimatedIconOptions.bolt,
              isSelected: true,
              size: FlickyAnimatedIconSizes.large,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome,',
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: Theme.of(context).colorScheme.secondary
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ].animate(
                interval: 300.ms
              ).slideX(
                begin: 0.5, end: 0,
                duration: 0.5.seconds,
                curve: Curves.easeInOut,
              ).fadeIn(
                duration: 0.5.seconds,
                curve: Curves.easeInOut,
              ),
            ),
          ),
        ],
      ),
    );
  }
}