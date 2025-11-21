import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../features/event/presentation/viewmodels/event_viewmodel.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../core/validators/form_validators.dart';
import '../core/widgets/responsive_widgets.dart';
import '../core/utils/responsive_helper.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_color_config.dart';
import '../core/widgets/modern_components.dart';
import 'widgets/modern_loading_widget.dart';
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController quotaController = TextEditingController();
  DateTime? selectedDateTime;
  File? coverPhotoFile;
  String? uploadedPhotoUrl;
  bool isUploading = false;
  
  // Kategori seçimi için
  final List<String> categories = [
    'Müzik', 'Spor', 'Yemek', 'Sanat', 'Parti', 'Teknoloji', 'Doğa', 'Eğitim', 'Oyun', 'Diğer'
  ];
  String selectedCategory = 'Diğer';
  LatLng? selectedLatLng;
  CameraPosition? initialCameraPosition;
  bool isLocating = false;
  Map<String, BitmapDescriptor> categoryIcons = {};
  bool iconsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoryIcons();
    });
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
    for (final entry in iconFiles.entries) {
      try {
        final bytes = await rootBundle.load(entry.value);
        final bitmap = BitmapDescriptor.bytes(bytes.buffer.asUint8List());
        loadedIcons[entry.key] = bitmap;
      } catch (_) {}
    }
    setState(() {
      categoryIcons = loadedIcons;
      iconsLoaded = true;
    });
  }

  /// Kategori renk şemasını döndürür
  Map<String, Color> _getCategoryColorScheme(String category) {
    switch (category) {
      case 'Müzik':
        return {
          'primary': const Color(0xFF7C3AED), // Deep purple
          'secondary': const Color(0xFFA855F7), // Lighter purple
        };
      case 'Spor':
        return {
          'primary': const Color(0xFF2563EB), // Blue
          'secondary': const Color(0xFF3B82F6), // Lighter blue
        };
      case 'Yemek':
        return {
          'primary': const Color(0xFFEA580C), // Orange
          'secondary': const Color(0xFFFB923C), // Lighter orange
        };
      case 'Sanat':
        return {
          'primary': const Color(0xFFDC2626), // Red
          'secondary': const Color(0xFFEF4444), // Lighter red
        };
      case 'Parti':
        return {
          'primary': const Color(0xFF059669), // Teal
          'secondary': const Color(0xFF10B981), // Lighter teal
        };
      case 'Teknoloji':
        return {
          'primary': const Color(0xFF4F46E5), // Indigo
          'secondary': const Color(0xFF6366F1), // Lighter indigo
        };
      case 'Doğa':
        return {
          'primary': const Color(0xFF16A34A), // Green
          'secondary': const Color(0xFF22C55E), // Lighter green
        };
      case 'Eğitim':
        return {
          'primary': const Color(0xFF92400E), // Brown
          'secondary': const Color(0xFFB45309), // Lighter brown
        };
      case 'Oyun':
        return {
          'primary': const Color(0xFF7C2D12), // Dark brown
          'secondary': const Color(0xFF991B1B), // Lighter brown
        };
      default: // Diğer
        return {
          'primary': const Color(0xFF6B7280), // Gray
          'secondary': Colors.grey.shade400,
        };
    }
  }

  BitmapDescriptor _getCategoryIcon(String category) {
    if (iconsLoaded && categoryIcons.containsKey(category)) {
      return categoryIcons[category]!;
    }
    // Yedek: renkli marker
    switch (category) {
      case 'Müzik':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case 'Spor':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'Yemek':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'Sanat':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      case 'Parti':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      case 'Teknoloji':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      case 'Doğa':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'Eğitim':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'Oyun':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<void> _pickCoverPhoto() async {
    // Önce galeri veya kamera seçimi göster
    final source = await ModernDialog.showImageSource(
      context: context,
      title: 'Fotoğraf Seç',
    );
    
    if (source == null) return;
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 90);
    if (pickedFile != null) {
      // Kırpma işlemi
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Fotoğrafı Kırp',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: false, // Serbest kırpma
          ),
          IOSUiSettings(
            title: 'Fotoğrafı Kırp',
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
    if (coverPhotoFile == null) return;
    setState(() { isUploading = true; });
    final fileName = 'event_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child('event_covers').child(fileName);
    await ref.putFile(coverPhotoFile!);
    final url = await ref.getDownloadURL();
    setState(() {
      uploadedPhotoUrl = url;
      isUploading = false;
    });
  }

  Future<void> _pickCategory() async {
    final theme = Theme.of(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusRound),
        ),
      ),
      builder: (context) {
        String tempCategory = selectedCategory;
        return StatefulBuilder(
          builder: (context, setModalState) => Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusRound),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: AppTheme.spacingMd),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withAlpha(AppTheme.alphaMedium),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingXl),
                  child: Row(
                    children: [
                      Text(
                        'Kategori Seç',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Categories Grid
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXl,
                  ),
                  child: Wrap(
                    spacing: AppTheme.spacingMd,
                    runSpacing: AppTheme.spacingMd,
                    children: categories.map((category) {
                      final isSelected = tempCategory == category;
                      final colorScheme = _getCategoryColorScheme(category);
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => tempCategory = category);
                          setState(() => selectedCategory = category);
                          Navigator.of(context).pop();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingLg,
                            vertical: AppTheme.spacingMd,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [colorScheme['primary']!, colorScheme['secondary']!],
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : colorScheme['primary']!.withAlpha(AppTheme.alphaVeryLight),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme['primary']!
                                  : colorScheme['primary']!.withAlpha(AppTheme.alphaMedium),
                              width: isSelected ? 2 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    AppTheme.shadowSoft(
                                      color: colorScheme['primary']!.withAlpha(AppTheme.alphaMedium),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            category,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme['primary']!,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),
              ],
            ),
          ),
        );
      },
    );
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
    LatLng startLatLng = position != null
        ? LatLng(position.latitude, position.longitude)
        : LatLng(39.925533, 32.866287); // Ankara default
    LatLng tempLatLng = selectedLatLng ?? startLatLng;
    String tempCategory = selectedCategory;
    if (mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Konum ve Kategori Seç'),
              content: SizedBox(
                width: 320,
                height: 420,
                child: Column(
                  children: [
                    Expanded(
                      child: !iconsLoaded
                          ? Center(child: ModernLoadingWidget(message: 'Harita yükleniyor...'))
                          : GoogleMap(
                              initialCameraPosition: CameraPosition(target: tempLatLng, zoom: 14),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('selected'),
                                  position: tempLatLng,
                                  draggable: true,
                                  icon: _getCategoryIcon(tempCategory),
                                  onDragEnd: (newPos) {
                                    setModalState(() { tempLatLng = newPos; });
                                  },
                                ),
                              },
                              onTap: (latLng) {
                                setModalState(() { tempLatLng = latLng; });
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: tempCategory,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: categories.map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() { tempCategory = val; });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (mounted) Navigator.of(context).pop();
                  },
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      selectedLatLng = tempLatLng;
                      selectedCategory = tempCategory;
                    });
                    if (mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Seç'),
                ),
              ],
            );
          },
        );
      },
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventViewModel = Provider.of<EventViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppTheme.gradientPrimary,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
          children: [
            SingleChildScrollView(
              padding: ResponsiveHelper.getPadding(context),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 56), // Geri butonu için boşluk
                // Modern Photo Upload Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    child: Stack(
                      children: [
                        // Photo or Placeholder
                        GestureDetector(
                          onTap: isUploading ? null : _pickCoverPhoto,
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: uploadedPhotoUrl != null
                                ? null
                                : BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColorConfig.primaryColor.withAlpha(AppTheme.alphaVeryLight),
                                        AppColorConfig.secondaryColor.withAlpha(AppTheme.alphaVeryLight),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                            child: uploadedPhotoUrl != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        uploadedPhotoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                        ),
                                      ),
                                      // Overlay for change button
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withAlpha(AppTheme.alphaMedium),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(AppTheme.spacingLg),
                                          decoration: BoxDecoration(
                                            color: AppColorConfig.primaryColor.withAlpha(AppTheme.alphaLight),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 48,
                                            color: AppColorConfig.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: AppTheme.spacingMd),
                                        Text(
                                          'Kapak Fotoğrafı Ekle',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: AppColorConfig.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: AppTheme.spacingXs),
                                        Text(
                                          'Galeri veya kameradan seç',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withAlpha(AppTheme.alphaMedium),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        // Upload Progress Overlay
                        if (isUploading)
                          Container(
                            height: 200,
                            color: Colors.black.withAlpha(AppTheme.alphaMedium),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColorConfig.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacingMd),
                                  Text(
                                    'Fotoğraf yükleniyor...',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Change Photo Button (when photo is uploaded)
                        if (uploadedPhotoUrl != null && !isUploading)
                          Positioned(
                            bottom: AppTheme.spacingMd,
                            right: AppTheme.spacingMd,
                            child: FilledButton.icon(
                              onPressed: _pickCoverPhoto,
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Değiştir'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white.withAlpha(AppTheme.alphaAlmostOpaque),
                                foregroundColor: AppColorConfig.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingMd,
                                  vertical: AppTheme.spacingSm,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),
                // Form Fields - Modern Card Style
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withAlpha(AppTheme.alphaVeryLight),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      children: [
                        ModernInputField(
                          controller: titleController,
                          label: 'Başlık',
                          textInputAction: TextInputAction.next,
                          validator: FormValidators.title,
                          prefixIcon: Icon(Icons.title, color: AppColorConfig.primaryColor),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        ModernInputField(
                          controller: descController,
                          label: 'Açıklama',
                          textInputAction: TextInputAction.next,
                          maxLines: 3,
                          validator: FormValidators.description,
                          prefixIcon: Icon(Icons.description, color: AppColorConfig.secondaryColor),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        ModernInputField(
                          controller: addressController,
                          label: 'Adres',
                          textInputAction: TextInputAction.next,
                          validator: FormValidators.address,
                          prefixIcon: Icon(Icons.location_on, color: AppColorConfig.tertiaryColor),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        ModernInputField(
                          controller: quotaController,
                          label: 'Kota',
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          validator: FormValidators.quota,
                          prefixIcon: Icon(Icons.people, color: AppColorConfig.primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                // Kategori ve Tarih - Modern Card Style
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withAlpha(AppTheme.alphaVeryLight),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      children: [
                        Builder(
                          builder: (context) {
                            final categoryColors = _getCategoryColorScheme(selectedCategory);
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
                          label: Text(
                            selectedDateTime == null
                                ? 'Tarih/Saat seçiniz'
                                : '${selectedDateTime!.day}.${selectedDateTime!.month}.${selectedDateTime!.year} - ${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}',
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
                ),
                const SizedBox(height: AppTheme.spacingMd),
                // Konum seçme butonu
                FilledButton.icon(
                  onPressed: isLocating ? null : _selectLocationOnMap,
                  icon: const Icon(Icons.location_on),
                  label: Text(selectedLatLng == null
                      ? 'Haritadan Konum Seç'
                      : 'Konum Seçildi: (${selectedLatLng!.latitude.toStringAsFixed(4)}, ${selectedLatLng!.longitude.toStringAsFixed(4)})'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColorConfig.primaryColor,
                    foregroundColor: Colors.white,
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
                  onPressed: eventViewModel.isLoading
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          // Form validasyonu
                          if (_formKey.currentState?.validate() != true) {
                            ModernSnackbar.showError(
                              context,
                              'Lütfen tüm zorunlu alanları doldurun',
                            );
                            return;
                          }
                          // Tarih kontrolü
                          if (selectedDateTime == null) {
                            ModernSnackbar.showError(
                              context,
                              'Lütfen etkinlik tarihi ve saatini seçin',
                            );
                            return;
                          }
                          // Konum kontrolü
                          if (selectedLatLng == null) {
                            ModernSnackbar.showError(
                              context,
                              'Lütfen etkinlik konumunu haritadan seçin',
                            );
                            return;
                          }
                          final event = EventModel(
                            id: '',
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            location: GeoPoint(selectedLatLng!.latitude, selectedLatLng!.longitude),
                            address: addressController.text.trim(),
                            datetime: selectedDateTime!,
                            quota: int.tryParse(quotaController.text.trim()) ?? 0,
                            createdBy: authViewModel.user?.uid ?? '',
                            participants: [authViewModel.user?.uid ?? ''],
                            coverPhotoUrl: uploadedPhotoUrl,
                            category: selectedCategory,
                          );
                          await eventViewModel.addEvent(event);
                          if (!mounted) return;
                          navigator.pop();
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('Etkinlik Oluştur'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColorConfig.tertiaryColor,
                    foregroundColor: Colors.white,
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
                  backgroundColor: Colors.white.withAlpha(AppTheme.alphaLight),
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
  }
} 