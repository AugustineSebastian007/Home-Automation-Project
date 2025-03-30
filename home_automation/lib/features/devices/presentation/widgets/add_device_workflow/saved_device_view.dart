import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:home_automation/styles/styles.dart';

class SavedDeviceView extends StatefulWidget {
  const SavedDeviceView({super.key});

  @override
  State<SavedDeviceView> createState() => _SavedDeviceViewState();
}

class _SavedDeviceViewState extends State<SavedDeviceView> {
  
  @override
  void initState() {
    super.initState();
    // Automatically close the sheet after a delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.5,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
              size: HomeAutomationStyles.xlargeIconSize,
              color: Theme.of(context).colorScheme.primary
            ),
            HomeAutomationStyles.smallVGap,
            Text('Saved Device',
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold
              )
            )
          ].animate(
            interval: 100.ms,
          ).slideY(
            begin: 0.5, end: 0,
            duration: 0.25.seconds,
            curve: Curves.easeInOut
          ).fadeIn(
            duration: 0.25.seconds,
            curve: Curves.easeInOut
          ),
        )
      ),
    );
  }
}