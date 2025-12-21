import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../features/event/presentation/viewmodels/event_viewmodel.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../models/event_model.dart';
import '../views/event_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'widgets/app_gradient_container.dart';
import 'widgets/modern_loading_widget.dart';
import '../core/widgets/glass_container.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_color_config.dart';
import '../core/widgets/modern_components.dart';
import '../l10n/app_localizations.dart';

class EventListView extends StatefulWidget {
  const EventListView({super.key});

  @override
  State<EventListView> createState() => _EventListViewState();
}

class _EventListViewState extends State<EventListView> {
  final TextEditingController _searchController = TextEditingController();
  String? locationHint;
  Position? userPosition; // Konum alma için gerekli

  // Kategori listesi (UI için)
  final List<String> categories = [
    'Tümü', 'Müzik', 'Spor', 'Yemek', 'Sanat', 'Parti', 'Teknoloji', 'Doğa', 'Eğitim', 'Oyun', 'Diğer'
  ];

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
    _loadCategoryIcons();
    // Widget oluşturulduğunda konum filtresini sıfırla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
      eventViewModel.resetLocationFilter();
      userPosition = null;
      locationHint = null;
    });
  }

  Future<void> _getUserLocation(EventViewModel eventViewModel) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() { locationHint = 'locationServiceDisabled'; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() { locationHint = 'locationPermissionDenied'; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() { locationHint = 'locationPermissionDeniedForever'; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() { 
        userPosition = pos; 
        locationHint = null; 
      });
      // ViewModel'e konumu bildir
      eventViewModel.setUserLocation(pos.latitude, pos.longitude);
    } catch (_) {
      if (!mounted) return;
      setState(() { locationHint = 'locationFailed'; });
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final eventViewModel = Provider.of<EventViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final currentUser = authViewModel.user;
    
    // Following ID'lerini ViewModel'e set et (değişiklik varsa)
    final followingIds = currentUser?.following ?? [];
    if (followingIds.isNotEmpty) {
      // Sadece değişiklik varsa güncelle (sonsuz döngüyü önle)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        eventViewModel.setFollowingIds(followingIds);
      });
    }

    // Filtrelenmiş etkinlikleri ViewModel'den al (memoized)
    final filteredEvents = eventViewModel.getFilteredEvents();

    return AppGradientContainer(
      backgroundImagePath: 'assets/backgrounds/background_2.png',
      backgroundOpacity: 0.7,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: null,
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingLg, 
                MediaQuery.of(context).padding.top + AppTheme.spacingLg, 
                AppTheme.spacingLg, 
                AppTheme.spacingSm
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      borderRadius: AppTheme.radiusFull,
                      padding: EdgeInsets.zero,
                      glassAlpha: AppTheme.glassAlphaVeryLight,
                      borderAlpha: AppTheme.glassAlphaMedium,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l10n.searchEventHint,
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          suffixIcon: eventViewModel.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: theme.colorScheme.error,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    eventViewModel.setSearchQuery('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingXl,
                            vertical: AppTheme.spacingLg,
                          ),
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        onChanged: (value) {
                          eventViewModel.setSearchQuery(value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  FilledButton(
                      onPressed: () async {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(AppTheme.radiusRound),
                            ),
                          ),
                          builder: (context) {
                            String tempSelectedCategory = eventViewModel.selectedCategory;
                            DateTime? tempStartDate = eventViewModel.startDate;
                            DateTime? tempEndDate = eventViewModel.endDate;
                            double tempSelectedDistance = eventViewModel.selectedDistance;
                            bool tempIsDistanceFilterEnabled = eventViewModel.isDistanceFilterEnabled;
                            return Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(AppTheme.radiusRound),
                                ),
                              ),
                              child: Padding(
                              padding: EdgeInsets.only(
                                  left: AppTheme.spacingXxl,
                                  right: AppTheme.spacingXxl,
                                  top: AppTheme.spacingXxl,
                                  bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingXxl,
                              ),
                              child: StatefulBuilder(
                                builder: (context, setModalState) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.filters, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                                      decoration: InputDecoration(labelText: l10n.category),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.date_range),
                                            label: Text(tempStartDate == null ? l10n.startDateLabel : '${tempStartDate!.day}.${tempStartDate!.month}.${tempStartDate!.year}'),
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
                                            label: Text(tempEndDate == null ? l10n.endDateLabel : '${tempEndDate!.day}.${tempEndDate!.month}.${tempEndDate!.year}'),
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
                                            '${l10n.enableDistanceFilter} (${tempSelectedDistance.round()} km)',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (tempIsDistanceFilterEnabled && userPosition != null) ...[
                                      const SizedBox(height: 8),
                                      Text('${l10n.distanceLabel}: ${tempSelectedDistance.round()} km', style: theme.textTheme.bodySmall),
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
                                          await _getUserLocation(eventViewModel);
                                          if (!context.mounted) return;
                                          if (userPosition != null) {
                                            // Filtreleri ViewModel'e uygula
                                            eventViewModel.setCategory(tempSelectedCategory);
                                            eventViewModel.setDateRange(start: tempStartDate, end: tempEndDate);
                                            eventViewModel.setDistanceFilter(
                                              enabled: true,
                                              distance: tempSelectedDistance,
                                            );
                                            // Modal'ı güvenli şekilde kapat
                                            if (Navigator.canPop(context)) {
                                              Navigator.of(context).pop();
                                            }
                                            if (context.mounted) {
                                              ModernSnackbar.showSuccess(
                                                context,
                                                l10n.locationObtained,
                                              );
                                            }
                                          } else {
                                            // Hata durumunda ayarlar dialog'u göster
                                            final action = await showDialog<String>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                                                ),
                                                title: Text(
                                                  l10n.locationSettingsTitle,
                                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                                ),
                                                content: Text(
                                                  _getLocationHintText(l10n),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, 'loc'),
                                                    child: Text(l10n.locationSettingsBtn),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, 'app'),
                                                    child: Text(l10n.appSettingsBtn),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, 'cancel'),
                                                    child: Text(l10n.close),
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
                                          }
                                        },
                                        icon: Icon(
                                          userPosition != null ? Icons.check_circle : Icons.my_location,
                                          color: userPosition != null ? Colors.green : Colors.deepPurple,
                                        ),
                                        label: Text(
                                          userPosition != null
                                              ? '${l10n.locationObtained} ✓'
                                              : l10n.findNearbyEvents,
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
                                              // Filtreleri ViewModel'e uygula
                                              eventViewModel.setCategory(tempSelectedCategory);
                                              eventViewModel.setDateRange(start: tempStartDate, end: tempEndDate);
                                              eventViewModel.setDistanceFilter(
                                                enabled: tempIsDistanceFilterEnabled,
                                                distance: tempSelectedDistance,
                                              );
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
                                            child: Text(l10n.apply),
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
                                            child: Text(l10n.clear),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    ),
                    child: const Icon(Icons.filter_alt_rounded),
                  ),
                ],
              ),
            ),
            if (locationHint != null && userPosition == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColorConfig.warningColor.withAlpha(AppTheme.alphaLight),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppColorConfig.warningColor.withAlpha(AppTheme.alphaMediumDark),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColorConfig.warningColor,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Text(
                          locationHint!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColorConfig.warningColor,
                          ),
                        ),
                      ),
                    ],
                  ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Expanded(
              child: eventViewModel.isLoading
                  ? Center(
                      child: ModernLoadingWidget(message: l10n.loadingEvents),
                    )
                  : filteredEvents.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.event_busy,
                          title: l10n.noEventsFoundTitle,
                          message: eventViewModel.searchQuery.isNotEmpty
                              ? l10n.noEventsFoundSearch
                              : l10n.noEventsFoundEmpty,
                          actionText: eventViewModel.searchQuery.isNotEmpty ? l10n.clearFilters : null,
                          onAction: eventViewModel.searchQuery.isNotEmpty
                              ? () {
                                  _searchController.clear();
                                  eventViewModel.resetFilters();
                                }
                              : null,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMd,
                            vertical: AppTheme.spacingSm,
                          ),
                          itemCount: filteredEvents.length + 1,
                          separatorBuilder: (contextIgnored, indexIgnored) => const SizedBox(height: AppTheme.spacingLg),
                          itemBuilder: (context, index) {
                            if (index == filteredEvents.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                                child: Center(
                                  child: eventViewModel.canLoadMore
                                      ? FilledButton.icon(
                                          onPressed: eventViewModel.isLoadingMore
                                              ? null
                                              : () => eventViewModel.loadMore(),
                                          icon: eventViewModel.isLoadingMore
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Icon(Icons.expand_more),
                                          label: Text(
                                            eventViewModel.isLoadingMore ? l10n.loading : l10n.loadMore,
                                          ),
                                        )
                                      : Text(
                                          l10n.thatsAll,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                ),
                              );
                            }
                            final event = filteredEvents[index];
                            // Mesafe hesaplama ViewModel'den
                            final distanceKm = eventViewModel.getDistanceForEvent(event);
                            return _buildModernEventCard(event, distanceKm, theme);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLocationHintText(AppLocalizations l10n) {
    if (locationHint == null) return l10n.locationFailed;
    switch (locationHint) {
      case 'locationServiceDisabled':
        return l10n.locationServiceDisabled;
      case 'locationPermissionDenied':
        return l10n.locationPermissionDenied;
      case 'locationPermissionDeniedForever':
        return l10n.locationPermissionDeniedForever;
      case 'locationFailed':
        return l10n.locationFailed;
      default:
        return l10n.locationFailed;
    }
  }

  Widget _buildModernEventCard(EventModel event, double? distanceKm, ThemeData theme) {
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          // iOS 16 tarzı güçlü blur efekti
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              // iOS 16 glassmorphism - çok şeffaf, gerçekten camsı
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05) // Çok şeffaf beyaz (dark mode)
                  : Colors.white.withValues(alpha: 0.15), // Light mode için biraz daha opak
              borderRadius: BorderRadius.circular(22),
              // İnce, şeffaf border - iOS 16 tarzı
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15) // Çok şeffaf border
                    : Colors.white.withValues(alpha: 0.25),
                width: 1.0, // Daha ince border
              ),
              // Subtle shadow - sadece derinlik için
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _goToEventDetail(event),
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.coverPhotoUrl != null && event.coverPhotoUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(22),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: event.coverPhotoUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 180,
                            color: isDark
                                ? theme.colorScheme.surface.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.1),
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              color: isDark
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                                  : Colors.white.withValues(alpha: 0.7),
                              strokeWidth: 2.5,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 180,
                            color: isDark
                                ? theme.colorScheme.surface.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.1),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: isDark
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  event.title,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? theme.colorScheme.onSurface
                                        : Colors.white.withValues(alpha: 0.95),
                                    height: 1.3,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColorConfig.primaryColor.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColorConfig.primaryColor.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  event.category,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? theme.colorScheme.onSurface
                                        : Colors.white.withValues(alpha: 0.9),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                              color: isDark
                                  ? theme.colorScheme.onSurfaceVariant
                                  : Colors.white.withValues(alpha: 0.82),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: isDark
                                    ? theme.colorScheme.onSurfaceVariant
                                    : Colors.white.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${event.datetime.day}.${event.datetime.month}.${event.datetime.year} - ${event.datetime.hour.toString().padLeft(2, '0')}:${event.datetime.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? theme.colorScheme.onSurfaceVariant
                                        : Colors.white.withValues(alpha: 0.85),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.people_rounded,
                                size: 18,
                                color: isDark
                                    ? theme.colorScheme.onSurfaceVariant
                                    : Colors.white.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${event.participants.length}/${event.quota}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? theme.colorScheme.onSurfaceVariant
                                      : Colors.white.withValues(alpha: 0.85),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 18,
                                color: isDark
                                    ? theme.colorScheme.onSurfaceVariant
                                    : Colors.white.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.address,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? theme.colorScheme.onSurfaceVariant
                                        : Colors.white.withValues(alpha: 0.85),
                                    height: 1.4,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (distanceKm != null) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColorConfig.primaryColor.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColorConfig.primaryColor.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${distanceKm.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? theme.colorScheme.onSurface
                                          : Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goToEventDetail(EventModel event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailPage(event: event),
      ),
    );
  }
} 