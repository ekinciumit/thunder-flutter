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
      child: Center(
        child: RefreshIndicator(
          onRefresh: () => _refreshUser(authViewModel),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: AppCard(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                padding: const EdgeInsets.all(24),
                borderRadius: 32,
                gradientColors: [
                  Colors.black.withAlpha(AppTheme.alphaMediumLight),
                  Colors.black.withAlpha(AppTheme.alphaVeryLight),
                ],
                boxShadow: const [], // Gölgeyi kaldır veya özelleştir
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center, // Her şeyi ortala
                  children: [
                    GestureDetector(
                      onTap: isUploading ? null : () => _showPhotoDialog(user.photoUrl, authViewModel),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 64,
                            backgroundColor: Colors.white.withAlpha(AppTheme.alphaVeryLight),
                            child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: user.photoUrl!,
                                      width: 128,
                                      height: 128,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 200,
                                      memCacheHeight: 200,
                                      maxWidthDiskCache: 400,
                                      maxHeightDiskCache: 400,
                                      placeholder: (context, url) => Container(
                                        width: 128,
                                        height: 128,
                                        color: Colors.grey[300],
                                        child: const Center(child: CircularProgressIndicator()),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.person, size: 64, color: Colors.white70),
                                    ),
                                  )
                                : const Icon(Icons.person, size: 64, color: Colors.white70),
                          ),
                          if (isUploading)
                            const Positioned.fill(
                              child: Center(
                                child: ModernLoadingWidget(
                                  size: 32,
                                  message: 'Yükleniyor...',
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: AppTheme.gradientSecondary),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isEditing)
                      _buildEditableTextField(nameController, 'İsim')
                    else
                      Text(
                        user.displayName ?? 'İsim belirtilmemiş',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [const Shadow(blurRadius: 2, color: Colors.black54, offset: Offset(1, 1))],
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (isEditing)
                      _buildEditableTextField(bioController, 'Biyografi', maxLines: 3)
                    else
                      Text(
                        user.bio ?? 'Biyografi yok',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withAlpha(AppTheme.alphaVeryDark),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(AppTheme.alphaVeryLight),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                        border: Border.all(color: Colors.white.withAlpha(AppTheme.alphaMediumLight)),
                      ),
                      child: Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.white.withAlpha(AppTheme.alphaAlmostOpaque),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFollowerStats(user, theme),
                    const SizedBox(height: 24),
                    _buildGradientButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserSearchPage()));
                      },
                      label: 'Kullanıcı Ara',
                      icon: Icons.person_search,
                      gradientColors: AppTheme.gradientSecondary,
                    ),
                    const SizedBox(height: 16),
                    _buildGradientButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyEventsPage()));
                      },
                      label: 'Etkinliklerim',
                      icon: Icons.event_note_rounded,
                      gradientColors: AppTheme.gradientSecondary,
                    ),
                    const SizedBox(height: 16),
                    // Seed/test verisi butonu kaldırıldı
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGradientButton(
                          onPressed: () async {
                            if (isEditing) {
                              await authViewModel.completeProfile(
                                displayName: nameController.text.trim(),
                                bio: bioController.text.trim(),
                                photoUrl: user.photoUrl,
                              );
                              await _refreshUser(authViewModel);
                            }
                            setState(() => isEditing = !isEditing);
                          },
                          label: isEditing ? 'Kaydet' : 'Düzenle',
                          icon: isEditing ? Icons.save : Icons.edit,
                          gradientColors: isEditing
                              ? AppTheme.gradientSuccess
                              : AppTheme.gradientSecondary,
                        ),
                        const SizedBox(width: 16),
                        _buildGradientButton(
                          onPressed: () async => await authViewModel.signOut(),
                          label: 'Çıkış Yap',
                          icon: Icons.logout,
                          gradientColors: [Colors.red.shade600, Colors.pink.shade400],
                        ),
                      ],
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

  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withAlpha((0.4 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFollowerStats(UserModel user, ThemeData theme) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      borderRadius: 20,
      gradientColors: [ // 'color' yerine 'gradientColors' kullan
        Colors.white.withAlpha(AppTheme.alphaLight),
        Colors.white.withAlpha(AppTheme.alphaVeryLight),
      ],
      boxShadow: const [], // Gölgeyi kaldır veya özelleştir
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Takipçi', user.followers.length, theme),
          Container(width: 1, height: 30, color: Colors.white.withAlpha(AppTheme.alphaMediumLight)),
          _buildStatColumn('Takip', user.following.length, theme),
        ],
      ),
    );
  }

  Column _buildStatColumn(String label, int count, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold, 
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
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