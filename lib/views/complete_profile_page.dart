import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/validators/form_validators.dart';
import '../core/widgets/responsive_widgets.dart';
import '../core/utils/responsive_helper.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/modern_components.dart';
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          title: const Text(
            'Fotoğraf Seç',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primary),
                title: const Text('Galeri'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary),
                title: const Text('Kamera'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
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
          ModernSnackbar.showError(context, 'Fotoğraf kırpma hatası: ${e.toString()}');
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
        ModernSnackbar.showError(context, 'Fotoğraf seçme hatası: ${e.toString()}');
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
        ModernSnackbar.showError(context, 'Fotoğraf yükleme hatası: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profilini Tamamla')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppTheme.gradientPrimary,
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
                      colors: AppTheme.gradientWithAlpha(
                        AppTheme.gradientPrimaryLight,
                        AppTheme.alphaMediumLight,
                      ),
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                  border: Border.all(
                    color: Colors.deepPurple.withAlpha(AppTheme.alphaDark),
                    width: 1.5,
                  ),
                  boxShadow: [
                    AppTheme.shadowLarge(
                      color: Colors.deepPurple.withAlpha(AppTheme.alphaDarker),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppTheme.gradientWithAlpha(
                            AppTheme.gradientSecondary,
                            AppTheme.alphaMediumLight,
                          ),
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
                              Colors.deepPurple.withAlpha(AppTheme.alphaMediumDark),
                              Colors.blue.withAlpha(AppTheme.alphaMediumLight),
                              Colors.amber.withAlpha(AppTheme.alphaLight),
                            ],
                          ),
                          boxShadow: [
                            AppTheme.shadowMedium(
                              color: Colors.deepPurple.withAlpha(AppTheme.alphaDarker),
                              blurRadius: 16,
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
                          backgroundColor: Colors.deepPurple.withAlpha(AppTheme.alphaMediumDark),
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
                          colors: [
                            Colors.amber.withAlpha(AppTheme.alphaMediumLight),
                            Colors.orange.withAlpha(AppTheme.alphaLight),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: Colors.amber.withAlpha(AppTheme.alphaDark)),
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
                    ModernInputField(
                        controller: nameController,
                      label: 'İsim Soyisim',
                      hint: 'Adınız ve soyadınız',
                        textInputAction: TextInputAction.next,
                        validator: FormValidators.name,
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: theme.colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    ModernInputField(
                        controller: bioController,
                      label: 'Biyografi (Opsiyonel)',
                      hint: 'Kendiniz hakkında kısa bir açıklama',
                        textInputAction: TextInputAction.done,
                      maxLines: 3,
                        validator: FormValidators.bio,
                      prefixIcon: Icon(
                        Icons.description_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    ResponsiveSizedBox(
                      height: ResponsiveHelper.getSpacing(context) * 2,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isUploading ? null : () {
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }
                          widget.onComplete(
                            nameController.text.trim(),
                            bioController.text.trim(),
                            uploadedPhotoUrl,
                          );
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingXxl,
                            vertical: AppTheme.spacingLg,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          ),
                        ),
                        child: const Text(
                          'Kaydet ve Devam Et',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
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