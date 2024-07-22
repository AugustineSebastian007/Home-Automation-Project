import 'package:flutter/material.dart';
import 'package:home_automation/features/navigation/presentation/widgets/home_automation_bottom_bar.dart';

class LandingPage extends StatelessWidget {

  final Widget child;
  const LandingPage({
    required this.child,
    super.key
    });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Flex(
        direction: Axis.vertical,
        children: [
          Expanded(
            child: child,
          ),
          const HomeAutomationBottomBar()
        ],
        )
    );
  }
}