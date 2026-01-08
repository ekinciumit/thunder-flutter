import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../l10n/app_localizations.dart';

/// Event submit button section widget
/// Displays the create event button with loading state
class EventSubmitButtonSection extends StatelessWidget {
  final bool isLoading;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final ThemeData theme;
  final AppLocalizations? l10n;

  const EventSubmitButtonSection({
    super.key,
    required this.isLoading,
    required this.isSubmitting,
    required this.onSubmit,
    required this.theme,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: (isLoading || isSubmitting) ? null : onSubmit,
      icon: isSubmitting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.add),
      label: Text(
        isSubmitting
            ? (l10n?.loading ?? 'Loading...')
            : (l10n?.createEvent ?? 'Create Event'),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppColorConfig.tertiaryColor,
        foregroundColor: theme.colorScheme.onTertiary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXl,
          vertical: AppTheme.spacingLg,
        ),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        elevation: 2,
      ),
    );
  }
}

