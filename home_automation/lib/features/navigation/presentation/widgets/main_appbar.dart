import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/landing/presentation/pages/auth_page.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/helpers/utils.dart';
import 'package:home_automation/styles/styles.dart';

class HomeAutomationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final String? title;

  const HomeAutomationAppBar({
    Key? key,
    this.leading,
    this.title,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(HomeAutomationStyles.appBarSize);

  void signUserOut() {
    FirebaseAuth.instance.signOut();
    GoRouter.of(Utils.mainNav.currentContext!).go(AuthPage.route);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      iconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.secondary
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: leading,
      title: title != null 
        ? Text(title!)
        : const FlickyAnimatedIcons(
            icon: FlickyAnimatedIconOptions.flickybulb,
            isSelected: true,
          ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: signUserOut,
        ),
        HomeAutomationStyles.xsmallHGap
      ],
    );
  }
}