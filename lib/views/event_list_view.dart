import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../features/event/presentation/viewmodels/event_viewmodel.dart';
import '../models/event_model.dart';
import 'dart:math';
import '../views/event_detail_page.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'widgets/app_card.dart';
import 'widgets/app_gradient_container.dart';
import 'widgets/modern_loading_widget.dart';
import '../core/theme/app_theme.dart';

class EventListView extends StatefulWidget {
  const EventListView({super.key});

  @override
  State<EventListView> createState() => _EventListViewState();
}

class _EventListViewState extends State<EventListView> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, double> _distanceCache = {};
  String? locationHint;

  // Kategori filtresi
  final List<String> categories = [
    'Tümü', 'Müzik', 'Spor', 'Yemek', 'Sanat', 'Parti', 'Teknoloji', 'Doğa', 'Eğitim', 'Oyun', 'Diğer'
  ];
  String selectedCategory = 'Tümü';

  // Tarih aralığı filtresi
  DateTime? startDate;
  DateTime? endDate;

  // Mesafe filtresi (km)
  double selectedDistance = 10; // Varsayılan 10 km
  Position? userPosition;
  bool isDistanceFilterEnabled = false;

  Map<String, String> iconFiles = {
    'Müzik': 'assets/icons/music.png',
    'Spor': 'assets/icons/sport.png',
    'Yemek': 'assets/icons/food.png',
    'Sanat': 'assets/icons/art.png',
    'Parti': 'assets/icons/party.png',
    'Teknoloji': 'assets/icons/technology.png',
    'Doğa': 'assets/icons/nature.png',
    'Eğitim': 'assets/icons/education.png',
    'Oyun': 'assets/icons/game.png',
    'Diğer': 'assets/icons/other.png',
  };
  Map<String, ImageProvider> categoryIconImages = {};
  bool iconsLoaded = false;

  @override
  void initState() {
    super.initState();
    // Konum otomatik alınmıyor - kullanıcı "Konumuma en yakın etkinlikleri bul" butonuna tıkladığında alınacak
    // Sayfa yenilendiğinde (widget yeniden oluşturulduğunda) konum filtresini sıfırla
    _resetLocationFilter();
    _loadCategoryIcons();
  }

  /// Konum filtresini sıfırla
  /// Sayfa yenilendiğinde veya kullanıcı istediğinde çağrılır
  void _resetLocationFilter() {
    isDistanceFilterEnabled = false;
    userPosition = null;
    locationHint = null;
    _distanceCache.clear(); // Mesafe cache'ini de temizle
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() { locationHint = 'Konum servisi kapalı. Lütfen açın.'; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() { locationHint = 'Konum izni reddedildi.'; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() { locationHint = 'Konum izni kalıcı reddedildi. Ayarlardan izin verin.'; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() { userPosition = pos; locationHint = null; });
    } catch (_) {
      if (!mounted) return;
      setState(() { locationHint = 'Konum alınamadı. Tekrar deneyin.'; });
    }
  }

  Future<void> _loadCategoryIcons() async {
    final Map<String, ImageProvider> loadedIcons = {};
    for (final entry in iconFiles.entries) {
      try {
        loadedIcons[entry.key] = AssetImage(entry.value);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      categoryIconImages = loadedIcons;
      iconsLoaded = true;
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a =
        0.5 - cos(dLat)/2 + cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * (1 - cos(dLon)) / 2;
    return R * 2 * asin(sqrt(a));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventViewModel = Provider.of<EventViewModel>(context);
    final events = eventViewModel.events;

    // Filtreleme
    final filteredEvents = events.where((event) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = event.title.toLowerCase().contains(query) ||
          event.description.toLowerCase().contains(query) ||
          event.address.toLowerCase().contains(query);
      final matchesCategory = selectedCategory == 'Tümü' || event.category == selectedCategory;
      final matchesDate = (startDate == null || event.datetime.isAfter(startDate!.subtract(const Duration(days: 1)))) &&
          (endDate == null || event.datetime.isBefore(endDate!.add(const Duration(days: 1))));
      bool matchesDistance = true;
      if (isDistanceFilterEnabled &&
          userPosition != null &&
          event.location.latitude != 0 &&
          event.location.longitude != 0) {
        final distance = _calculateDistance(
          userPosition!.latitude,
          userPosition!.longitude,
          event.location.latitude,
          event.location.longitude,
        );
        matchesDistance = distance <= selectedDistance;
      }
      return matchesSearch && matchesCategory && matchesDate && matchesDistance;
    }).toList();

    // Mesafeye göre sıralama (sadece konum alındıysa ve mesafe filtresi aktifse)
    if (userPosition != null && isDistanceFilterEnabled) {
      filteredEvents.sort((a, b) {
        final da = _calculateDistance(userPosition!.latitude, userPosition!.longitude, a.location.latitude, a.location.longitude);
        final db = _calculateDistance(userPosition!.latitude, userPosition!.longitude, b.location.latitude, b.location.longitude);
        return da.compareTo(db);
      });
    }

    return AppGradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: null,
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                16, 
                MediaQuery.of(context).padding.top + 16, 
                16, 
                8
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withAlpha(20),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Etkinlik ara (başlık, açıklama, adres)',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary.withAlpha(120),
                          ),
                          prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_alt_rounded, color: Colors.white),
                      tooltip: 'Filtrele',
                      onPressed: () async {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                          ),
                          builder: (context) {
                            String tempSelectedCategory = selectedCategory;
                            DateTime? tempStartDate = startDate;
                            DateTime? tempEndDate = endDate;
                            double tempSelectedDistance = selectedDistance;
                            bool tempIsDistanceFilterEnabled = isDistanceFilterEnabled;
                            return Padding(
                              padding: EdgeInsets.only(
                                left: 24,
                                right: 24,
                                top: 24,
                                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                              ),
                              child: StatefulBuilder(
                                builder: (context, setModalState) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Filtreler', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 20),
                                    DropdownButtonFormField<String>(
                                      initialValue: tempSelectedCategory,
                                      items: categories.map((cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat, style: theme.textTheme.bodyMedium),
                                      )).toList(),
                                      onChanged: (val) {
                                        if (val != null) setModalState(() => tempSelectedCategory = val);
                                      },
                                      decoration: const InputDecoration(labelText: 'Kategori'),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.date_range),
                                            label: Text(tempStartDate == null ? 'Başlangıç' : '${tempStartDate!.day}.${tempStartDate!.month}.${tempStartDate!.year}'),
                                            onPressed: () async {
                                              final now = DateTime.now();
                                              final pickedStart = await showDatePicker(
                                                context: context,
                                                initialDate: tempStartDate ?? now,
                                                firstDate: DateTime(now.year - 1),
                                                lastDate: DateTime(now.year + 2),
                                                builder: (context, child) {
                                                  return Theme(
                                                    data: Theme.of(context).copyWith(
                                                      colorScheme: ColorScheme.light(
                                                        primary: theme.colorScheme.primary,
                                                        onPrimary: Colors.white,
                                                        surface: Colors.white,
                                                        onSurface: Colors.black,
                                                      ),
                                                    ),
                                                    child: child!,
                                                  );
                                                },
                                              );
                                              if (pickedStart != null) setModalState(() => tempStartDate = pickedStart);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.date_range),
                                            label: Text(tempEndDate == null ? 'Bitiş' : '${tempEndDate!.day}.${tempEndDate!.month}.${tempEndDate!.year}'),
                                            onPressed: () async {
                                              final now = DateTime.now();
                                              final pickedEnd = await showDatePicker(
                                                context: context,
                                                initialDate: tempEndDate ?? now,
                                                firstDate: DateTime(now.year - 1),
                                                lastDate: DateTime(now.year + 2),
                                                builder: (context, child) {
                                                  return Theme(
                                                    data: Theme.of(context).copyWith(
                                                      colorScheme: ColorScheme.light(
                                                        primary: theme.colorScheme.primary,
                                                        onPrimary: Colors.white,
                                                        surface: Colors.white,
                                                        onSurface: Colors.black,
                                                      ),
                                                    ),
                                                    child: child!,
                                                  );
                                                },
                                              );
                                              if (pickedEnd != null) setModalState(() => tempEndDate = pickedEnd);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Mesafe filtresi checkbox
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: tempIsDistanceFilterEnabled && userPosition != null,
                                          onChanged: userPosition != null
                                              ? (value) {
                                                  setModalState(() {
                                                    tempIsDistanceFilterEnabled = value ?? false;
                                                  });
                                                }
                                              : null,
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Mesafe filtresini aktif et (${tempSelectedDistance.round()} km)',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (tempIsDistanceFilterEnabled && userPosition != null) ...[
                                      const SizedBox(height: 8),
                                      Text('Mesafe: ${tempSelectedDistance.round()} km', style: theme.textTheme.bodySmall),
                                      Slider(
                                        value: tempSelectedDistance,
                                        min: 1,
                                        max: 50,
                                        divisions: 49,
                                        label: '${tempSelectedDistance.round()} km',
                                        onChanged: (val) => setModalState(() => tempSelectedDistance = val),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    // Konumuma en yakın etkinlikleri bul butonu (en altta, diğer filtrelerden sonra)
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: AppTheme.gradientWithAlpha(
                                            AppTheme.gradientSecondary,
                                            AppTheme.alphaMediumLight,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.deepPurple.withAlpha(AppTheme.alphaMediumDark),
                                        ),
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          // Konum al ve mesafe filtresini aktif et - otomatik uygula
                                          await _getUserLocation();
                                          if (!context.mounted) return;
                                          if (userPosition != null) {
                                            // Filtreleri otomatik uygula ve modal'ı kapat
                                            setState(() {
                                              isDistanceFilterEnabled = true;
                                              selectedCategory = tempSelectedCategory;
                                              startDate = tempStartDate;
                                              endDate = tempEndDate;
                                              selectedDistance = tempSelectedDistance;
                                            });
                                            // Modal'ı güvenli şekilde kapat
                                            if (Navigator.canPop(context)) {
                                              Navigator.of(context).pop();
                                            }
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: const Text('Konum alındı! En yakın etkinlikler gösteriliyor.'),
                                                  backgroundColor: Colors.green,
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          } else {
                                            // Hata durumunda ayarlar dialog'u göster
                                            final action = await showDialog<String>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Konum İzni/Ayarı'),
                                                content: Text(locationHint ?? 'Konum alınamadı. Lütfen ayarları kontrol edin.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, 'loc'),
                                                    child: const Text('Konum Ayarları'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, 'app'),
                                                    child: const Text('Uygulama Ayarları'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, 'cancel'),
                                                    child: const Text('Kapat'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (!context.mounted) return;
                                            if (action == 'loc') {
                                              await Geolocator.openLocationSettings();
                                            } else if (action == 'app') {
                                              await Geolocator.openAppSettings();
                                            }
                                            // Ayarlar açıldıktan sonra modal'ı kapatma - kullanıcı manuel kapatabilir
                                          }
                                        },
                                        icon: Icon(
                                          userPosition != null ? Icons.check_circle : Icons.my_location,
                                          color: userPosition != null ? Colors.green : Colors.deepPurple,
                                        ),
                                        label: Text(
                                          userPosition != null
                                              ? 'Konumum alındı ✓'
                                              : 'Konumuma en yakın etkinlikleri bul',
                                          style: TextStyle(
                                            color: userPosition != null ? Colors.green.shade700 : Colors.deepPurple.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                selectedCategory = tempSelectedCategory;
                                                startDate = tempStartDate;
                                                endDate = tempEndDate;
                                                selectedDistance = tempSelectedDistance;
                                                isDistanceFilterEnabled = tempIsDistanceFilterEnabled;
                                              });
                                              if (Navigator.canPop(context)) {
                                                Navigator.of(context).pop();
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: theme.colorScheme.primary,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                            ),
                                            child: const Text('Uygula'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              setModalState(() {
                                                tempSelectedCategory = 'Tümü';
                                                tempStartDate = null;
                                                tempEndDate = null;
                                                tempSelectedDistance = 10;
                                                tempIsDistanceFilterEnabled = false;
                                              });
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: theme.colorScheme.primary,
                                              side: BorderSide(color: theme.colorScheme.primary),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                            ),
                                            child: const Text('Temizle'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (locationHint != null && userPosition == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(AppTheme.alphaLight),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withAlpha(AppTheme.alphaMediumDark)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(child: Text(locationHint!, style: Theme.of(context).textTheme.bodySmall)),
                    ],
                  ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: eventViewModel.isLoading
                  ? Center(child: ModernLoadingWidget(message: 'Etkinlikler yükleniyor...'))
                  : filteredEvents.isEmpty
                      ? ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: 6,
                          separatorBuilder: (contextIgnored, indexIgnored) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return AppCard(
                            borderRadius: 24,
                              gradientColors: [Colors.grey.withAlpha(10), Colors.grey.withAlpha(6)],
                              boxShadow: const [],
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(height: 160, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(16))),
                                  const SizedBox(height: 12),
                                  Container(height: 16, width: 180, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8))),
                                  const SizedBox(height: 8),
                                  Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8))),
                                  const SizedBox(height: 6),
                                  Container(height: 12, width: 220, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8))),
                                  const SizedBox(height: 12),
                                ],
                            ),
                            );
                          },
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: filteredEvents.length + 1,
                          separatorBuilder: (contextIgnored, indexIgnored) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index == filteredEvents.length) {
                              // Load more footer as a button
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: eventViewModel.canLoadMore
                                      ? ElevatedButton.icon(
                                          onPressed: eventViewModel.isLoadingMore ? null : () => eventViewModel.loadMore(),
                                          icon: eventViewModel.isLoadingMore
                                              ? const SizedBox(
                                                  width: 16, height: 16, 
                                                  child: ModernLoadingWidget(size: 16, showMessage: false),
                                                )
                                              : const Icon(Icons.expand_more),
                                          label: Text(eventViewModel.isLoadingMore ? 'Yükleniyor...' : 'Daha fazla yükle'),
                                        )
                                      : const Text('Hepsi bu kadar'),
                                ),
                              );
                            }
                            final event = filteredEvents[index];
                            final colorScheme = _getCategoryColorScheme(event.category);
                            double? distanceKm;
                            if (userPosition != null && event.location.latitude != 0 && event.location.longitude != 0) {
                              distanceKm = _distanceCache[event.id];
                              if (distanceKm == null) {
                              distanceKm = _calculateDistance(
                                userPosition!.latitude,
                                userPosition!.longitude,
                                event.location.latitude,
                                event.location.longitude,
                              );
                                _distanceCache[event.id] = distanceKm;
                              }
                            }
                            return AppCard(
                              borderRadius: 24,
                              gradientColors: [
                                colorScheme['primary']!.withAlpha(25),
                                colorScheme['secondary']!.withAlpha(20),
                                colorScheme['accent']!.withAlpha(15),
                                Colors.white.withAlpha(30),
                              ],
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme['primary']!.withAlpha(40),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (event.coverPhotoUrl != null && event.coverPhotoUrl!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: CachedNetworkImage(
                                        imageUrl: event.coverPhotoUrl!,
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          height: 160,
                                          width: double.infinity,
                                          alignment: Alignment.center,
                                          child: const CircularProgressIndicator(),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          height: 160,
                                          width: double.infinity,
                                          color: colorScheme['primary']!.withAlpha(20),
                                          child: Icon(Icons.broken_image, size: 48, color: colorScheme['primary']!.withAlpha(100)),
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: colorScheme['primary']!.withAlpha(40),
                                              child: _getCategoryIcon(event.category),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                event.title,
                                                style: theme.textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white, // Metin rengini beyaz yap
                                                  shadows: [
                                                    const Shadow(
                                                      blurRadius: 2.0,
                                                      color: Colors.black54,
                                                      offset: Offset(1.0, 1.0),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [colorScheme['primary']!, colorScheme['secondary']!],
                                                ),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                event.category,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          event.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.9), // Metin rengini hafif şeffaf beyaz yap
                                            shadows: [
                                              const Shadow(
                                                blurRadius: 2.0,
                                                color: Colors.black45,
                                                offset: Offset(1.0, 1.0),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 18, color: Colors.white), // İkon rengini beyaz yap
                                            const SizedBox(width: 6),
                                            Text(
                                              '${event.datetime.day}.${event.datetime.month}.${event.datetime.year} - ${event.datetime.hour.toString().padLeft(2, '0')}:${event.datetime.minute.toString().padLeft(2, '0')}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: Colors.white, // Metin rengini beyaz yap
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(Icons.people, size: 18, color: Colors.white), // İkon rengini beyaz yap
                                            const SizedBox(width: 6),
                                            Text(
                                              '${event.participants.length}/${event.quota}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: Colors.white, // Metin rengini beyaz yap
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on, size: 18, color: Colors.white), // İkon rengini beyaz yap
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                event.address,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: Colors.white, // Metin rengini beyaz yap
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (distanceKm != null)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 8.0),
                                                child: Text(
                                                  'Mesafe: ${distanceKm.toStringAsFixed(1)} km',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: Colors.white, // Metin rengini beyaz yap
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _goToEventDetail(event),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get color scheme based on category with better contrast
  Map<String, Color> _getCategoryColorScheme(String category) {
    switch (category) {
      case 'Müzik':
        return {
          'primary': const Color(0xFF7C3AED), // Deep purple with better contrast
          'secondary': const Color(0xFFA855F7), // Lighter purple
          'accent': const Color(0xFF8B5CF6), // Purple accent
          'text': const Color(0xFF1C1B1F), // High contrast text
        };
      case 'Spor':
        return {
          'primary': const Color(0xFF2563EB), // Blue with better contrast
          'secondary': const Color(0xFF3B82F6), // Lighter blue
          'accent': const Color(0xFF60A5FA), // Blue accent
          'text': const Color(0xFF1C1B1F),
        };
      case 'Yemek':
        return {
          'primary': const Color(0xFFEA580C), // Orange with better contrast
          'secondary': const Color(0xFFFB923C), // Lighter orange
          'accent': const Color(0xFFF97316), // Orange accent
          'text': const Color(0xFF1C1B1F),
        };
      case 'Sanat':
        return {
          'primary': const Color(0xFFDC2626), // Red with better contrast
          'secondary': const Color(0xFFEF4444), // Lighter red
          'accent': const Color(0xFFF87171), // Red accent
          'text': const Color(0xFF1C1B1F),
        };
      case 'Parti':
        return {
          'primary': const Color(0xFF059669), // Teal with better contrast
          'secondary': const Color(0xFF10B981), // Lighter teal
          'accent': const Color(0xFF34D399), // Teal accent
          'text': const Color(0xFF1C1B1F),
        };
      case 'Teknoloji':
        return {
          'primary': const Color(0xFF4F46E5), // Indigo with better contrast
          'secondary': const Color(0xFF6366F1), // Lighter indigo
          'accent': const Color(0xFF818CF8), // Indigo accent
          'text': const Color(0xFF1C1B1F),
        };
      case 'Doğa':
        return {
          'primary': const Color(0xFF16A34A), // Green with better contrast
          'secondary': const Color(0xFF22C55E), // Lighter green
          'accent': const Color(0xFF4ADE80), // Green accent
          'text': const Color(0xFF1C1B1F),
        };
      case 'Eğitim':
        return {
          'primary': const Color(0xFF92400E), // Brown with better contrast
          'secondary': const Color(0xFFB45309), // Lighter brown
          'accent': const Color(0xFFD97706), // Brown accent
          'text': const Color(0xFF1C1B1F),
        };
      case 'Oyun':
        return {
          'primary': const Color(0xFF7C2D12), // Dark purple with better contrast
          'secondary': const Color(0xFF991B1B), // Lighter purple
          'accent': const Color(0xFFB91C1C), // Purple accent
          'text': const Color(0xFF1C1B1F),
        };
      default:
        return {
          'primary': const Color(0xFF6B7280), // Gray with better contrast
          'secondary': Colors.grey,
          'accent': Colors.grey,
        };
    }
  }

  Widget _getCategoryIcon(String category) {
    if (categoryIconImages.containsKey(category)) {
      return Image(
        image: categoryIconImages[category]!,
        width: 24,
        height: 24,
      );
    }
    return Icon(Icons.category, size: 24, color: _getCategoryColorScheme(category)['primary']);
  }

  void _goToEventDetail(EventModel event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailPage(event: event),
      ),
    );
  }
} 