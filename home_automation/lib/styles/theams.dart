import 'package:flutter/material.dart';
import 'package:home_automation/styles/colors.dart';
import 'package:home_automation/styles/styles.dart';


class HomeAutomationTheam {
  static ThemeData dark = ThemeData(
    canvasColor: Colors.transparent,
    fontFamily: 'Product Sans',
    scaffoldBackgroundColor: HomeAutomationColors.darkScaffoldBackground,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: HomeAutomationColors.darkSeedColor,
      primary: HomeAutomationColors.darkPrimary,
      secondary: HomeAutomationColors.darkSecondary,
      tertiary: HomeAutomationColors.darkTertiary,
      background: HomeAutomationColors.darkBackground,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: HomeAutomationColors.darkPrimary
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        elevation: 0,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.black,
        textStyle: HomeAutomationStyles.elevatedButtonTextStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: HomeAutomationStyles.smallSize,
          fontFamily: 'Product Sans',
        )
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: HomeAutomationStyles.headlineLarge,
      headlineMedium: HomeAutomationStyles.headlineMedium,
      labelLarge: HomeAutomationStyles.labelLarge,
      labelMedium: HomeAutomationStyles.labelMedium,
      displayMedium: HomeAutomationStyles.labelMedium.copyWith(
        color: Colors.white,
      )
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: HomeAutomationColors.darkSeedColor,
      surfaceTintColor: Colors.black,
    ),
    iconTheme: const IconThemeData(
      size: HomeAutomationStyles.mediumIconSize,
      color: HomeAutomationColors.darkSecondary
    ),
    snackBarTheme: SnackBarThemeData(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(
        topLeft: Radius.circular(HomeAutomationStyles.mediumRadius),
        topRight: Radius.circular(HomeAutomationStyles.mediumRadius),
      )),
      backgroundColor: HomeAutomationColors.darkPrimary,
      actionTextColor: Colors.black,
      closeIconColor: Colors.black,
      insetPadding: HomeAutomationStyles.smallPadding,
      contentTextStyle: HomeAutomationStyles.labelMedium.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    )
  );
    
  static ThemeData light = ThemeData(
    canvasColor: Colors.transparent,
    fontFamily: 'Product Sans',
    scaffoldBackgroundColor: HomeAutomationColors.lightScaffoldBackground,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: HomeAutomationColors.lightSeedColor,
      primary: HomeAutomationColors.lightPrimary,
      secondary: Color(0xFF707070),
      tertiary: Color(0xFFA0A0A0),
      background: const Color.fromARGB(228, 255, 255, 255),
      onSurface: Color(0xFF303030),
      onBackground: Color(0xFF303030),
      onSurfaceVariant: Color(0xFF202020),
      surface: Color(0xFFE0E0E0),
      surfaceVariant: Color(0xFFEEEEEE),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: HomeAutomationColors.lightPrimary
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        elevation: 0,
        foregroundColor: Colors.white,
        padding: HomeAutomationStyles.mediumPadding,
        shadowColor: Colors.transparent,
        textStyle: HomeAutomationStyles.elevatedButtonTextStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: HomeAutomationStyles.smallSize,
          fontFamily: 'Product Sans',
        )
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: HomeAutomationStyles.headlineLarge.copyWith(
        color: Color(0xFF202020),
      ),
      headlineMedium: HomeAutomationStyles.headlineMedium.copyWith(
        color: Color(0xFF202020),
      ),
      labelLarge: HomeAutomationStyles.labelLarge.copyWith(
        color: Color(0xFF303030),
      ),
      labelMedium: HomeAutomationStyles.labelMedium.copyWith(
        color: Color(0xFF303030),
      ),
      displayMedium: HomeAutomationStyles.labelMedium.copyWith(
        color: Color(0xFF202020),
      ),
      bodyLarge: TextStyle(
        color: Color(0xFF303030),
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Color(0xFF303030),
        fontSize: 14,
      ),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: HomeAutomationColors.lightSeedColor,
      surfaceTintColor: Colors.white,
    ),
    iconTheme: const IconThemeData(
      size: HomeAutomationStyles.mediumIconSize,
      color: Color(0xFF606060),
    ),
    snackBarTheme: SnackBarThemeData(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(
          topLeft: Radius.circular(HomeAutomationStyles.mediumRadius),
          topRight: Radius.circular(HomeAutomationStyles.mediumRadius),
        )),
        backgroundColor: HomeAutomationColors.lightPrimary,
        actionTextColor: Colors.white,
        closeIconColor: Colors.white,
        insetPadding: HomeAutomationStyles.smallPadding,
        contentTextStyle: HomeAutomationStyles.labelMedium
        .copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white),
      )
  );
}