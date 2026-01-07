import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_color_config.dart';
import 'nav_bar_icon.dart';

/// Custom bottom navigation bar with gradient and animations
class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final List<NavigationItem> items;
  final int? unreadChatCount;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    this.unreadChatCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Container(
      margin: EdgeInsets.fromLTRB(
        AppTheme.spacingMd, // Sol
        AppTheme.spacingSm, // Üst
        AppTheme.spacingMd, // Sağ
        MediaQuery.of(context).padding.bottom + AppTheme.spacingXs, // Alt (4px)
      ),
      decoration: BoxDecoration(
        // Dark mode'da düz renk, light mode'da gradient
        color: brightness == Brightness.dark
            ? theme.colorScheme.surfaceContainerHighest // Düz renk
            : null,
        gradient: brightness == Brightness.dark
            ? null // Dark mode'da gradient yok
            : LinearGradient(
                colors: [
                  AppColorConfig.primaryColor.withValues(alpha: 0.95),
                  AppColorConfig.secondaryColor.withValues(alpha: 0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        boxShadow: brightness == Brightness.dark
            ? [
                // Dark mode için çok subtle shadow - sadece derinlik için
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ]
            : [
                // Light mode için yumuşak shadow
                BoxShadow(
                  color: AppColorConfig.primaryColor.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingXxl,
            vertical: AppTheme.spacingMd,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              
              // NavBarIcon widget'ını oluştur
              final navIcon = NavBarIcon(
                icon: item.icon,
                label: item.label,
                selected: selectedIndex == index,
                onTap: () => onTap(index),
              );
              
              // Chat item için unread count göster
              if (index == 1 && unreadChatCount != null && unreadChatCount! > 0) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    navIcon,
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColorConfig.errorColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadChatCount! > 99 ? '99+' : unreadChatCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }
              
              return navIcon;
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Navigation item data class
class NavigationItem {
  final IconData icon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.label,
  });
}

