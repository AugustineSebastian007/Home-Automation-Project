import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/features/devices/presentation/widgets/device_row_item.dart';
import 'package:home_automation/features/shared/widgets/warning_message.dart';
import 'package:home_automation/styles/styles.dart';
import 'dart:async';
import 'package:home_automation/features/devices/data/models/device.model.dart';

class DevicesList extends ConsumerStatefulWidget {
  const DevicesList({super.key});

  @override
  ConsumerState<DevicesList> createState() => _DevicesListState();
}

class _DevicesListState extends ConsumerState<DevicesList> {
  Timer? _debounce;

  void _onTapDevice(DeviceModel device) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(deviceListVMProvider.notifier).showDeviceDetails(device);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devicesList = ref.watch(deviceListVMProvider);
    
    return devicesList.isNotEmpty 
      ? ListView.builder(
          itemCount: devicesList.length,
          padding: HomeAutomationStyles.mediumPadding,
          itemBuilder: (context, index) {
            final device = devicesList[index];
            return GestureDetector(
              onTap: () => _onTapDevice(device),
              child: DeviceRowItem(
                device: device, 
                onTapDevice: _onTapDevice,
                onToggle: (bool value) {
                  ref.read(deviceRepositoryProvider).updateDevice(
                    device.roomId,
                    device.outletId,
                    device.copyWith(isSelected: value),
                  );
                },
              ).animate(
                delay: (index * 0.125).seconds,
              ).slideY(
                begin: 0.5, end: 0,
                duration: 0.5.seconds,
                curve: Curves.easeInOut
              ).fadeIn(
                duration: 0.5.seconds,
                curve: Curves.easeInOut
              ),
            );
          },
        ) 
      : const Center(
          child: WarningMessage(message: "No available devices"),
        );
  }
}