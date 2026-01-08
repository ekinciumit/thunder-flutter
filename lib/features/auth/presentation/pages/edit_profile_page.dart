import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../core/widgets/modern_components.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../views/widgets/app_gradient_container.dart';

/// Modern Profil Düzenleme Sayfası
/// 
/// Özellikler:
/// - Bölümlenmiş layout (Fotoğraf, Kişisel Bilgiler, Bio)
/// - Net başlıklar ve helper text
/// - Görsel olarak ayrılmış bölümler
/// - Modern UI/UX
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  double _uploadProgress = 0.0;
  String? _tempPhotoUrl;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = authViewModel.user;
    
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _locationController = TextEditingController();
    _tempPhotoUrl = user?.photoUrl;
    
    // Değişiklikleri izle
    _nameController.addListener(_onChanged);
    _bioController.addListener(_onChanged);
    _locationController.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() { _hasChanges = true; });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }


  Future<void> _changePhoto() async {
    if (_isUploadingPhoto) return;

    final l10n = AppLocalizations.of(context);
    
    // Galeri veya kamera seçimi
    final source = await ModernDialog.showImageSource(
      context: context,
      title: l10n?.selectPhoto ?? 'Select Photo',
    );
    
    if (source == null || !mounted) return;
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 90);
    
    if (pickedFile == null || !mounted) return;
    
    // Kırpma işlemi
    final theme = Theme.of(context);
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: l10n?.cropPhoto ?? 'Crop Photo',
          toolbarColor: theme.colorScheme.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: l10n?.cropPhoto ?? 'Crop Photo',
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
      ],
    );
    
    if (croppedFile == null || !mounted) return;
    
    setState(() { 
      _isUploadingPhoto = true;
      _uploadProgress = 0.0;
    });
    
    try {
      if (!mounted) return;
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      
      if (authViewModel.user == null) return;
      
      // Clean Architecture: ViewModel üzerinden yükle
      // Not: _compressImage ile sıkıştırma yapıyoruz, bu kısmı koruyoruz
      // Upload işlemi ViewModel'de yapılıyor, bu yüzden dosya yolunu gönderiyoruz
      final url = await authViewModel.uploadProfilePhoto(croppedFile.path);
      
      if (!mounted) return;
      if (url != null) {
        setState(() {
          _tempPhotoUrl = url;
          _isUploadingPhoto = false;
          _hasChanges = true;
        });
        
        ModernSnackbar.showSuccess(context, l10n?.photoUpdated ?? 'Photo updated');
      } else {
        setState(() {
          _isUploadingPhoto = false;
        });
        ModernSnackbar.showError(context, 'Fotoğraf yüklenemedi');
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isUploadingPhoto = false; });
        ModernSnackbar.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_isLoading) return;
    
    final l10n = AppLocalizations.of(context);
    
    // Validasyon
    if (_nameController.text.trim().isEmpty) {
      ModernSnackbar.showError(context, l10n?.pleaseEnterDescription ?? 'Please enter your name');
      return;
    }
    
    setState(() { _isLoading = true; });
    
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      
      await authViewModel.completeProfile(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        photoUrl: _tempPhotoUrl,
      );
      
      if (mounted) {
        ModernSnackbar.showSuccess(context, l10n?.profileUpdated ?? 'Profile updated');
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ModernSnackbar.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    
    final l10n = AppLocalizations.of(context);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.cancel ?? 'Discard changes?'),
        content: Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n?.delete ?? 'Discard'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.user;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: AppGradientContainer(
        backgroundImagePath: 'assets/backgrounds/background_2.png',
        backgroundOpacity: 0.7,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              l10n?.editProfile ?? 'Edit Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColorConfig.cardColor,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.close, color: AppColorConfig.cardColor),
              onPressed: () async {
                if (!mounted) return;
                final navigator = Navigator.of(context);
                if (await _onWillPop()) {
                  if (mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
            actions: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                TextButton(
                  onPressed: _hasChanges ? _saveProfile : null,
                  child: Text(
                    l10n?.save ?? 'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _hasChanges 
                          ? AppColorConfig.primaryColor 
                          : Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════════════════════════════════════════════════════
                // BÖLÜM 1: PROFİL FOTOĞRAFI
                // ═══════════════════════════════════════════════════════════
                GlassContainer(
                  borderRadius: AppTheme.radiusXl,
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.photo ?? 'Profile Photo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColorConfig.cardColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        'Choose a photo that represents you',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColorConfig.cardColor.withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: _isUploadingPhoto ? null : _changePhoto,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColorConfig.primaryColor.withAlpha(100),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColorConfig.primaryColor.withAlpha(50),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _tempPhotoUrl != null && _tempPhotoUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: _tempPhotoUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            child: const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            child: Icon(
                                              Icons.person,
                                              size: 60,
                                              color: AppColorConfig.primaryColor,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: AppColorConfig.primaryColor.withAlpha(30),
                                          child: Icon(
                                            Icons.person,
                                            size: 60,
                                            color: AppColorConfig.primaryColor,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            // Edit badge
                            if (!_isUploadingPhoto)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _changePhoto,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: AppTheme.gradientPrimary,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.surface,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            // Upload progress
                            if (_isUploadingPhoto)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(150),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                          value: _uploadProgress > 0 ? _uploadProgress : null,
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                          strokeWidth: 3,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${(_uploadProgress * 100).toInt()}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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
                const SizedBox(height: AppTheme.spacingLg),
                
                // ═══════════════════════════════════════════════════════════
                // BÖLÜM 2: KİŞİSEL BİLGİLER
                // ═══════════════════════════════════════════════════════════
                GlassContainer(
                  borderRadius: AppTheme.radiusXl,
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.account ?? 'Personal Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColorConfig.cardColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        'Update your personal details',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColorConfig.cardColor.withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      
                      // İsim
                      _buildFormField(
                        controller: _nameController,
                        label: l10n?.name ?? 'Full Name',
                        hint: 'Enter your full name',
                        icon: Icons.person_outline,
                        maxLength: 50,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      
                      // Email (readonly)
                      _buildReadOnlyField(
                        value: user?.email ?? '',
                        label: l10n?.email ?? 'Email',
                        icon: Icons.email_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                
                // ═══════════════════════════════════════════════════════════
                // BÖLÜM 3: BİYOGRAFİ
                // ═══════════════════════════════════════════════════════════
                GlassContainer(
                  borderRadius: AppTheme.radiusXl,
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.bio ?? 'Bio',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColorConfig.cardColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        'Tell others about yourself',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColorConfig.cardColor.withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      
                      _buildFormField(
                        controller: _bioController,
                        label: l10n?.bio ?? 'Bio',
                        hint: 'Write a short bio about yourself...',
                        icon: Icons.edit_note,
                        maxLines: 4,
                        maxLength: 200,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColorConfig.primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColorConfig.cardColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: TextStyle(color: AppColorConfig.cardColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColorConfig.cardColor.withAlpha(100),
            ),
            filled: true,
            fillColor: Colors.white.withAlpha(10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: Colors.white.withAlpha(30),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: Colors.white.withAlpha(30),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: AppColorConfig.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(AppTheme.spacingMd),
            counterStyle: TextStyle(
              color: AppColorConfig.cardColor.withAlpha(150),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColorConfig.primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColorConfig.cardColor,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.lock_outline,
              size: 14,
              color: AppColorConfig.cardColor.withAlpha(100),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(5),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: Colors.white.withAlpha(15),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: AppColorConfig.cardColor.withAlpha(150),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

