import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/validators/form_validators.dart';
import '../core/widgets/responsive_widgets.dart';
import '../core/utils/responsive_helper.dart';
import 'widgets/modern_loading_widget.dart';

class CompleteProfilePage extends StatefulWidget {
  final void Function(String name, String bio, String? photoUrl) onComplete;
  const CompleteProfilePage({super.key, required this.onComplete});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  File? photoFile;
  String? uploadedPhotoUrl;
  bool isUploading = false;

  Future<void> _pickImageFromCamera() async {
    if (!mounted) return;
    
    try {
      final picker = ImagePicker();
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
      
      if (source == null || !mounted) return;
      
      final pickedFile = await picker.pickImage(source: source, imageQuality: 90);
      if (pickedFile == null || !mounted) return;
      
      // Kırpma işlemi
      CroppedFile? croppedFile;
      try {
        croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Kare profil fotoğrafı
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Fotoğrafı Kırp',
              toolbarColor: Theme.of(context).colorScheme.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true, // Profil fotoğrafı için kare zorunlu
            ),
            IOSUiSettings(
              title: 'Fotoğrafı Kırp',
              aspectRatioPresets: [CropAspectRatioPreset.square],
            ),
          ],
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fotoğraf kırpma hatası: ${e.toString()}')),
          );
        }
        return;
      }
      
      if (croppedFile != null && mounted) {
        setState(() {
          photoFile = File(croppedFile!.path);
        });
        await _uploadPhotoToStorage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf seçme hatası: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _uploadPhotoToStorage() async {
    if (photoFile == null || !mounted) return;
    
    setState(() { isUploading = true; });
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child('profile_photos').child(fileName);
    
    try {
      // Web platformu için putData kullan
      if (kIsWeb) {
        final bytes = await photoFile!.readAsBytes();
        await ref.putData(bytes);
      } else {
        await ref.putFile(photoFile!);
      }
      
      final url = await ref.getDownloadURL();
      
      if (mounted) {
        setState(() {
          uploadedPhotoUrl = url;
          isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { isUploading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf yükleme hatası: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profilini Tamamla')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7F53AC), Color(0xFF647DEE), Color(0xFFFFD54F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: ResponsivePadding(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Container(
                padding: ResponsiveHelper.getPadding(context),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withAlpha((0.37 * 255).toInt()),
                      Colors.deepPurple.withAlpha((0.04 * 255).toInt()),
                      Colors.blue.withAlpha((0.03 * 255).toInt()),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.deepPurple.withAlpha(40),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withAlpha(60),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.withAlpha(30),
                            Colors.blue.withAlpha(20),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add,
                        size: 48,
                        color: Colors.deepPurple.shade600,
                      ),
                    ),
                    ResponsiveSizedBox.spacing(),
                    Text(
                      'Profilini Tamamla',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                    ResponsiveSizedBox(
                      height: ResponsiveHelper.getSpacing(context) * 2,
                    ),
                    GestureDetector(
                      onTap: isUploading ? null : _pickImageFromCamera,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.withAlpha(30),
                              Colors.blue.withAlpha(20),
                              Colors.amber.withAlpha(15),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withAlpha(60),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.deepPurple,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: (uploadedPhotoUrl != null)
                              ? NetworkImage(uploadedPhotoUrl!)
                              : (photoFile != null ? FileImage(photoFile!) : null) as ImageProvider?,
                          backgroundColor: Colors.deepPurple.withAlpha(30),
                          child: (uploadedPhotoUrl == null && photoFile == null)
                              ? Icon(Icons.camera_alt, size: 40, color: Colors.deepPurple.shade600)
                              : null,
                        ),
                      ),
                    ),
                    if (isUploading) Container(
                      margin: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.withAlpha(20), Colors.orange.withAlpha(15)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withAlpha(40)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ModernLoadingWidget(
                            size: 24,
                            color: Colors.amber,
                            showMessage: false,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Fotoğraf yükleniyor...',
                            style: TextStyle(
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ResponsiveSizedBox(
                      height: ResponsiveHelper.getSpacing(context) * 2,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple.withAlpha(15), Colors.blue.withAlpha(10)],
                        ),
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getBorderRadius(context, 16),
                        ),
                        border: Border.all(color: Colors.deepPurple.withAlpha(40)),
                      ),
                      child: TextFormField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        validator: FormValidators.name,
                        decoration: InputDecoration(
                          labelText: 'İsim Soyisim',
                          labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.deepPurple.withAlpha(40)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.deepPurple.shade600, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          prefixIcon: Icon(Icons.person, color: Colors.deepPurple.shade600),
                          errorStyle: const TextStyle(color: Colors.red),
                          helperText: 'En az 2 karakter, sadece harf ve boşluk',
                        ),
                      ),
                    ),
                    ResponsiveSizedBox.spacing(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.withAlpha(15), Colors.cyan.withAlpha(10)],
                        ),
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getBorderRadius(context, 16),
                        ),
                        border: Border.all(color: Colors.blue.withAlpha(40)),
                      ),
                      child: TextFormField(
                        controller: bioController,
                        textInputAction: TextInputAction.done,
                        maxLines: 2,
                        validator: FormValidators.bio,
                        decoration: InputDecoration(
                          labelText: 'Biyografi (Opsiyonel)',
                          labelStyle: TextStyle(color: Colors.blue.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.blue.withAlpha(40)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          prefixIcon: Icon(Icons.description, color: Colors.blue.shade600),
                          errorStyle: const TextStyle(color: Colors.red),
                          helperText: 'Maksimum 500 karakter',
                          helperMaxLines: 1,
                        ),
                      ),
                    ),
                    ResponsiveSizedBox(
                      height: ResponsiveHelper.getSpacing(context) * 2,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple, Colors.blue],
                        ),
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getBorderRadius(context, 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withAlpha(60),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isUploading ? null : () {
                          if (!_formKey.currentState!.validate()) {
                            return; // Form geçersizse işlem yapma
                          }
                          widget.onComplete(
                            nameController.text.trim(),
                            bioController.text.trim(),
                            uploadedPhotoUrl,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: Text(
                          'Kaydet ve Devam Et',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
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
    );
  }
} 