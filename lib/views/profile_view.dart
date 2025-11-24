import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'user_search_page.dart';
import 'followers_following_page.dart';
import 'widgets/user_suggestions_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import 'event_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = authViewModel.user;
    nameController = TextEditingController(text: user?.displayName ?? '');
    bioController = TextEditingController(text: user?.bio ?? '');
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
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
          // ignore: use_build_context_synchronously
          final currentContext = context;
          Navigator.of(currentContext).pop(); // Progress dialog'u kapat
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
          // ignore: use_build_context_synchronously
          final currentContext = context;
          Navigator.of(currentContext).pop(); // Progress dialog'u kapat
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

  Stream<List<EventModel>> _getUserEventsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('events')
        .where('createdBy', isEqualTo: userId)
        .orderBy('datetime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return EventModel.fromMap(data, doc.id);
            }).toList());
  }

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instagram tarzı üst kısım - Profil fotoğrafı ve istatistikler yan yana
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                    child: Row(
                  children: [
                        // Profil Fotoğrafı
                    GestureDetector(
                      onTap: isUploading ? null : () => _showPhotoDialog(user.photoUrl, authViewModel),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withAlpha(AppTheme.alphaMedium),
                                    width: 2,
                                  ),
                                ),
                            child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: user.photoUrl!,
                                      fit: BoxFit.cover,
                                          memCacheWidth: 180,
                                          memCacheHeight: 180,
                                      placeholder: (context, url) => Container(
                                            color: theme.colorScheme.surfaceContainerHighest,
                                        child: const Center(child: CircularProgressIndicator()),
                                      ),
                                          errorWidget: (context, url, error) => Container(
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            child: Icon(
                                              Icons.person,
                                              size: 45,
                                              color: AppColorConfig.primaryColor,
                                            ),
                                          ),
                                    ),
                                  )
                                    : Container(
                                        color: AppColorConfig.primaryColor.withAlpha(AppTheme.alphaVeryLight),
                                        child: Icon(
                                          Icons.person,
                                          size: 45,
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
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: AppTheme.gradientSecondary,
                                      ),
                                shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.surface,
                                        width: 2,
                                      ),
                              ),
                                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                  ),
                            ),
                        ],
                      ),
                    ),
                        const SizedBox(width: AppTheme.spacingLg),
                        // İstatistikler
                        Expanded(
                          child: StreamBuilder<List<EventModel>>(
                            stream: _getUserEventsStream(user.uid),
                            builder: (context, snapshot) {
                              final eventsCount = snapshot.hasData ? snapshot.data!.length : 0;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatColumn(
                                    'Etkinlik',
                                    eventsCount,
                                    theme,
                                    null,
                                  ),
                                  _buildStatColumn(
                                    'Takipçi',
                                    user.followers.length,
                                    theme,
                                    () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => FollowersFollowingPage(
                                            userId: user.uid,
                                            showFollowers: true,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildStatColumn(
                                    'Takip',
                                    user.following.length,
                                    theme,
                                    () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => FollowersFollowingPage(
                                            userId: user.uid,
                                            showFollowers: false,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  // İsim ve Bio
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    if (isEditing)
                      _buildEditableTextField(nameController, 'İsim')
                    else
                      Text(
                        user.displayName ?? 'İsim belirtilmemiş',
                            style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                        ),
                      ),
                        const SizedBox(height: AppTheme.spacingXs),
                    if (isEditing)
                      _buildEditableTextField(bioController, 'Biyografi', maxLines: 3)
                        else if (user.bio != null && user.bio!.isNotEmpty)
                      Text(
                            user.bio!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  // Düzenle Butonu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                          onPressed: () async {
                            if (isEditing) {
                              await authViewModel.completeProfile(
                                displayName: nameController.text.trim(),
                                bio: bioController.text.trim(),
                                photoUrl: user.photoUrl,
                              );
                              await _refreshUser(authViewModel);
                                if (!mounted) return;
                                // ignore: use_build_context_synchronously
                                final currentContext = context;
                                ModernSnackbar.showSuccess(
                                  currentContext,
                                  'Profil başarıyla güncellendi!',
                                );
                            }
                            setState(() => isEditing = !isEditing);
                          },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                            ),
                            child: Text(isEditing ? 'Kaydet' : 'Düzenle'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingXs),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const UserSearchPage()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                            ),
                            child: const Text('Kullanıcı Ara'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingXs),
                        OutlinedButton(
                          onPressed: () async => await authViewModel.signOut(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                          child: const Icon(Icons.logout, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  // Etkinlikler Grid (Instagram tarzı)
                  StreamBuilder<List<EventModel>>(
                    stream: _getUserEventsStream(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppTheme.spacingXl),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final events = snapshot.data ?? [];

                      if (events.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingXl),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_note_rounded,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant.withAlpha(AppTheme.alphaMedium),
                              ),
                              const SizedBox(height: AppTheme.spacingMd),
                              Text(
                                'Henüz etkinlik oluşturmadınız',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Grid görünümü (3 sütun)
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tab bar (Instagram tarzı)
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: theme.colorScheme.outline.withAlpha(AppTheme.alphaVeryLight),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: AppColorConfig.primaryColor,
                                          width: 2,
                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.grid_on_rounded,
                                      color: AppColorConfig.primaryColor,
                                    ),
                                  ),
                    ),
                  ],
                ),
                          ),
                          // Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(1),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                              childAspectRatio: 1,
                            ),
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              final event = events[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EventDetailPage(event: event),
                                    ),
                                  );
                                },
                                child: Container(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: event.coverPhotoUrl != null && event.coverPhotoUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: event.coverPhotoUrl!,
                                          fit: BoxFit.cover,
                                          memCacheWidth: 300,
                                          memCacheHeight: 300,
                                          placeholder: (context, url) => Container(
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            child: const Center(
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            child: Icon(
                                              Icons.event_note_rounded,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          child: Icon(
                                            Icons.event_note_rounded,
                                            size: 40,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  // User Suggestions
                  UserSuggestionsWidget(
                    currentUserId: user.uid,
                    followingIds: user.following,
                    followersIds: user.followers,
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


  Widget _buildStatColumn(String label, int count, ThemeData theme, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
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