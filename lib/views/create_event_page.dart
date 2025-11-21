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
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fotoğraf Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
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
                ElevatedButton(
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
      appBar: AppBar(title: const Text('Etkinlik Oluştur')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppTheme.gradientPrimary,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: ResponsiveHelper.getPadding(context),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: isUploading ? null : _pickCoverPhoto,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppTheme.gradientWithAlpha(
                          AppTheme.gradientPrimary,
                          AppTheme.alphaMediumLight,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                      border: Border.all(
                        color: Colors.deepPurple.withAlpha(AppTheme.alphaDark),
                        width: 1.5,
                      ),
                      boxShadow: [
                        AppTheme.shadowMedium(
                          color: Colors.deepPurple.withAlpha(AppTheme.alphaDark),
                        ),
                      ],
                      image: uploadedPhotoUrl != null
                          ? DecorationImage(image: NetworkImage(uploadedPhotoUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: uploadedPhotoUrl == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 48, color: Colors.deepPurple.shade600),
                                const SizedBox(height: 8),
                                Text(
                                  'Kapak Fotoğrafı Ekle',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.deepPurple.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
                if (isUploading) Container(
                  margin: const EdgeInsets.all(8.0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                          colors: AppTheme.gradientWithAlpha(
                            AppTheme.gradientSecondary,
                            AppTheme.alphaLight,
                          ),
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: Colors.deepPurple.withAlpha(AppTheme.alphaDark)),
                  ),
                  child: Column(
                    children: [
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(
                        'Fotoğraf yükleniyor...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                          colors: AppTheme.gradientWithAlpha(
                            AppTheme.gradientSecondary,
                            AppTheme.alphaVeryLight,
                          ),
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(color: Colors.deepPurple.withAlpha(AppTheme.alphaDark)),
                  ),
                  child: TextFormField(
                    controller: titleController,
                    textInputAction: TextInputAction.next,
                    validator: FormValidators.title,
                    decoration: InputDecoration(
                      labelText: 'Başlık',
                      labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide(color: Colors.deepPurple.withAlpha(AppTheme.alphaDark)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide(color: Colors.deepPurple.shade600, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      errorStyle: const TextStyle(color: Colors.red),
                      prefixIcon: Icon(Icons.title, color: Colors.deepPurple.shade600),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                          colors: AppTheme.gradientWithAlpha(
                            [theme.colorScheme.tertiary, theme.colorScheme.tertiaryContainer],
                            AppTheme.alphaVeryLight,
                          ),
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(color: Colors.blue.withAlpha(AppTheme.alphaDark)),
                  ),
                  child: TextFormField(
                    controller: descController,
                    textInputAction: TextInputAction.next,
                    maxLines: 3,
                    validator: FormValidators.description,
                    decoration: InputDecoration(
                      labelText: 'Açıklama',
                      labelStyle: TextStyle(color: Colors.blue.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide(color: Colors.blue.withAlpha(AppTheme.alphaDark)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      errorStyle: const TextStyle(color: Colors.red),
                      prefixIcon: Icon(Icons.description, color: Colors.blue.shade600),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withAlpha(AppTheme.alphaLight),
                        Colors.orange.withAlpha(AppTheme.alphaVeryLight),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(color: Colors.amber.withAlpha(AppTheme.alphaDark)),
                  ),
                  child: TextFormField(
                    controller: addressController,
                    textInputAction: TextInputAction.next,
                    validator: FormValidators.address,
                    decoration: InputDecoration(
                      labelText: 'Adres',
                      labelStyle: TextStyle(color: Colors.amber.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide(color: Colors.amber.withAlpha(AppTheme.alphaDark)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide(color: Colors.amber.shade600, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      errorStyle: const TextStyle(color: Colors.red),
                      prefixIcon: Icon(Icons.location_on, color: Colors.amber.shade600),
                    ),
                  ),
                ),
                ResponsiveSizedBox.spacing(),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withAlpha(AppTheme.alphaLight),
                        Colors.lightGreen.withAlpha(AppTheme.alphaVeryLight),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getBorderRadius(context, 16),
                    ),
                    border: Border.all(color: Colors.green.withAlpha(AppTheme.alphaDark)),
                  ),
                  child: TextFormField(
                    controller: quotaController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    validator: FormValidators.quota,
                    decoration: InputDecoration(
                      labelText: 'Kota',
                      labelStyle: TextStyle(color: Colors.green.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide(color: Colors.green.withAlpha(AppTheme.alphaDark)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      errorStyle: const TextStyle(color: Colors.red),
                      prefixIcon: Icon(Icons.people, color: Colors.green.shade600),
                    ),
                  ),
                ),
                ResponsiveSizedBox.spacing(),
                // Kategori Dropdown
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.withAlpha(AppTheme.alphaLight),
                        Colors.deepPurple.withAlpha(AppTheme.alphaVeryLight),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getBorderRadius(context, 16),
                    ),
                    border: Border.all(color: Colors.purple.withAlpha(AppTheme.alphaDark)),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      labelStyle: TextStyle(color: Colors.purple.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    items: categories.map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedCategory = val);
                    },
                  ),
                ),
                ResponsiveSizedBox.spacing(),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.teal.withAlpha(AppTheme.alphaLight),
                        Colors.cyan.withAlpha(AppTheme.alphaVeryLight),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getBorderRadius(context, 16),
                    ),
                    border: Border.all(color: Colors.teal.withAlpha(AppTheme.alphaDark)),
                  ),
                  child: ListTile(
                    title: Text(
                      selectedDateTime == null
                          ? 'Tarih/Saat seçiniz'
                          : '${selectedDateTime!.day}.${selectedDateTime!.month}.${selectedDateTime!.year} - ${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.teal.shade700),
                    ),
                    trailing: Icon(Icons.calendar_today, color: Colors.teal.shade600),
                    onTap: _pickDateTime,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
                    tileColor: Colors.transparent,
                  ),
                ),
                ResponsiveSizedBox.spacing(),
                // Konum seçme butonu ve seçili konumu göster
                ElevatedButton.icon(
                  onPressed: isLocating ? null : _selectLocationOnMap,
                  icon: const Icon(Icons.location_on),
                  label: Text(selectedLatLng == null
                      ? 'Haritadan Konum Seç'
                      : 'Konum Seçildi: (${selectedLatLng!.latitude.toStringAsFixed(4)}, ${selectedLatLng!.longitude.toStringAsFixed(4)})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getBorderRadius(context, 16),
                      ),
                    ),
                  ),
                ),
                ResponsiveSizedBox(
                  height: ResponsiveHelper.getSpacing(context) * 2,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppTheme.gradientSecondary,
                    ),
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getBorderRadius(context, 16),
                        ),
                        boxShadow: [
                          AppTheme.shadowMedium(
                            color: Colors.deepPurple.withAlpha(AppTheme.alphaDarker),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: eventViewModel.isLoading
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            // Form validasyonu
                            if (_formKey.currentState?.validate() != true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lütfen tüm zorunlu alanları doldurun'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            // Tarih kontrolü
                            if (selectedDateTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lütfen etkinlik tarihi ve saatini seçin'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            // Konum kontrolü
                            if (selectedLatLng == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lütfen etkinlik konumunu haritadan seçin'),
                                  backgroundColor: Colors.red,
                                ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 