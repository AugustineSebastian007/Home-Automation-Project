import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/navigation/presentation/providers/navigation_providers.dart';
import 'package:home_automation/styles/styles.dart';

class HomeAutomationBottomBar extends ConsumerWidget {
  const HomeAutomationBottomBar({super.key});

  @override
  Widget build(BuildContext context , WidgetRef ref) {

    final barItems = ref.watch(bottomBarVMProvider);

    return Container(
      padding: HomeAutomationStyles.xsmallPadding,
      child: Flex(
        direction: Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: barItems.map((e) {
          return Container(
            margin: const EdgeInsets.only(bottom: HomeAutomationStyles.smallSize),
            child: IconButton(
              onPressed: (){},
              icon: Icon(e.iconOption),
            )
          );
        }).toList()
         .animate(
          interval: 200.ms
        ).slideY(
          begin: 1, end: 0,
          duration: 0.5.seconds,
          curve: Curves.easeInOut
        ),
      ),
    );

  }
}