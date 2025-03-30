import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/styles/styles.dart';

class DeviceTile extends StatelessWidget {
  final DeviceModel device;

  const DeviceTile({Key? key, required this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedColor = device.isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;

    // Use dark gray color in dark mode for background, matching the RoomTile
    final bgColor = Theme.of(context).brightness == Brightness.dark 
        ? Color(0xFF2A2A2A) // Dark gray for dark mode
        : selectedColor.withOpacity(0.15); // Original color for light mode
    final splashColor = selectedColor.withOpacity(0.25);

    return Container(
      margin: const EdgeInsets.only(bottom: HomeAutomationStyles.smallSize),
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
        color: bgColor,
        child: InkWell(
          onTap: () {
            context.push('/device-details/${device.roomId}/${device.outletId}', extra: device);
          },
          splashColor: splashColor,
          highlightColor: splashColor,
          child: Padding(
            padding: HomeAutomationStyles.mediumPadding,
            child: Row(
              children: [
                FlickyAnimatedIcons(
                  icon: device.iconOption,
                  isSelected: device.isSelected,
                ),
                HomeAutomationStyles.smallHGap,
                Expanded(
                  child: Text(
                    device.label,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: selectedColor
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}