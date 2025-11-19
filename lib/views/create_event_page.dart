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
                          ? const Center(child: CircularProgressIndicator())
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
            colors: [Color(0xFF7F53AC), Color(0xFF647DEE), Color(0xFFFFD54F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                        colors: [
                          Colors.deepPurple.withAlpha(30),
                          Colors.blue.withAlpha(20),
                          Colors.amber.withAlpha(15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.deepPurple.withAlpha(40),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withAlpha(40),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
                      colors: [Colors.deepPurple.withAlpha(20), Colors.blue.withAlpha(15)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepPurple.withAlpha(40)),
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
                      colors: [Colors.deepPurple.withAlpha(15), Colors.blue.withAlpha(10)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.deepPurple.withAlpha(40)),
                  ),
                  child: TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Başlık',
                      labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Başlık giriniz' : null,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.withAlpha(15), Colors.cyan.withAlpha(10)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withAlpha(40)),
                  ),
                  child: TextFormField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Açıklama',
                      labelStyle: TextStyle(color: Colors.blue.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    maxLines: 2,
                    validator: (v) => v == null || v.isEmpty ? 'Açıklama giriniz' : null,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.withAlpha(15), Colors.orange.withAlpha(10)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withAlpha(40)),
                  ),
                  child: TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Adres',
                      labelStyle: TextStyle(color: Colors.amber.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Adres giriniz' : null,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.withAlpha(15), Colors.lightGreen.withAlpha(10)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withAlpha(40)),
                  ),
                  child: TextFormField(
                    controller: quotaController,
                    decoration: InputDecoration(
                      labelText: 'Kota',
                      labelStyle: TextStyle(color: Colors.green.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Kota giriniz' : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Kategori Dropdown
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.withAlpha(15), Colors.deepPurple.withAlpha(10)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple.withAlpha(40)),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      labelStyle: TextStyle(color: Colors.purple.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
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
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.withAlpha(15), Colors.cyan.withAlpha(10)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.withAlpha(40)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    tileColor: Colors.transparent,
                  ),
                ),
                const SizedBox(height: 16),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withAlpha(60),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: eventViewModel.isLoading
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            if (_formKey.currentState?.validate() != true || selectedDateTime == null || selectedLatLng == null) return;
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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