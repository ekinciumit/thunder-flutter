import 'package:flutter/material.dart';

/// Responsive Helper
/// 
/// Ekran boyutlarına göre responsive değerler döndüren yardımcı sınıf
class ResponsiveHelper {
  // Breakpoint'ler
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  
  /// Ekran genişliğini döndürür
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// Ekran yüksekliğini döndürür
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// Ekran tipini döndürür
  static DeviceType getDeviceType(BuildContext context) {
    final width = screenWidth(context);
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }
  
  /// Mobile cihaz mı?
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }
  
  /// Tablet cihaz mı?
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }
  
  /// Desktop cihaz mı?
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }
  
  /// Responsive padding döndürür
  /// 
  /// Mobile: small
  /// Tablet: medium
  /// Desktop: large
  static EdgeInsets getPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16);
      case DeviceType.tablet:
        return const EdgeInsets.all(24);
      case DeviceType.desktop:
        return const EdgeInsets.all(32);
    }
  }
  
  /// Responsive horizontal padding döndürür
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.symmetric(horizontal: 16);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(horizontal: 24);
      case DeviceType.desktop:
        return const EdgeInsets.symmetric(horizontal: 32);
    }
  }
  
  /// Responsive vertical padding döndürür
  static EdgeInsets getVerticalPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.symmetric(vertical: 16);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(vertical: 24);
      case DeviceType.desktop:
        return const EdgeInsets.symmetric(vertical: 32);
    }
  }
  
  /// Responsive font size döndürür
  /// 
  /// Mobile: baseSize
  /// Tablet: baseSize * 1.1
  /// Desktop: baseSize * 1.2
  static double getFontSize(BuildContext context, double baseSize) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return baseSize;
      case DeviceType.tablet:
        return baseSize * 1.1;
      case DeviceType.desktop:
        return baseSize * 1.2;
    }
  }
  
  /// Responsive spacing döndürür
  /// 
  /// Mobile: small
  /// Tablet: medium
  /// Desktop: large
  static double getSpacing(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 8;
      case DeviceType.tablet:
        return 12;
      case DeviceType.desktop:
        return 16;
    }
  }
  
  /// Responsive icon size döndürür
  static double getIconSize(BuildContext context, double baseSize) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return baseSize;
      case DeviceType.tablet:
        return baseSize * 1.2;
      case DeviceType.desktop:
        return baseSize * 1.4;
    }
  }
  
  /// Responsive border radius döndürür
  static double getBorderRadius(BuildContext context, double baseRadius) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return baseRadius;
      case DeviceType.tablet:
        return baseRadius * 1.1;
      case DeviceType.desktop:
        return baseRadius * 1.2;
    }
  }
  
  /// Responsive width (ekran genişliğinin yüzdesi)
  static double getWidth(BuildContext context, double percentage) {
    return screenWidth(context) * (percentage / 100);
  }
  
  /// Responsive height (ekran yüksekliğinin yüzdesi)
  static double getHeight(BuildContext context, double percentage) {
    return screenHeight(context) * (percentage / 100);
  }
  
  /// Responsive column count (GridView için)
  static int getColumnCount(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.desktop:
        return 3;
    }
  }
}

/// Cihaz tipi enum
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

