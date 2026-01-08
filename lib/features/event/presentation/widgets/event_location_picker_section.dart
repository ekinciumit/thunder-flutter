import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../l10n/app_localizations.dart';

/// Event location picker section widget
/// Displays a button to select event location on map
class EventLocationPickerSection extends StatelessWidget {
  final LatLng? selectedLatLng;
  final bool isLocating;
  final VoidCallback onSelectLocation;
  final ThemeData theme;
  final AppLocalizations? l10n;

  const EventLocationPickerSection({
    super.key,
    required this.selectedLatLng,
    required this.isLocating,
    required this.onSelectLocation,
    required this.theme,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLocating ? null : onSelectLocation,
      icon: const Icon(Icons.location_on),
      label: Builder(
        builder: (context) {
          final loc = selectedLatLng;
          if (loc == null) {
            return Text(l10n?.selectLocation ?? 'Select Location');
          }
          return Text(
            '${l10n?.locationSelected ?? 'Location Selected'}: (${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)})',
          );
        },
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppColorConfig.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXl,
          vertical: AppTheme.spacingLg,
        ),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),
    );
  }
}

