import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../core/validators/form_validators.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../core/widgets/modern_components.dart';
import '../../../../l10n/app_localizations.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

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
      final l10n = AppLocalizations.of(context)!;
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          title: Text(
            l10n.selectPhoto,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primary),
                title: Text(l10n.photo),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary),
                title: Text(l10n.photo),
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
              toolbarTitle: l10n.cropPhoto,
              toolbarColor: Theme.of(context).colorScheme.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true, // Profil fotoğrafı için kare zorunlu
            ),
            IOSUiSettings(
              title: l10n.cropPhoto,
              aspectRatioPresets: [CropAspectRatioPreset.square],
            ),
          ],
        );
      } catch (e) {
        if (mounted) {
          ModernSnackbar.showError(context, l10n.photoUploadError(e.toString()));
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
        ModernSnackbar.showError(context, AppLocalizations.of(context)!.filePickError(e.toString()));
      }
    }
  }

  Future<void> _uploadPhotoToStorage() async {
    if (photoFile == null || !mounted) return;
    
    setState(() { isUploading = true; });
    
    try {
      if (!mounted) return;
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      
      if (authViewModel.user == null) {
        setState(() { isUploading = false; });
        ModernSnackbar.showError(context, AppLocalizations.of(context)!.userInfoNotFound);
        return;
      }
      
      // Clean Architecture: ViewModel üzerinden yükle
      final url = await authViewModel.uploadProfilePhoto(photoFile!.path);
      
      if (!mounted) return;
      if (url != null) {
        setState(() {
          uploadedPhotoUrl = url;
          isUploading = false;
        });
      } else {
        setState(() { isUploading = false; });
        ModernSnackbar.showError(context, AppLocalizations.of(context)!.photoUploadFailed);
      }
    } catch (e) {
      if (mounted) {
        setState(() { isUploading = false; });
        ModernSnackbar.showError(context, AppLocalizations.of(context)!.photoUploadError(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final authViewModel = Provider.of<AuthViewModel>(context);
    final l10n = AppLocalizations.of(context)!;
    
    // ✅ Profil tamamlandıysa ana sayfaya yönlendir
    // NOT: Dev preview modunda bu redirect'i devre dışı bırak
    // (Dev preview'da ekranın kapanmaması için)
    // Navigator stack'te birden fazla sayfa varsa dev preview modundadır
    final isDevPreview = Navigator.of(context).canPop();
    
    if (!authViewModel.needsProfileCompletion && 
        authViewModel.user != null && 
        !isDevPreview) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.mounted) {
          context.go('/');
        }
      });
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColorConfig.getGradientPrimary(brightness),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppTheme.spacingXl),
                    // ✅ Başlık ve Açıklama
                    Text(
                      l10n.completeProfile,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      l10n.completeProfileSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: AppTheme.alphaMedium / 255.0),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingXxl * 1.5),
                    // ✅ Profil Fotoğrafı
                    Center(
                      child: GestureDetector(
                        onTap: isUploading ? null : _pickImageFromCamera,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: uploadedPhotoUrl != null || photoFile != null
                                      ? [Colors.transparent, Colors.transparent]
                                      : [
                                          theme.colorScheme.primaryContainer,
                                          theme.colorScheme.secondaryContainer,
                                        ],
                                ),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withValues(alpha: AppTheme.alphaLight / 255.0),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: AppTheme.alphaLight / 255.0),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: (uploadedPhotoUrl != null)
                                    ? Image.network(
                                        uploadedPhotoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(theme),
                                      )
                                    : (photoFile != null
                                        ? Image.file(
                                            photoFile!,
                                            fit: BoxFit.cover,
                                          )
                                        : _buildDefaultAvatar(theme)),
                              ),
                            ),
                            // ✅ Kamera ikonu overlay
                            if (uploadedPhotoUrl == null && photoFile == null)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.primary,
                                    border: Border.all(
                                      color: theme.colorScheme.surface,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.shadow.withValues(alpha: AppTheme.alphaMedium / 255.0),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 18,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // ✅ Upload progress indicator
                    if (isUploading) ...[
                      const SizedBox(height: AppTheme.spacingLg),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                          vertical: AppTheme.spacingSm,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: AppTheme.alphaLight / 255.0),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            Text(
                              l10n.uploadingPhoto,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacingXxl * 2),
                    // ✅ İsim Input
                    ModernInputField(
                      controller: nameController,
                      label: l10n.name,
                      hint: l10n.nameHint,
                      textInputAction: TextInputAction.next,
                      validator: (value) => FormValidators.name(value, l10n),
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    // ✅ Biyografi Input
                    ModernInputField(
                      controller: bioController,
                      label: l10n.bioOptional,
                      hint: l10n.bioHint,
                      textInputAction: TextInputAction.done,
                      maxLines: 3,
                      validator: (value) => FormValidators.bio(value, l10n),
                      prefixIcon: Icon(
                        Icons.description_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),
                    // ✅ Hata mesajı göster
                    if (authViewModel.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(
                            color: theme.colorScheme.error.withValues(alpha: AppTheme.alphaMedium / 255.0),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            Expanded(
                              child: Text(
                                authViewModel.error!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                    ],
                    // ✅ Kaydet Butonu
                    FilledButton(
                      onPressed: (isUploading || authViewModel.isLoading) ? null : () async {
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }
                          
                          // ✅ Profil tamamlama işlemini başlat
                          try {
                            final displayName = nameController.text.trim();
                            final bio = bioController.text.trim();
                            
                            if (displayName.isEmpty) {
                              ModernSnackbar.showError(context, l10n.nameRequired);
                              return;
                            }
                            
                            if (kDebugMode) {
                              debugPrint('✅ [COMPLETE_PROFILE] Profil tamamlama başlatılıyor: displayName=$displayName, bio=$bio, photoUrl=$uploadedPhotoUrl');
                            }
                            
                            // ViewModel üzerinden direkt çağır (error handling için)
                            await authViewModel.completeProfile(
                              displayName: displayName,
                              bio: bio.isEmpty ? null : bio,
                              photoUrl: uploadedPhotoUrl,
                            );
                            
                            if (!mounted) return;
                            
                            if (kDebugMode) {
                              debugPrint('✅ [COMPLETE_PROFILE] completeProfile başarılı. needsProfileCompletion=${authViewModel.needsProfileCompletion}');
                            }
                            
                            // ✅ Başarılı oldu - Router otomatik olarak ana sayfaya yönlendirecek
                            // needsProfileCompletion = false olduğu için router redirect yapacak
                            // Ama güvenlik için manuel navigation da ekliyoruz
                            if (!authViewModel.needsProfileCompletion) {
                              if (kDebugMode) {
                                debugPrint('✅ [COMPLETE_PROFILE] Ana sayfaya yönlendiriliyor...');
                              }
                            // Router'ın refreshListenable mekanizması çalışacak ama gecikme olmaması için manuel navigation
                            await Future.delayed(const Duration(milliseconds: 300));
                            if (!mounted) return;
                            if (context.mounted) {
                              context.go('/');
                            }
                            }
                          } catch (e, stackTrace) {
                            if (kDebugMode) {
                              debugPrint('❌ [COMPLETE_PROFILE] Hata: $e');
                              debugPrint('❌ [COMPLETE_PROFILE] Stack trace: $stackTrace');
                            }
                            // Hata zaten ViewModel'de gösteriliyor, ama ekstra snackbar da göster
                            if (mounted) {
                              await Future.delayed(const Duration(milliseconds: 100));
                              if (!mounted) return;
                              final navigatorContext = context;
                              if (navigatorContext.mounted) {
                                final errorMessage = authViewModel.error ?? e.toString();
                                ModernSnackbar.showError(navigatorContext, l10n.profileSaveFailed(errorMessage));
                              }
                            }
                          }
                        },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingXxl,
                          vertical: AppTheme.spacingLg + 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        elevation: 2,
                      ),
                      child: authViewModel.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.saveAndContinue,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingSm),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: AppTheme.spacingXxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 50,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
} 