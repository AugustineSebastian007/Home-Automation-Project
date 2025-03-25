import 'package:flutter/material.dart';
import 'package:home_automation/features/landing/presentation/responsiveness/landing_page_responsive.config.dart';
import 'package:home_automation/features/landing/presentation/widgets/energy_consumption_panel.dart';
import 'package:home_automation/features/landing/presentation/widgets/home_page_header.dart';
import 'package:home_automation/features/landing/presentation/widgets/home_tile_options_panel.dart';
import 'package:home_automation/styles/styles.dart';

class HomePage extends StatelessWidget {

  static const String route = '/home';
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final config = LandingPageResponsiveConfig.landingPageConfig(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Top content in scrollable area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HomePageHeader(),
                    HomeAutomationStyles.smallVGap,
                    const HomeTileOptionsPanel(),
                  ],
                ),
              ),
            ),
            // Energy panel that fills remaining space
            const Expanded(
              child: EnergyConsumptionPanel(),
            ),
          ],
        );
      },
    );
  }
}