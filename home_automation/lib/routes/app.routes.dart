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
import 'package:home_automation/features/rooms/presentation/pages/rooms.page.dart';
import 'package:home_automation/features/rooms/presentation/pages/add_room.page.dart';
import 'package:home_automation/features/rooms/presentation/pages/room_details.page.dart' as details;
import 'package:home_automation/features/settings/presentation/pages/settings.page.dart';
import 'package:home_automation/helpers/utils.dart';

class AppRoutes {
  static final router = GoRouter(
    routerNeglect: true,
    initialLocation: SplashPage.route,
    navigatorKey: Utils.mainNav,
    routes: [
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: SplashPage.route,
        builder: (context, state){
          return const SplashPage();
        }
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: LoadingPage.route,
        builder: (context, state){
          return const LoadingPage();
        }
      ),
      // GoRoute(
      //   parentNavigatorKey: Utils.mainNav,
      //   path: HomePage.route,
      //   builder: (context, state){
      //     return const HomePage();
      //   }
      // ),
      ShellRoute(
        navigatorKey: Utils.tabNav,
        builder: (context, state,child){
          return LandingPage(child:child);
        },
        routes: [
          GoRoute(
          parentNavigatorKey: Utils.tabNav,
          path: HomePage.route,
          pageBuilder: (context, state){
            return const NoTransitionPage(
              child: HomePage()
              );
            }
          ),
          GoRoute(
          parentNavigatorKey: Utils.tabNav,
          path: RoomsPage.route,
          pageBuilder: (context, state){
            return NoTransitionPage(
              child: RoomsPage()
              );
            }
          ),
          GoRoute(
          parentNavigatorKey: Utils.tabNav,
          path: SettingsPage.route,
          pageBuilder: (context, state){
            return const NoTransitionPage(
              child: SettingsPage()
              );
            }
          ),
          GoRoute(
          parentNavigatorKey: Utils.tabNav,
          path: DevicesPage.route,
          pageBuilder: (context, state){
            return const NoTransitionPage(
              child: DevicesPage()
              );
            }
          ),
        ]
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: SigninPage.route,
        builder: (context, state){
          return  SigninPage(onTap: () {  },);
        }
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: LoginPage.route,
        builder: (context, state){
          return  LoginPage(onTap: () {  },);
        }
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: AuthPage.route,
        builder: (context, state){
          return  AuthPage();
        }
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: DeviceDetailsPage.route,
        builder: (context, state) {
          return const DeviceDetailsPage();
        },
      ),
      GoRoute(
        parentNavigatorKey: Utils.mainNav,
        path: AddRoomPage.route,
        builder: (context, state) {
          return AddRoomPage();
        },
      ),
      GoRoute(
        path: details.RoomDetailsPage.route,
        builder: (context, state) => details.RoomDetailsPage(roomId: state.pathParameters['id']!),
      ),
    ]
  );
}