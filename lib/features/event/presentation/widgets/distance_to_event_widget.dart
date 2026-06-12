import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../l10n/app_localizations.dart';

/// Widget that displays the distance to an event from the user's current location
class DistanceToEventWidget extends StatefulWidget {
  final double eventLat;
  final double eventLng;
  
  const DistanceToEventWidget({
    super.key,
    required this.eventLat,
    required this.eventLng,
  });

  @override
  State<DistanceToEventWidget> createState() => _DistanceToEventWidgetState();
}

class _DistanceToEventWidgetState extends State<DistanceToEventWidget> {
  double? distanceKm;
  
  @override
  void initState() {
    super.initState();
    _getDistance();
  }

  Future<void> _getDistance() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final d = Geolocator.distanceBetween(
        pos.latitude, 
        pos.longitude, 
        widget.eventLat, 
        widget.eventLng
      ) / 1000.0;
      setState(() { distanceKm = d; });
    } catch (_) {
      // Silently fail if location permission not granted
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (distanceKm == null) {
      return Text(
        l10n.calculatingDistance, 
        style: const TextStyle(color: Colors.blueGrey),
      );
    }
    return Text(
      '${l10n.distanceToEvent} ${distanceKm!.toStringAsFixed(2)} ${l10n.km}', 
      style: const TextStyle(
        color: Colors.blueGrey, 
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

