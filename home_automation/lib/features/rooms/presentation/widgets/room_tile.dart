import 'package:flutter/material.dart';
import 'package:home_automation/features/rooms/data/models/room.model.dart';
import 'package:home_automation/styles/styles.dart';

class RoomTile extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;

  const RoomTile({
    Key? key,
    required this.room,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.secondary;
    final bgColor = selectedColor.withOpacity(0.15);
    final splashColor = selectedColor.withOpacity(0.25);

    return Container(
      margin: const EdgeInsets.only(bottom: HomeAutomationStyles.smallSize),
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
        color: bgColor,
        child: InkWell(
          onTap: onTap,
          splashColor: splashColor,
          highlightColor: splashColor,
          child: Padding(
            padding: HomeAutomationStyles.mediumPadding,
            child: Row(
              children: [
                Icon(
                  Icons.room,
                  color: selectedColor,
                  size: HomeAutomationStyles.mediumIconSize,
                ),
                HomeAutomationStyles.smallHGap,
                Expanded(
                  child: Text(
                    room.name,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: selectedColor
                    ),
                  ),
                ),
                Text(
                  '${room.deviceCount} Devices',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: selectedColor.withOpacity(0.7),
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