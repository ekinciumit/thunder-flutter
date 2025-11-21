import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'user_search_page.dart';
import 'my_events_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'widgets/app_card.dart';
import 'widgets/app_gradient_container.dart';
import 'widgets/modern_loading_widget.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_color_config.dart';
import '../core/widgets/modern_components.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
// Removed seed data service as test data seeding is no longer needed.

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with SingleTickerProviderStateMixin {
  bool isUploading = false;
  bool isEditing = false;
  double uploadProgress = 0.0;
  late TextEditingController nameController;
  late TextEditingController bioController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = authViewModel.user;
    nameController = TextEditingController(text: user?.displayName ?? '');
    bioController = TextEditingController(text: user?.bio ?? '');
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnimation = CurvedAnimation(parent: _animationController, curve: Curves.elasticOut);
    _animationController.forward();
    // Kullanıcı profilini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authViewModel.loadUserProfile();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  // Resim boyutunu küçült ve sıkıştır
  Future<Uint8List> _compressImage(String imagePath) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: 300, // Profil fotoğrafı için 300x300 yeterli
      targetHeight: 300,
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _changePhoto(AuthViewModel authViewModel) async {
    if (!mounted) return;
    
    try {
      // Önce galeri veya kamera seçimi göster
      final source = await ModernDialog.showImageSource(
        context: context,
        title: 'Fotoğraf Seç',
      );
      
      if (source == null || !mounted) return;
      
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source, 
        imageQuality: 90,
      );
      
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
          ModernSnackbar.showError(
            context,
            'Fotoğraf kırpma hatası: ${e.toString()}',
          );
        }
        return;
      }
      
      if (croppedFile == null || !mounted) return; // Kullanıcı kırpmayı iptal etti
      
      final croppedFileObj = File(croppedFile.path);
      if (!mounted) return;
      
      setState(() { 
        isUploading = true; 
        uploadProgress = 0.0;
      });
      
      // Progress dialog göster
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          title: const Text('Yükleniyor...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('${(uploadProgress * 100).toStringAsFixed(0)}%'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: uploadProgress),
            ],
          ),
        ),
      );
      
      try {
        // Resmi sıkıştır (kırpılmış dosyayı kullan)
        final compressedBytes = await _compressImage(croppedFileObj.path);
        
        if (!mounted) {
          Navigator.of(context).pop(); // Progress dialog'u kapat
          return;
        }
        
        final fileName = 'profile_${authViewModel.user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child('profile_photos').child(fileName);
        
        // Sıkıştırılmış resmi yükle
        final uploadTask = ref.putData(compressedBytes);
        
        // Upload progress göster
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          if (mounted) {
            setState(() {
              uploadProgress = progress;
            });
          }
        });
        
        await uploadTask;
        final url = await ref.getDownloadURL();
        
        if (!mounted) {
          Navigator.of(context).pop(); // Progress dialog'u kapat
          return;
        }
        
        // Profil güncellemesini yap, ama sayfa değişikliğini geciktir
        await authViewModel.completeProfile(
          displayName: authViewModel.user!.displayName ?? '',
          bio: authViewModel.user!.bio,
          photoUrl: url,
        );
        
        if (mounted) {
          Navigator.of(context).pop(); // Progress dialog'u kapat
          setState(() { isUploading = false; });
          
          // Sayfa değişikliğini geciktir (activity result işlensin)
          await Future.delayed(const Duration(milliseconds: 300));
          
          if (mounted) {
            ModernSnackbar.showSuccess(
              context,
              'Profil fotoğrafı başarıyla güncellendi!',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Progress dialog'u kapat
          setState(() { isUploading = false; });
          ModernSnackbar.showError(
            context,
            'Hata: ${e.toString()}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { isUploading = false; });
        ModernSnackbar.showError(
          context,
          'Fotoğraf seçme hatası: ${e.toString()}',
        );
      }
    }
  }

  void _showPhotoDialog(String? photoUrl, AuthViewModel authViewModel) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photoUrl != null && photoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  width: 280,
                  height: 280,
                  memCacheWidth: 300, // Memory cache boyutu
                  memCacheHeight: 300,
                  maxWidthDiskCache: 600, // Disk cache boyutu
                  maxHeightDiskCache: 600,
                  placeholder: (context, url) => Container(
                    width: 280,
                    height: 280,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 280,
                    height: 280,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 90, color: Colors.grey),
                  ),
                ),
              )
            else
              const CircleAvatar(radius: 90, child: Icon(Icons.person, size: 90)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: isUploading ? null : () async {
                Navigator.of(context).pop();
                await _changePhoto(authViewModel);
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Yeni Fotoğraf Yükle'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshUser(AuthViewModel authViewModel) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(authViewModel.user!.uid).get();
    if (doc.exists) {
      final updatedUser = UserModel.fromMap(doc.data()!, doc.id);
      setState(() {
        authViewModel.user = updatedUser;
        nameController.text = updatedUser.displayName ?? '';
        bioController.text = updatedUser.bio ?? '';
      });
    }
  }

  // Removed seeding UI and logic.

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.user;
    final theme = Theme.of(context);

    if (authViewModel.isLoading) {
      return Center(child: ModernLoadingWidget(message: 'Yükleniyor...'));
    }
    if (user == null) {
      return Center(child: ModernLoadingWidget(message: 'Kullanıcı bilgisi yükleniyor...'));
    }

    return AppGradientContainer(
      gradientColors: AppTheme.gradientPrimary,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => _refreshUser(authViewModel),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                MediaQuery.of(context).padding.top + AppTheme.spacingMd,
                AppTheme.spacingMd,
                AppTheme.spacingXl + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppTheme.spacingMd),
              // Profile Header Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.surface,
                        theme.colorScheme.surfaceContainerHighest,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  padding: const EdgeInsets.all(AppTheme.spacingXl),
                  child: Column(
                    children: [
                      // Profile Photo
                      GestureDetector(
                        onTap: isUploading ? null : () => _showPhotoDialog(user.photoUrl, authViewModel),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColorConfig.primaryColor.withAlpha(AppTheme.alphaMedium),
                                  width: 3,
                                ),
                                boxShadow: [
                                  AppTheme.shadowMedium(
                                    color: AppColorConfig.primaryColor.withAlpha(AppTheme.alphaMedium),
                                  ),
                                ],
                              ),
                              child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: user.photoUrl!,
                                        fit: BoxFit.cover,
                                        memCacheWidth: 200,
                                        memCacheHeight: 200,
                                        placeholder: (context, url) => Container(
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          child: const Center(child: CircularProgressIndicator()),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          child: Icon(
                                            Icons.person,
                                            size: 60,
                                            color: AppColorConfig.primaryColor,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: AppColorConfig.primaryColor.withAlpha(AppTheme.alphaVeryLight),
                                      child: Icon(
                                        Icons.person,
                                        size: 60,
                                        color: AppColorConfig.primaryColor,
                                      ),
                                    ),
                            ),
                            if (isUploading)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(AppTheme.alphaMedium),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: AppTheme.gradientSecondary,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    AppTheme.shadowSoft(
                                      color: AppColorConfig.tertiaryColor.withAlpha(AppTheme.alphaMedium),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      // Name
                      if (isEditing)
                        _buildEditableTextField(nameController, 'İsim')
                      else
                        Text(
                          user.displayName ?? 'İsim belirtilmemiş',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      const SizedBox(height: AppTheme.spacingXs),
                      // Bio
                      if (isEditing)
                        _buildEditableTextField(bioController, 'Biyografi', maxLines: 3)
                      else
                        Text(
                          user.bio ?? 'Biyografi yok',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: AppTheme.spacingMd),
                      // Email
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                          vertical: AppTheme.spacingSm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColorConfig.primaryColor.withAlpha(AppTheme.alphaVeryLight),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(
                            color: AppColorConfig.primaryColor.withAlpha(AppTheme.alphaMedium),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: AppColorConfig.primaryColor,
                            ),
                            const SizedBox(width: AppTheme.spacingXs),
                            Text(
                              user.email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColorConfig.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              // Stats Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: theme.colorScheme.outline.withAlpha(AppTheme.alphaVeryLight),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Takipçi', user.followers.length, theme),
                      Container(
                        width: 1,
                        height: 40,
                        color: theme.colorScheme.outline.withAlpha(AppTheme.alphaVeryLight),
                      ),
                      _buildStatColumn('Takip', user.following.length, theme),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              // Action Buttons
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UserSearchPage()),
                  );
                },
                icon: const Icon(Icons.person_search),
                label: const Text('Kullanıcı Ara'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColorConfig.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXl,
                    vertical: AppTheme.spacingMd,
                  ),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyEventsPage()),
                  );
                },
                icon: const Icon(Icons.event_note_rounded),
                label: const Text('Etkinliklerim'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColorConfig.tertiaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXl,
                    vertical: AppTheme.spacingMd,
                  ),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              // Edit and Logout Buttons
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        if (isEditing) {
                          await authViewModel.completeProfile(
                            displayName: nameController.text.trim(),
                            bio: bioController.text.trim(),
                            photoUrl: user.photoUrl,
                          );
                          await _refreshUser(authViewModel);
                          if (mounted) {
                            ModernSnackbar.showSuccess(
                              context,
                              'Profil başarıyla güncellendi!',
                            );
                          }
                        }
                        setState(() => isEditing = !isEditing);
                      },
                      icon: Icon(isEditing ? Icons.save : Icons.edit),
                      label: Text(isEditing ? 'Kaydet' : 'Düzenle'),
                      style: FilledButton.styleFrom(
                        backgroundColor: isEditing
                            ? AppColorConfig.successColor
                            : AppColorConfig.tertiaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                          vertical: AppTheme.spacingMd,
                        ),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async => await authViewModel.signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Çıkış Yap'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColorConfig.errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                          vertical: AppTheme.spacingMd,
                        ),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildStatColumn(String label, int count, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColorConfig.primaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return ModernInputField(
      controller: controller,
      label: label,
      maxLines: maxLines,
    );
  }
} 