import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/presentation/responsiveness/device_details_responsive.config.dart';
import 'package:home_automation/features/devices/presentation/widgets/device_details_panel.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/devices/presentation/widgets/devices_list.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/presentation/pages/device_details.page.dart';
import 'package:home_automation/helpers/utils.dart';

class DevicesPage extends ConsumerStatefulWidget {
  static const String route = '/devices';

  const DevicesPage({super.key});

  @override
  ConsumerState<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends ConsumerState<DevicesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceListVMProvider.notifier).fetchDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = DeviceDetailsResponsiveConfig.deviceDetailsConfig(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MainPageHeader(
          icon: FlickyAnimatedIcons(
            icon: FlickyAnimatedIconOptions.bardevices,
            size: FlickyAnimatedIconSizes.large,
            isSelected: true,
          ),
          title: 'My Devices',
        ),
        Visibility(
          visible: config.showSingleLayout,
          replacement: Builder(
            builder: (context) {
              final selectedDevice = ref.watch(selectedDeviceProvider);
              return Expanded(
                child: Padding(
                  padding: HomeAutomationStyles.mediumPadding,
                  child: Row(
                    children: [
                      const Expanded(child: DevicesList()),
                      Expanded(
                        child: selectedDevice != null
                          ? DeviceDetailsPanel(device: selectedDevice)
                          : const Center(child: Text('No device selected')),
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
          child: const Expanded(
            child: DevicesList()
          ),
        ),
      ],
    );
  }
}