import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../l10n/app_localizations.dart';

/// Event date time picker section widget
/// Displays a button to select event date and time
class EventDateTimePickerSection extends StatelessWidget {
  final DateTime? selectedDateTime;
  final VoidCallback onPickDateTime;
  final AppLocalizations? l10n;

  const EventDateTimePickerSection({
    super.key,
    required this.selectedDateTime,
    required this.onPickDateTime,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: AppTheme.radiusLg,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: OutlinedButton.icon(
        onPressed: onPickDateTime,
        icon: const Icon(Icons.calendar_today),
        label: Builder(
          builder: (context) {
            final dt = selectedDateTime;
            if (dt == null) {
              return Text(l10n?.selectDateTime ?? 'Select Date & Time');
            }
            return Text(
              '${dt.day}.${dt.month}.${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
            );
          },
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
        ),
      ),
    );
  }
}

