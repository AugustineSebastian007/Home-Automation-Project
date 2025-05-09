import 'package:flutter/material.dart';
import 'package:home_automation/features/rooms/data/models/room.model.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';

class RoomTile extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const RoomTile({
    Key? key,
    required this.room,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.secondary;
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
          onTap: onTap,
          splashColor: splashColor,
          highlightColor: splashColor,
          child: Padding(
            padding: HomeAutomationStyles.mediumPadding,
            child: Row(
              children: [
                FlickyAnimatedIcons(
                  icon: FlickyAnimatedIconOptions.barrooms,
                  size: FlickyAnimatedIconSizes.small,
                  isSelected: false,
                ),
                HomeAutomationStyles.smallHGap,
                Expanded(
                  child: Text(
                    room.name,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: selectedColor,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ),
                if (onDelete != null) ...[
                  Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: colorScheme.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
                      child: InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
                        splashColor: colorScheme.error.withOpacity(0.2),
                        highlightColor: colorScheme.error.withOpacity(0.1),
                        child: Icon(
                          Icons.delete_rounded,
                          color: colorScheme.error,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
                Text(
                  '${room.deviceCount} ${room.deviceCount == 1 ? 'Device' : 'Devices'}',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: selectedColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: 14.0,
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