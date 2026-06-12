import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/utils/category_utils.dart';

/// Event category picker section widget
/// Displays a button to select event category
class EventCategoryPickerSection extends StatelessWidget {
  final String selectedCategory;
  final VoidCallback onPickCategory;
  final ThemeData theme;

  const EventCategoryPickerSection({
    super.key,
    required this.selectedCategory,
    required this.onPickCategory,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColors = CategoryUtils.getCategoryColorScheme(selectedCategory);
    
    return GlassContainer(
      borderRadius: AppTheme.radiusLg,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Builder(
        builder: (context) {
          return OutlinedButton.icon(
            onPressed: onPickCategory,
            icon: Icon(
              Icons.category,
              color: categoryColors['primary']!,
            ),
            label: Text(
              selectedCategory,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: categoryColors['primary']!,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingMd,
              ),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              side: BorderSide(
                color: categoryColors['primary']!.withAlpha(AppTheme.alphaMedium),
                width: 1.5,
              ),
              backgroundColor: categoryColors['primary']!.withAlpha(AppTheme.alphaVeryLight),
            ),
          );
        },
      ),
    );
  }
}

