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
      isMobile(context) ? 16.0 : 24.0;
      
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
}
