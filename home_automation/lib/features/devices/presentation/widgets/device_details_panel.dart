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

    print("Device data in DeviceDetailsPanel: ${device.toJson()}");

    if (device.id.isEmpty || device.id == 'error' || device.id == 'not_found') {
      print("Warning: Invalid device data in DeviceDetailsPanel");
      return Center(
        child: Text("Error: Invalid device data. Please try reloading the device list.",
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final selectionColor = device.isSelected ? colorScheme.primary : colorScheme.secondary;

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
                              key: ValueKey(device.iconOption),
                              icon: device.iconOption,
                              size: FlickyAnimatedIconSizes.x2large,
                              isSelected: device.isSelected,
                            ),
                            Text(device.label,
                              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                                color: selectionColor
                              )
                            ),
                            HomeAutomationStyles.mediumVGap,
                            isDeviceSaving
                              ? const CircularProgressIndicator()
                              : GestureDetector(
                                  onTap: () async {
                                    try {
                                      await ref.read(deviceToggleVMProvider.notifier).toggleDevice(device);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Device toggled successfully'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error toggling device: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Icon(
                                    device.isSelected ? Icons.toggle_on : Icons.toggle_off,
                                    color: selectionColor,
                                    size: HomeAutomationStyles.x2largeIconSize,
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  HomeAutomationStyles.mediumVGap,
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: !device.isSelected && !isDeviceSaving
                          ? () async {
                              await ref.read(deviceListVMProvider.notifier).removeDevice(device);
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
              ),
            ),
          ),
        );
      }
    );
  }
}