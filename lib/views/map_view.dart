import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../viewmodels/event_viewmodel.dart';
import 'event_detail_page.dart';
import 'dart:async';
import 'widgets/app_gradient_container.dart';
import 'package:flutter/foundation.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  Position? userPosition;
  GoogleMapController? mapController;
  bool iconsLoaded = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadCategoryIcons();
  }

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
    // Web platformunda etkinlik listesi göster
    if (kIsWeb) {
      final eventViewModel = Provider.of<EventViewModel>(context);
      final events = eventViewModel.events;
      
      return Scaffold(
        appBar: AppBar(
          title: const Text('Etkinlikler'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: events.isEmpty
            ? const Center(
                child: Text('Henüz etkinlik bulunmuyor'),
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
    final markers = <Marker>[];

    // Etkinlik markerları
    for (final event in events) {
      if (event.location.latitude != 0 && event.location.longitude != 0) {
        markers.add(
          Marker(
            markerId: MarkerId(event.id),
            position: LatLng(event.location.latitude, event.location.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            consumeTapEvents: true,
            onTap: () {
              _showEventSheet(event);
            },
          ),
        );
      }
    }

    // Kullanıcı konumu markerı
    if (userPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(userPosition!.latitude, userPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Benim Konumum'),
        ),
      );
    }

    final initialCameraPosition = userPosition != null
        ? CameraPosition(target: LatLng(userPosition!.latitude, userPosition!.longitude), zoom: 13)
        : const CameraPosition(target: LatLng(39.925533, 32.866287), zoom: 6); // Ankara default

    return AppGradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: !iconsLoaded
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: initialCameraPosition,
                    markers: Set.from(markers),
                    myLocationEnabled: userPosition != null,
                    myLocationButtonEnabled: false,
                    onMapCreated: (controller) => mapController = controller,
                    onCameraMove: (position) {
                      // Zoom değişince marker ikonlarını güncelle
                      setState(() {});
                    },
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      heroTag: 'my_location_btn',
                      mini: true,
                      onPressed: () async {
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.my_location, color: Colors.white),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showEventSheet(event) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
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
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.primary.withAlpha(20),
                      image: event.coverPhotoUrl != null
                          ? DecorationImage(image: NetworkImage(event.coverPhotoUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: event.coverPhotoUrl == null
                        ? Icon(Icons.event, color: theme.colorScheme.primary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(event.category, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 4),
                        Text(event.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
                    );
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Etkinlik Detayına Git'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 