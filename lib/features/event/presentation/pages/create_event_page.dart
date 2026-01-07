import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/event_entity.dart';
import '../viewmodels/event_viewmodel.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../core/validators/form_validators.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../core/widgets/modern_components.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../views/widgets/app_gradient_container.dart';
import '../../../../views/widgets/event_cover_photo_picker.dart';
import '../../../../views/widgets/location_picker_dialog.dart';
import '../../../../core/utils/category_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  // Dark mode için Google Maps style JSON (map_view.dart ile aynı)
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
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController quotaController = TextEditingController();
  DateTime? selectedDateTime;
  File? coverPhotoFile;
  String? uploadedPhotoUrl;
  bool isUploading = false;
  bool _isSubmitting = false; // Double submit engelleme için
  
  // Kategori seçimi için
  final List<String> categories = CategoryUtils.categories;
  String selectedCategory = 'Diğer';
  LatLng? selectedLatLng;
  CameraPosition? initialCameraPosition;
  bool isLocating = false;
  Map<String, BitmapDescriptor> categoryIcons = {};
  bool iconsLoaded = false;

  @override
  void initState() {
    super.initState();
    // Icon'ları arka planda yükle (non-blocking)
    // Sayfa hemen açılsın, icon'lar yüklenirken location picker default icon kullanacak
    _loadCategoryIcons();
  }

  Future<void> _loadCategoryIcons() async {
    final Map<String, String> iconFiles = {
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
    final Map<String, BitmapDescriptor> loadedIcons = {};
    
    // Paralel yükleme için Future.wait kullan (daha hızlı)
    final futures = iconFiles.entries.map((entry) async {
      try {
        final bytes = await rootBundle.load(entry.value);
        final bitmap = BitmapDescriptor.bytes(bytes.buffer.asUint8List());
        return <String, BitmapDescriptor>{entry.key: bitmap};
      } catch (_) {
        return <String, BitmapDescriptor>{};
      }
    }).toList();
    
    final results = await Future.wait(futures);
    for (final result in results) {
      loadedIcons.addAll(result);
    }
    
    if (mounted) {
      setState(() {
        categoryIcons = loadedIcons;
        iconsLoaded = true;
      });
    }
  }

  Future<void> _pickCoverPhoto() async {
    final l10n = AppLocalizations.of(context);
    // Önce galeri veya kamera seçimi göster
    final source = await ModernDialog.showImageSource(
      context: context,
      title: l10n?.selectPhoto ?? 'Select Photo',
    );
    
    if (source == null) return;
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 90);
    if (pickedFile != null && mounted) {
      // Context'i async öncesi sakla
      final theme = Theme.of(context);
      // Kırpma işlemi
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: l10n?.cropPhoto ?? 'Crop Photo',
            toolbarColor: theme.colorScheme.primary,
            toolbarWidgetColor: theme.colorScheme.onPrimary,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: false, // Serbest kırpma
          ),
          IOSUiSettings(
            title: l10n?.cropPhoto ?? 'Crop Photo',
            aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
          ),
        ],
      );
      
      if (croppedFile != null) {
        setState(() { coverPhotoFile = File(croppedFile.path); });
        await _uploadCoverPhoto();
      }
    }
  }

  Future<void> _uploadCoverPhoto() async {
    // Guard clause: Null safety için yerel değişkene ata
    final file = coverPhotoFile;
    if (file == null) return;
    
    setState(() { isUploading = true; });
    
    try {
      if (!mounted) return;
      final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
      
      // Clean Architecture: ViewModel üzerinden yükle
      final url = await eventViewModel.uploadEventCoverPhoto(file.path);
      
      if (!mounted) return;
      if (url != null) {
        setState(() {
          uploadedPhotoUrl = url;
          isUploading = false;
        });
      } else {
        setState(() { isUploading = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fotoğraf yüklenemedi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() { isUploading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf yükleme hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickCategory() async {
    final l10n = AppLocalizations.of(context);
    final category = await showDialog<String>(
      context: context,
      builder: (context) {
        String tempCategory = selectedCategory;
        return StatefulBuilder(
          builder: (context, setModalState) => AlertDialog(
            title: Text(l10n?.selectCategory ?? 'Select Category'),
            content: SizedBox(
              width: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final categoryColors = CategoryUtils.getCategoryColorScheme(category);
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: categoryColors['primary']!.withAlpha(AppTheme.alphaVeryLight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.category,
                        color: categoryColors['primary'],
                      ),
                    ),
                    title: Text(category),
                    selected: tempCategory == category,
                    onTap: () {
                      setModalState(() {
                        tempCategory = category;
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n?.cancel ?? 'Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(tempCategory),
                child: Text(l10n?.select ?? 'Select'),
              ),
            ],
          ),
        );
      },
    );
    
    if (category != null && mounted) {
      setState(() {
        selectedCategory = category;
      });
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _selectLocationOnMap() async {
    setState(() { isLocating = true; });
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      position = null;
    }
    setState(() { isLocating = false; });
    final startLatLng = position != null
        ? LatLng(position.latitude, position.longitude)
        : const LatLng(39.925533, 32.866287); // Ankara default
    final initialLatLng = selectedLatLng ?? startLatLng;
    
    if (!mounted) return;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => LocationPickerDialog(
        initialLatLng: initialLatLng,
        initialCategory: selectedCategory,
        categories: categories,
        iconsLoaded: iconsLoaded,
        categoryIcons: categoryIcons,
        darkMapStyle: _darkMapStyle,
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        selectedLatLng = result['latLng'] as LatLng;
        selectedCategory = result['category'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety checks
    if (!mounted) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    // Consumer ile eventViewModel.isLoading değişikliklerini dinle
    return Consumer<EventViewModel>(
      builder: (context, eventViewModel, _) {
        try {
          final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
          final theme = Theme.of(context);
          
          // Try to get localization, but don't block if it fails
          AppLocalizations? l10n;
          try {
            l10n = AppLocalizations.of(context);
          } catch (e) {
            // Continue without localization - use fallback strings
          }
          final mediaQuery = MediaQuery.of(context);
          final keyboardHeight = mediaQuery.viewInsets.bottom;
          final isKeyboardOpen = keyboardHeight > 0;
        
        return AppGradientContainer(
      backgroundImagePath: 'assets/backgrounds/background_2.png',
      backgroundOpacity: 0.7,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,
        // Keyboard açıldığında layout kaymasını engelle
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          // Bottom inset'i manuel yönet (keyboard için)
          bottom: false,
          child: Stack(
          children: [
            // Keyboard-aware scroll view
            SingleChildScrollView(
              // Keyboard açıkken otomatik scroll
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: ResponsiveHelper.getPadding(context).left,
                right: ResponsiveHelper.getPadding(context).right,
                top: ResponsiveHelper.getPadding(context).top,
                // Keyboard açıkken extra bottom padding
                bottom: isKeyboardOpen 
                    ? keyboardHeight + AppTheme.spacingXl 
                    : ResponsiveHelper.getPadding(context).bottom + mediaQuery.padding.bottom,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 56), // Geri butonu için boşluk
                // Modern Photo Upload Card
                EventCoverPhotoPicker(
                  uploadedPhotoUrl: uploadedPhotoUrl,
                  isUploading: isUploading,
                  onPickPhoto: _pickCoverPhoto,
                ),
                const SizedBox(height: AppTheme.spacingXl),
                // Form Fields - Glass Style
                GlassContainer(
                  borderRadius: AppTheme.radiusLg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingLg, // Üst padding artırıldı
                  ),
                  child: Column(
                      children: [
                        ModernInputField(
                          controller: titleController,
                          label: l10n?.eventTitle ?? 'Event Title',
                          textInputAction: TextInputAction.next,
                          validator: FormValidators.title,
                          prefixIcon: Icon(Icons.title, color: AppColorConfig.primaryColor),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        ModernInputField(
                          controller: descController,
                          label: l10n?.eventDescription ?? 'Description',
                          textInputAction: TextInputAction.next,
                          maxLines: 3,
                          validator: FormValidators.description,
                          prefixIcon: Icon(Icons.description, color: AppColorConfig.secondaryColor),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        ModernInputField(
                          controller: addressController,
                          label: l10n?.eventAddress ?? 'Address',
                          textInputAction: TextInputAction.next,
                          validator: FormValidators.address,
                          prefixIcon: Icon(Icons.location_on, color: AppColorConfig.tertiaryColor),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        ModernInputField(
                          controller: quotaController,
                          label: l10n?.eventQuota ?? 'Quota',
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          validator: FormValidators.quota,
                          prefixIcon: Icon(Icons.people, color: AppColorConfig.primaryColor),
                        ),
                      ],
                    ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                // Kategori ve Tarih - Glass Style
                GlassContainer(
                  borderRadius: AppTheme.radiusLg,
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Column(
                      children: [
                        Builder(
                          builder: (context) {
                            final categoryColors = CategoryUtils.getCategoryColorScheme(selectedCategory);
                            return OutlinedButton.icon(
                              onPressed: _pickCategory,
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
                        const SizedBox(height: AppTheme.spacingMd),
                        OutlinedButton.icon(
                          onPressed: _pickDateTime,
                          icon: const Icon(Icons.calendar_today),
                          label: Builder(
                            builder: (context) {
                              final dt = selectedDateTime;
                              if (dt == null) return Text(l10n?.selectDateTime ?? 'Select Date & Time');
                              return Text('${dt.day}.${dt.month}.${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}');
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
                      ],
                    ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                // Konum seçme butonu
                FilledButton.icon(
                  onPressed: isLocating ? null : _selectLocationOnMap,
                  icon: const Icon(Icons.location_on),
                  label: Builder(
                    builder: (context) {
                      final loc = selectedLatLng;
                      if (loc == null) return Text(l10n?.selectLocation ?? 'Select Location');
                      return Text('${l10n?.locationSelected ?? 'Location Selected'}: (${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)})');
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
                ),
                const SizedBox(height: AppTheme.spacingXl),
                // Etkinlik Oluştur butonu
                FilledButton.icon(
                  onPressed: (eventViewModel.isLoading || _isSubmitting)
                      ? null
                      : () async {
                          // Double submit engelleme
                          if (_isSubmitting) return;
                          
                          final navigator = Navigator.of(context);
                          // Form validasyonu
                          if (_formKey.currentState?.validate() != true) {
                            ModernSnackbar.showError(
                              context,
                              l10n?.fillAllFields ?? 'Please fill all fields',
                            );
                            return;
                          }
                          // Guard clause: Tarih kontrolü (yerel değişkene ata)
                          final dateTime = selectedDateTime;
                          if (dateTime == null) {
                            ModernSnackbar.showError(
                              context,
                              l10n?.selectEventDateTime ?? 'Please select date and time',
                            );
                            return;
                          }
                          // Guard clause: Konum kontrolü (yerel değişkene ata)
                          final latLng = selectedLatLng;
                          if (latLng == null) {
                            ModernSnackbar.showError(
                              context,
                              l10n?.selectEventLocation ?? 'Please select location',
                            );
                            return;
                          }
                          
                          // Submit başlat - buton disabled olacak
                          setState(() { _isSubmitting = true; });
                          
                          try {
                            // Clean Architecture: EventEntity kullan
                            final locationEntity = LocationEntity(
                              latitude: latLng.latitude,
                              longitude: latLng.longitude,
                            );
                            
                            final event = EventEntity(
                              id: '',
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                              location: locationEntity,
                              address: addressController.text.trim(),
                              datetime: dateTime,
                              quota: int.tryParse(quotaController.text.trim()) ?? 0,
                              createdBy: authViewModel.user?.uid ?? '',
                              participants: [authViewModel.user?.uid ?? ''],
                              coverPhotoUrl: uploadedPhotoUrl,
                              category: selectedCategory,
                            );
                            await eventViewModel.addEvent(event);
                            if (!mounted) return;
                            navigator.pop();
                          } catch (e) {
                            if (!mounted) return;
                            final currentContext = context;
                            setState(() { _isSubmitting = false; });
                            if (mounted) {
                              ModernSnackbar.showError(currentContext, e.toString());
                            }
                          }
                        },
                  icon: _isSubmitting 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isSubmitting ? (l10n?.loading ?? 'Loading...') : (l10n?.createEvent ?? 'Create Event')),
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
                ),
                  ],
                ),
              ),
            ),
            // Geri butonu
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
                color: theme.colorScheme.onSurface,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface.withAlpha(AppTheme.alphaLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
        } catch (e) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading page: $e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
} 