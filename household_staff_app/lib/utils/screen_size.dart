import 'package:flutter/material.dart';

class ScreenSize {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double getPadding(BuildContext context) =>
      isMobile(context) ? 12.0 : 16.0;
      
  static EdgeInsets getScreenPadding(BuildContext context) =>
      EdgeInsets.all(getPadding(context));
      
  static int getGridCrossAxisCount(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }
  
  static double getGridChildAspectRatio(BuildContext context) {
    if (isDesktop(context)) return 1.8;
    if (isTablet(context)) return 1.5;
    return 1.2;
  }
  
  // New responsive utilities
  static double getResponsiveFontSize(BuildContext context, {
    double mobile = 14.0,
    double tablet = 16.0,
    double desktop = 18.0,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
  
  static double getResponsiveIconSize(BuildContext context, {
    double mobile = 20.0,
    double tablet = 24.0,
    double desktop = 28.0,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
  
  static EdgeInsets getResponsivePadding(BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    mobile ??= const EdgeInsets.all(12.0);
    tablet ??= const EdgeInsets.all(16.0);
    desktop ??= const EdgeInsets.all(20.0);
    
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
  
  static double getResponsiveSpacing(BuildContext context, {
    double mobile = 8.0,
    double tablet = 12.0,
    double desktop = 16.0,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}
