import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/map_cache_service.dart';

/// Location picker dialog widget
/// Allows user to select location on map and category
class LocationPickerDialog extends StatefulWidget {
  final LatLng initialLatLng;
  final String initialCategory;
  final List<String> categories;
  final bool iconsLoaded;
  final Map<String, BitmapDescriptor> categoryIcons;
  final String darkMapStyle;

  const LocationPickerDialog({
    super.key,
    required this.initialLatLng,
    required this.initialCategory,
    required this.categories,
    required this.iconsLoaded,
    required this.categoryIcons,
    required this.darkMapStyle,
  });

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late LatLng tempLatLng;
  late String tempCategory;
  @override
  void initState() {
    super.initState();
    tempLatLng = widget.initialLatLng;
    tempCategory = widget.initialCategory;
    
    // Cost Optimization: Check if we can use cached map
    if (MapCacheService.shouldUseCache(tempLatLng)) {
      // Cache exists and is valid, but we still need to create new widget
      // The cache helps reduce unnecessary map loads in rapid succession
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.selectLocationAndCategory),
      content: SizedBox(
        width: 320,
        height: 420,
        child: Column(
          children: [
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: tempLatLng,
                  zoom: 14,
                ),
                style: isDark ? widget.darkMapStyle : null,
                markers: {
                  Marker(
                    markerId: const MarkerId('selected'),
                    position: tempLatLng,
                    draggable: true,
                    icon: _getCategoryIcon(tempCategory),
                    onDragEnd: (newPos) {
                      setState(() {
                        tempLatLng = newPos;
                      });
                    },
                  ),
                },
                onTap: (latLng) {
                  setState(() {
                    tempLatLng = latLng;
                  });
                },
                onMapCreated: (controller) {
                  // Cost Optimization: Cache map controller and position
                  MapCacheService.cacheController(controller, tempLatLng, zoom: 14);
                },
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: tempCategory,
              decoration: InputDecoration(
                labelText: l10n.category,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: widget.categories.map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              )).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    tempCategory = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop({
              'latLng': tempLatLng,
              'category': tempCategory,
            });
          },
          child: Text(l10n.select),
        ),
      ],
    );
  }

  BitmapDescriptor _getCategoryIcon(String category) {
    if (widget.iconsLoaded && widget.categoryIcons.containsKey(category)) {
      return widget.categoryIcons[category]!;
    }
    // Fallback: use CategoryUtils fallback icon
    return CategoryUtils.getCategoryIconFallback(category);
  }
}

