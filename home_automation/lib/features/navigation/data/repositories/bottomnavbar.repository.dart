import 'package:home_automation/features/landing/presentation/pages/home.page.dart';
import 'package:home_automation/features/navigation/data/models/bottom_bar_nav_item.dart';
import 'package:home_automation/features/rooms/presentation/pages/rooms.page.dart';
import 'package:home_automation/features/settings/presentation/pages/settings.page.dart';
import 'package:home_automation/features/profiling/presentation/pages/profiling.page.dart';
import 'package:home_automation/helpers/enums.dart';

class BottomNavBarRepository {

  List<BottomBarNavItemModel> getBottomBarNavItems() {
    return const [
      BottomBarNavItemModel(
        iconOption: FlickyAnimatedIconOptions.barhome,
        route: HomePage.route,
        isSelected: true
      ),
      BottomBarNavItemModel(
        iconOption: FlickyAnimatedIconOptions.barrooms,
        route: RoomsPage.route
      ),
      BottomBarNavItemModel(
        iconOption: FlickyAnimatedIconOptions.bardevices, // Using an existing icon
        route: ProfilingPage.route
      ),
      BottomBarNavItemModel(
        iconOption: FlickyAnimatedIconOptions.barsettings,
        route: SettingsPage.route
      )
    ];
  }
}