import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < 600;
      
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= 600 && 
      MediaQuery.of(context).size.width < 900;
      
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= 900;
      
  static double getHeight(BuildContext context, double percentage) =>
      MediaQuery.of(context).size.height * percentage;
      
  static double getWidth(BuildContext context, double percentage) =>
      MediaQuery.of(context).size.width * percentage;
      
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return EdgeInsets.symmetric(
        horizontal: getWidth(context, 0.05),
        vertical: getHeight(context, 0.02),
      );
    } else if (isTablet(context)) {
      return EdgeInsets.symmetric(
        horizontal: getWidth(context, 0.1),
        vertical: getHeight(context, 0.03),
      );
    } else {
      // Center the content with max width on larger screens
      double sideMargin = (MediaQuery.of(context).size.width - 600) / 2;
      return EdgeInsets.symmetric(
        horizontal: sideMargin > 0 ? sideMargin : getWidth(context, 0.15),
        vertical: getHeight(context, 0.04),
      );
    }
  }
  
  static double getFontSize(BuildContext context, double baseSize) {
    if (isMobile(context)) {
      return baseSize;
    } else if (isTablet(context)) {
      return baseSize * 1.2;
    } else {
      return baseSize * 1.4;
    }
  }
}