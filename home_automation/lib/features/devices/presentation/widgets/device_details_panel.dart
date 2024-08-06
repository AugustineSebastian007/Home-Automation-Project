import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';

class DeviceDetailsPanel extends ConsumerWidget {
  final DeviceModel device;

  const DeviceDetailsPanel({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeviceSaving = ref.watch(deviceToggleVMProvider);
    final deviceData = ref.watch(selectedDeviceProvider);

    print("Device data in DeviceDetailsPanel: ${deviceData?.toJson()}");

    if (deviceData == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt,
              size: HomeAutomationStyles.largeIconSize,
              color: Theme.of(context).colorScheme.secondary
            ),
            Text('Select device', style: Theme.of(context).textTheme.labelLarge!
              .copyWith(
                color: Theme.of(context).colorScheme.secondary
              )
            )
          ].animate(
            interval: 200.ms,
          ).slideY(
            begin: 0.5, end: 0,
            duration: 0.5.seconds,
            curve: Curves.easeInOut,
          ).fadeIn(
            duration: 0.5.seconds,
            curve: Curves.easeInOut,
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final selectionColor = device.isSelected ? colorScheme.primary : colorScheme.secondary;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: HomeAutomationStyles.mediumPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Device ID: ${device.id}'),
                  HomeAutomationStyles.smallVGap,
                  Text('Label: ${device.label}'),
                  HomeAutomationStyles.smallVGap,
                  Text('Outlet: ${device.outlet}'),
                  HomeAutomationStyles.smallVGap,
                  Text('Icon: ${device.iconOption.name}'),
                  HomeAutomationStyles.mediumVGap,
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
                      color: selectionColor.withOpacity(0.125)
                    ),
                    child: Center(
                      child: Padding(
                        padding: HomeAutomationStyles.smallPadding,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FlickyAnimatedIcons(
                                      key: ValueKey(device.iconOption),
                                      icon: device.iconOption,
                                      size: FlickyAnimatedIconSizes.x2large,
                                      isSelected: device.isSelected,
                                    ),
                                    Text(device.label,
                                      style: Theme.of(context).textTheme.headlineMedium!.
                                      copyWith(
                                        color: selectionColor
                                      )
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: isDeviceSaving ?
                                const Padding(
                                  padding: HomeAutomationStyles.largePadding,
                                  child: Center(
                                    child: SizedBox(
                                      width: HomeAutomationStyles.largeIconSize, 
                                      height: HomeAutomationStyles.largeIconSize,
                                      child: CircularProgressIndicator(
                                        strokeWidth: HomeAutomationStyles.smallSize,
                                      )
                                    ),
                                  ),
                                )
                              : 
                                GestureDetector(
                                  onTap: () {
                                    ref.read(deviceListVMProvider.notifier).toggleDevice(device);
                                  },
                                  child: Icon(
                                    device.isSelected ? Icons.toggle_on : 
                                    Icons.toggle_off,
                                    color: selectionColor,
                                    size: HomeAutomationStyles.x2largeIconSize,
                                  ),
                                ),
                            )
                          ].animate(
                            interval: 100.ms
                          ).slideY(
                            begin: 0.5, end: 0,
                            duration: 0.5.seconds,
                            curve: Curves.easeInOut,
                          ).fadeIn(
                            duration: 0.5.seconds,
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ),
                    ),
                  ),
                ].animate(
                  interval: 100.ms
                ).slideY(
                  begin: 0.5, end: 0,
                  duration: 0.5.seconds,
                  curve: Curves.easeInOut,
                ).fadeIn(
                  duration: 0.5.seconds,
                  curve: Curves.easeInOut,
                ),
              ),
            ),
          ),
        ),
        HomeAutomationStyles.mediumVGap,
        ElevatedButton(
          onPressed: !device.isSelected && !isDeviceSaving ? () {
            ref.read(deviceListVMProvider.notifier).removeDevice(device);
          } : null, 
          child: const Text('Remove This Device')
        )
      ],
    );
  }
}