import 'package:flutter/material.dart';
import '../models/event_model.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../features/event/presentation/viewmodels/event_viewmodel.dart';
import 'event_detail_page.dart';
import 'dart:async';
import 'widgets/app_gradient_container.dart';
import 'widgets/modern_loading_widget.dart';
import 'package:flutter/foundation.dart';
import '../core/widgets/modern_components.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_color_config.dart';
import '../l10n/app_localizations.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  Position? userPosition;
  GoogleMapController? mapController;
  bool iconsLoaded = false;
  double _currentZoom = 13;
  
  // Dark mode için Google Maps style JSON
  static const String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#1d2c4d"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8ec3b9"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#1a3646"}]
    },
    {
      "featureType": "administrative.country",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#4b6878"}]
    },
    {
      "featureType": "administrative.land_parcel",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#64779e"}]
    },
    {
      "featureType": "administrative.province",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#4b6878"}]
    },
    {
      "featureType": "landscape.man_made",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#334e87"}]
    },
    {
      "featureType": "landscape.natural",
      "elementType": "geometry",
      "stylers": [{"color": "#023e58"}]
    },
    {
      "featureType": "poi",
      "elementType": "geometry",
      "stylers": [{"color": "#283d6a"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#6f9ba5"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#1d2c4d"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#023e58"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#3C7680"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#304a7d"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#98a5be"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#1d2c4d"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#2c6675"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#255763"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#b0d5ce"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#023e58"}]
    },
    {
      "featureType": "transit",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#98a5be"}]
    },
    {
      "featureType": "transit",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#1d2c4d"}]
    },
    {
      "featureType": "transit.line",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#283d6a"}]
    },
    {
      "featureType": "transit.station",
      "elementType": "geometry",
      "stylers": [{"color": "#3a4762"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#0e1626"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#4e6d70"}]
    }
  ]
  ''';

  List<Marker> _buildClusteredMarkers(List<EventModel> events) {
    if (events.isEmpty) return [];
    // Basit grid tabanlı yaklaştırma: zoom seviyesine göre hücre boyutu
    double grid;
    if (_currentZoom >= 15) {
      grid = 0.005; // ~500m
    } else if (_currentZoom >= 13) {
      grid = 0.01; // ~1km
    } else if (_currentZoom >= 11) {
      grid = 0.025; // ~2.5km
    } else if (_currentZoom >= 9) {
      grid = 0.05; // ~5km
    } else {
      grid = 0.1; // ~10km
    }

    final Map<String, List<EventModel>> cellToEvents = {};
    for (final e in events) {
      if (e.location.latitude == 0 || e.location.longitude == 0) continue;
      final cellLat = (e.location.latitude / grid).floor();
      final cellLng = (e.location.longitude / grid).floor();
      final key = '$cellLat' '_' '$cellLng';
      (cellToEvents[key] ??= []).add(e);
    }

    final List<Marker> markers = [];
    cellToEvents.forEach((key, list) {
      // Hücre merkezi için ortalama konum
      final avgLat = list.map((e) => e.location.latitude).reduce((a, b) => a + b) / list.length;
      final avgLng = list.map((e) => e.location.longitude).reduce((a, b) => a + b) / list.length;
      if (list.length == 1) {
        final event = list.first;
        markers.add(
          Marker(
            markerId: MarkerId(event.id),
            position: LatLng(event.location.latitude, event.location.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            consumeTapEvents: true,
            onTap: () => _showEventSheet(event),
          ),
        );
      } else {
        markers.add(
          Marker(
            markerId: MarkerId('cluster_$key'),
            position: LatLng(avgLat, avgLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
            infoWindow: InfoWindow(title: '${list.length} etkinlik'),
            consumeTapEvents: true,
            onTap: () {
              // Küme tıklanınca biraz yaklaştır
              if (mapController != null) {
                mapController!.animateCamera(CameraUpdate.zoomTo((_currentZoom + 1.5).clamp(3.0, 20.0)));
              }
            },
          ),
        );
      }
    });

    // Kullanıcı konumu marker'ı ayrıca eklenecek build içinde
    return markers;
  }

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadCategoryIcons();
  }
  
  // didChangeDependencies kaldırıldı - style parametresi otomatik olarak güncelleniyor


  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() { userPosition = pos; });
    } catch (_) {}
  }

  Future<void> _loadCategoryIcons() async {
    setState(() {
      iconsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Web platformunda etkinlik listesi göster
    if (kIsWeb) {
      final eventViewModel = Provider.of<EventViewModel>(context);
      final events = eventViewModel.events;
      
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.events),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: events.isEmpty
            ? EmptyStateWidget(
                icon: Icons.map_outlined,
                title: l10n.noData,
                message: l10n.noData,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          event.category[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(event.title),
                      subtitle: Text(event.category),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDetailPage(event: event),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      );
    }

    final eventViewModel = Provider.of<EventViewModel>(context);
    final events = eventViewModel.events;
    final markers = _buildClusteredMarkers(events);

    // Kullanıcı konumu markerı
    if (userPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(userPosition!.latitude, userPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: l10n.eventLocation),
        ),
      );
    }

    final initialCameraPosition = userPosition != null
        ? CameraPosition(target: LatLng(userPosition!.latitude, userPosition!.longitude), zoom: 13)
        : const CameraPosition(target: LatLng(39.925533, 32.866287), zoom: 6); // Ankara default

    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

    return AppGradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: !iconsLoaded
            ? Center(child: ModernLoadingWidget(message: l10n.loading))
            : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: initialCameraPosition,
                    markers: Set.from(markers),
                    myLocationEnabled: userPosition != null,
                    myLocationButtonEnabled: false,
                    mapType: MapType.normal,
                    style: isDark ? _darkMapStyle : null, // Dark mode için özel stil
                    onMapCreated: (controller) {
                      mapController = controller;
                    },
                    onCameraMove: (position) {
                      _currentZoom = position.zoom;
                      // Zoom değiştikçe yeniden cluster
                      setState(() {});
                    },
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  ),
                  // Konum Butonu - Nav bar'ın hemen üstünde
                  Positioned(
                    bottom: 140,
                    right: AppTheme.spacingLg,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(28),
                      color: isDark 
                          ? theme.colorScheme.primary 
                          : AppColorConfig.secondaryColor,
                      child: InkWell(
                        onTap: () async {
                          if (userPosition == null) {
                            await _getUserLocation();
                          }
                          if (userPosition != null && mapController != null) {
                            mapController!.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(userPosition!.latitude, userPosition!.longitude),
                                  zoom: 15,
                                ),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(
                            Icons.my_location, 
                            size: 24, 
                            color: isDark 
                                ? theme.colorScheme.onPrimary 
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showEventSheet(EventModel event) {
    final theme = Theme.of(context);
    GlassModalBottomSheet.show(
      context: context,
      isScrollControlled: true,
      padding: EdgeInsets.only(
        left: AppTheme.spacingXxl,
        right: AppTheme.spacingXxl,
        top: AppTheme.spacingXxl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingXxl,
      ),
      child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        color: theme.colorScheme.primary.withAlpha(AppTheme.alphaLight),
                      image: event.coverPhotoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(event.coverPhotoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: event.coverPhotoUrl == null
                          ? Icon(
                              Icons.event,
                              color: theme.colorScheme.primary,
                              size: 32,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(
                            event.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 4),
                          Text(
                            event.category,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        const SizedBox(height: 4),
                          Text(
                            event.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                    ),
                ],
              ),
                const SizedBox(height: AppTheme.spacingXl),
              SizedBox(
                width: double.infinity,
                  child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventDetailPage(event: event),
                        ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Etkinlik Detayına Git'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                  ),
                ),
              ),
            ],
      ),
    );
  }
} 