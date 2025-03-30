import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/features/devices/presentation/widgets/device_tile.dart';
import 'package:home_automation/features/navigation/presentation/widgets/main_appbar.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/navigation/providers/navigation_providers.dart';
import 'package:home_automation/features/landing/presentation/responsiveness/landing_page_responsive.config.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:home_automation/features/landing/presentation/pages/home.page.dart';
import 'package:home_automation/features/rooms/presentation/pages/rooms.page.dart';
import 'package:home_automation/features/camera/presentation/pages/camera_footage.page.dart';
import 'package:home_automation/features/profiling/presentation/pages/profiling.page.dart';
import 'package:home_automation/features/settings/presentation/pages/settings.page.dart';

class DevicesPage extends ConsumerWidget {
  static const String route = '/devices/:roomId/:outletId';
  final String roomId;
  final String outletId;

  const DevicesPage({Key? key, required this.roomId, required this.outletId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsyncValue = ref.watch(deviceListStreamProvider((roomId: roomId, outletId: outletId)));
    final barItems = ref.watch(bottomBarVMProvider);
    final config = LandingPageResponsiveConfig.landingPageConfig(context);

    return Scaffold(
      appBar: HomeAutomationAppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/room-details/$roomId');
          },
        ),
        title: 'Devices',
      ),
      body: Column(
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
          Expanded(
            child: devicesAsyncValue.when(
              data: (devices) => ListView.builder(
                itemCount: devices.length,
                padding: HomeAutomationStyles.mediumPadding,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return DeviceTile(device: device);
                },
              ),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: HomeAutomationStyles.xsmallPadding,
        color: config.bottomBarBg,
        child: Flex(
          direction: config.bottomBarDirection,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: barItems.map((e) {
            return Container(
              margin: const EdgeInsets.only(bottom: HomeAutomationStyles.smallSize),
              child: IconButton(
                onPressed: () {
                  // Direct navigation using context instead of the tabNav
                  switch (e.route) {
                    case HomePage.route:
                      context.go(HomePage.route);
                      break;
                    case RoomsPage.route:
                      context.go(RoomsPage.route);
                      break;
                    case CameraFootagePage.route:
                      context.go(CameraFootagePage.route);
                      break;
                    case ProfilingPage.route:
                      context.go(ProfilingPage.route);
                      break;
                    case SettingsPage.route:
                      context.go(SettingsPage.route);
                      break;
                  }
                },
                icon: FlickyAnimatedIcons(
                  icon: e.iconOption,
                  isSelected: e.isSelected,
                )
              ),
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
      ),
    );
  }
}