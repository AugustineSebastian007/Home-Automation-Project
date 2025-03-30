import 'package:go_router/go_router.dart';
import 'package:home_automation/features/devices/presentation/pages/device_details.page.dart';
import 'package:home_automation/features/devices/presentation/pages/devices.page.dart';
import 'package:home_automation/features/intro/presentation/pages/loading.pages.dart';
import 'package:home_automation/features/intro/presentation/pages/splash.pages.dart';
import 'package:home_automation/features/landing/presentation/pages/auth_page.dart';
import 'package:home_automation/features/landing/presentation/pages/home.page.dart';
import 'package:home_automation/features/landing/presentation/pages/landing.page.dart';
import 'package:home_automation/features/landing/presentation/pages/login.page.dart';
import 'package:home_automation/features/landing/presentation/pages/signin.page.dart';
import 'package:home_automation/features/outlets/presentation/pages/remove_outlet.page.dart';
import 'package:home_automation/features/rooms/presentation/pages/remove_room.page.dart';
import 'package:home_automation/features/rooms/presentation/pages/rooms.page.dart';
import 'package:home_automation/features/rooms/presentation/pages/room_details.page.dart' as details;
import 'package:home_automation/features/settings/presentation/pages/settings.page.dart';
import 'package:home_automation/helpers/utils.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/outlets/presentation/pages/add_outlet_page.dart';
import 'package:home_automation/features/profiling/presentation/pages/profiling.page.dart';
import 'package:home_automation/features/profiling/presentation/pages/add_profile.page.dart';
import 'package:home_automation/features/profiling/presentation/pages/profile_details.page.dart';
import 'package:home_automation/features/energy/presentation/pages/energy_saving.page.dart';

import '../features/rooms/presentation/pages/dummy_main_hall.page.dart';
import '../features/camera/presentation/pages/camera_footage.page.dart';
import '../features/camera/presentation/pages/single_camera.page.dart';
import '../features/household/presentation/pages/household_members.page.dart';

class AppRoutes {
  static final router = GoRouter(
    routerNeglect: true,
    initialLocation: SplashPage.route,
    navigatorKey: Utils.mainNav,
    routes: [
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: SplashPage.route,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: LoadingPage.route,
        builder: (context, state) => const LoadingPage(),
      ),
      ShellRoute(
        navigatorKey: Utils.tabNav,
        builder: (context, state, child) => LandingPage(child: child),
        routes: [
          GoRoute(
            path: HomePage.route,
            pageBuilder: (context, state) => const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: RoomsPage.route,
            pageBuilder: (context, state) => const NoTransitionPage(child: RoomsPage()),
          ),
          GoRoute(
            path: SettingsPage.route,
            pageBuilder: (context, state) => const NoTransitionPage(child: SettingsPage()),
          ),
          GoRoute(
            path: ProfilingPage.route,
            pageBuilder: (context, state) => const NoTransitionPage(child: ProfilingPage()),
          ),
          GoRoute(
            path: CameraFootagePage.route,
            pageBuilder: (context, state) => const NoTransitionPage(child: CameraFootagePage()),
          ),
          GoRoute(
            path: '/single-camera',
            pageBuilder: (context, state) {
              final args = state.extra as Map<String, dynamic>;
              return NoTransitionPage(
                child: SingleCameraPage(
                  label: args['label'] as String,
                  url: args['url'] as String,
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: DevicesPage.route,
        name: 'devices',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          final outletId = state.pathParameters['outletId'] ?? '';
          return DevicesPage(roomId: roomId, outletId: outletId);
        },
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: SigninPage.route,
        builder: (context, state) => SigninPage(onTap: () {}),
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: LoginPage.route,
        builder: (context, state) => LoginPage(onTap: () {}),
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: AuthPage.route,
        builder: (context, state) => AuthPage(),
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: details.RoomDetailsPage.route,
        builder: (context, state) => details.RoomDetailsPage(roomId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: DeviceDetailsPage.route,
        builder: (context, state) => DeviceDetailsPage(
          roomId: state.pathParameters['roomId']!,
          outletId: state.pathParameters['outletId']!,
          device: state.extra as DeviceModel,
        ),
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        name: 'remove-outlet',
        path: '/remove-outlet/:roomId',
        builder: (context, state) => RemoveOutletPage(roomId: state.pathParameters['roomId']!),
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        name: 'remove-room',
        path: '/remove-room',
        builder: (context, state) => RemoveRoomPage(),
      ),
      GoRoute(
        path: ProfileDetailsPage.route,
        builder: (context, state) => ProfileDetailsPage(
          profileId: state.pathParameters['id']!,
          memberId: state.pathParameters['memberId']!,
        ),
      ),
      GoRoute(
        path: '/dummy-main-hall',
        builder: (context, state) => DummyMainHallPage(),
      ),
      GoRoute(
        path: '/energy-saving',
        builder: (context, state) => const EnergySavingPage(),
      ),
      GoRoute(
        path: HouseholdMembersPage.route,
        builder: (context, state) => const HouseholdMembersPage(),
      ),
    ],
  );
}