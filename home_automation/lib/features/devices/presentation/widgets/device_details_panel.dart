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

    final deviceData = device;

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
            effects: [
              SlideEffect(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
                duration: 0.5.seconds,
                curve: Curves.easeInOut,
              ),
              FadeEffect(
                begin: 0,
                end: 1,
                duration: 0.5.seconds,
                curve: Curves.easeInOut,
              ),
            ],
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final selectionColor = deviceData.isSelected ? colorScheme.primary : colorScheme.secondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        HomeAutomationStyles.mediumVGap,
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
                              color: selectionColor.withOpacity(0.125)
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FlickyAnimatedIcons(
                                    key: ValueKey(deviceData.iconOption),
                                    icon: deviceData.iconOption,
                                    size: FlickyAnimatedIconSizes.x2large,
                                    isSelected: deviceData.isSelected,
                                  ),
                                  Text(deviceData.label,
                                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                                      color: selectionColor
                                    )
                                  ),
                                  HomeAutomationStyles.mediumVGap,
                                  isDeviceSaving
                                    ? const CircularProgressIndicator()
                                    : GestureDetector(
                                        onTap: () async {
                                          await ref.read(deviceToggleVMProvider.notifier).toggleDevice(deviceData);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Text(
                                                    'Device toggled',
                                                    style: TextStyle(fontSize: 16),
                                                  ),
                                                ),
                                                duration: Duration(seconds: 2),
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                margin: EdgeInsets.all(16),
                                                animation: CurvedAnimation(
                                                  parent: AnimationController(
                                                    vsync: ScaffoldMessenger.of(context),
                                                    duration: Duration(milliseconds: 300),
                                                  )..forward(),
                                                  curve: Curves.easeOutCubic,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: Icon(
                                          deviceData.isSelected ? Icons.toggle_on : Icons.toggle_off,
                                          color: selectionColor,
                                          size: HomeAutomationStyles.x2largeIconSize,
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  HomeAutomationStyles.mediumVGap,
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: !deviceData.isSelected && !isDeviceSaving
                          ? () async {
                              await ref.read(deviceListVMProvider.notifier).removeDevice(deviceData);
                            }
                          : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Remove This Device')
                      ),
                    ),
                  )
                ],
              ).animate(
                effects: [
                  SlideEffect(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                    duration: 0.5.seconds,
                    curve: Curves.easeInOut,
                  ),
                  FadeEffect(
                    begin: 0,
                    end: 1,
                    duration: 0.5.seconds,
                    curve: Curves.easeInOut,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}