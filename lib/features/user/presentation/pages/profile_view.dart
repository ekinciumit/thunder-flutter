import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../features/event/presentation/viewmodels/event_viewmodel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import '../widgets/user_suggestions_widget.dart';
import '../../../../features/event/domain/entities/event_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/profile_events_section.dart';
import '../../../../core/widgets/app_gradient_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../core/widgets/modern_components.dart';
import '../../../../core/widgets/skeleton_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/navigation/app_navigation.dart';
// Removed seed data service as test data seeding is no longer needed.

/// Helper class for Selector optimization
class _AuthViewModelState {
  final dynamic user;
  final bool isLoading;
  
  _AuthViewModelState({
    required this.user,
    required this.isLoading,
  });
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with SingleTickerProviderStateMixin {
  bool isUploading = false;
  bool isEditing = false;
  double uploadProgress = 0.0;
  bool isKesfetVisible = true; // Keşfet bölümü görünürlüğü (başlangıçta görünür)
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
    // ✅ Kullanıcı profilini yükle (sadece displayName yoksa veya boşsa)
    // Gereksiz yere her seferinde yüklemeyi önlemek için kontrol ekle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && authViewModel.user != null) {
        // Sadece displayName yoksa veya boşsa yükle (zaten yüklenmiş olabilir)
        final currentUser = authViewModel.user;
        if (currentUser?.displayName == null || currentUser!.displayName!.isEmpty) {
          authViewModel.loadUserProfile();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    bioController.dispose();
    super.dispose();
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
          title: Text(AppLocalizations.of(context)!.loading),
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
      
      // Context'i async öncesi sakla
      if (!mounted) return;
      final currentContext = context;
      final navigator = Navigator.of(currentContext);
      
      try {
        if (authViewModel.user == null) {
          if (mounted) {
            navigator.pop();
          }
          return;
        }
        
        // Clean Architecture: ViewModel üzerinden yükle
        final url = await authViewModel.uploadProfilePhoto(croppedFileObj.path);
        
        if (!mounted) return;
        navigator.pop(); // Progress dialog'u kapat
        
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
              label: Text(AppLocalizations.of(context)!.uploadNewPhoto),
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
    // Clean Architecture: AuthViewModel üzerinden user refresh
    await authViewModel.refreshUserProfile();
    if (authViewModel.user != null) {
      setState(() {
        nameController.text = authViewModel.user!.displayName ?? '';
        bioController.text = authViewModel.user!.bio ?? '';
        isKesfetVisible = true; // Refresh'te Keşfet bölümünü tekrar göster
      });
    }
  }

  // Removed seeding UI and logic.

  Stream<List<EventEntity>> _getUserEventsStream(String userId) {
    // Clean Architecture: EventViewModel üzerinden user events stream
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    // ViewModel Entity döndürüyor
    return eventViewModel.getUserEventsStream(userId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final overlayText = AppColorConfig.getOverlayTextPrimary(brightness);
    final overlayTextSecondary = AppColorConfig.getOverlayTextSecondary(brightness);
    final overlayAccent = AppColorConfig.getOverlayAccent(brightness);
    final overlayBorder = AppColorConfig.getOverlayBorder(brightness);
    final l10n = AppLocalizations.of(context)!;
    
    try {
      // Selector kullanarak sadece user ve isLoading değiştiğinde rebuild yap
      return Selector<AuthViewModel, _AuthViewModelState>(
      selector: (_, vm) => _AuthViewModelState(
        user: vm.user,
        isLoading: vm.isLoading,
      ),
      shouldRebuild: (previous, next) {
        // ✅ User değişikliklerini kontrol et (uid, displayName, bio, photoUrl)
        final prevUser = previous.user;
        final nextUser = next.user;
        
        // User null durumları
        if (prevUser == null && nextUser == null) {
          return previous.isLoading != next.isLoading;
        }
        if (prevUser == null || nextUser == null) {
          return true; // User null'dan non-null'a veya tersi
        }
        
        // ✅ User bilgileri değişti mi kontrol et
        final userChanged = prevUser.uid != nextUser.uid ||
                           prevUser.displayName != nextUser.displayName ||
                           prevUser.bio != nextUser.bio ||
                           prevUser.photoUrl != nextUser.photoUrl;
        
        return userChanged || previous.isLoading != next.isLoading;
      },
      builder: (context, authState, _) {
        if (kDebugMode) {
          debugPrint('🔵 [PROFILEVIEW] Building ProfileView - User: ${authState.user?.uid}, isLoading: ${authState.isLoading}');
        }

        if (authState.isLoading || authState.user == null) {
          if (kDebugMode) {
            debugPrint('🔵 [PROFILEVIEW] Showing skeleton');
          }
          return const ProfileSkeleton();
        }

        if (kDebugMode) {
          debugPrint('✅ [PROFILEVIEW] Building full ProfileView');
        }
        
        final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
        final user = authState.user;
        
        // ✅ User değiştiğinde controller'ları güncelle
        // Bu, completeProfile sonrası veya profil refresh sonrası çalışır
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && user != null) {
            final currentDisplayName = nameController.text;
            final currentBio = bioController.text;
            final newDisplayName = user.displayName ?? '';
            final newBio = user.bio ?? '';
            
            // Sadece değiştiyse güncelle (sonsuz döngüyü önlemek için)
            if (currentDisplayName != newDisplayName || currentBio != newBio) {
              if (kDebugMode) {
                debugPrint('✅ [PROFILEVIEW] Controller\'lar güncelleniyor: displayName=$newDisplayName, bio=$newBio');
              }
              setState(() {
                nameController.text = newDisplayName;
                bioController.text = newBio;
              });
            }
          }
        });

        return AppGradientContainer(
          backgroundImagePath: brightness == Brightness.dark
              ? 'assets/backgrounds/background_2.png'
              : null,
          backgroundOpacity: 0.7,
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
                      onLongPress: () {
                        // Uzun basınca profil sayfasına geç
                        AppNavigation.toUserProfile(context: context, userId: user.uid);
                      },
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
                          child: StreamBuilder<List<EventEntity>>(
                            stream: _getUserEventsStream(user.uid),
                            builder: (context, snapshot) {
                              final eventsCount = snapshot.hasData ? snapshot.data!.length : 0;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatColumn(
                                    l10n.events,
                                    eventsCount,
                                    theme,
                                    null,
                                  ),
                                  _buildStatColumn(
                                    l10n.followers,
                                    user.followers.length,
                                    theme,
                                    () {
                                      AppNavigation.toFollowers(context: context, userId: user.uid);
                                    },
                                  ),
                                  _buildStatColumn(
                                    l10n.following,
                                    user.following.length,
                                    theme,
                                    () {
                                      AppNavigation.toFollowing(context: context, userId: user.uid);
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
                      _buildEditableTextField(nameController, l10n.name)
                    else
                      GestureDetector(
                        onTap: () {
                          // Kendi profil sayfasına geç
                          AppNavigation.toUserProfile(context: context, userId: user.uid);
                        },
                        child: Text(
                          user.displayName ?? l10n.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: overlayText,
                          ),
                        ),
                      ),
                        const SizedBox(height: AppTheme.spacingXs),
                    if (isEditing)
                      _buildEditableTextField(bioController, l10n.bio, maxLines: 3)
                        else if (user.bio != null && user.bio!.isNotEmpty)
                      Text(
                            user.bio!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: overlayTextSecondary,
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
                              if (!mounted) return;
                              await authViewModel.completeProfile(
                                displayName: nameController.text.trim(),
                                bio: bioController.text.trim(),
                                photoUrl: user.photoUrl,
                              );
                              await _refreshUser(authViewModel);
                              if (!mounted) return;
                              ModernSnackbar.showSuccess(
                                context,
                                'Profil başarıyla güncellendi!',
                              );
                            }
                            setState(() => isEditing = !isEditing);
                          },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: overlayAccent,
                              side: BorderSide(color: overlayBorder, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                            ),
                            child: Text(isEditing ? l10n.save : l10n.edit),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingXs),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              AppNavigation.toUserSearch(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: overlayAccent,
                              side: BorderSide(color: overlayBorder, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                            ),
                            child: Text(l10n.searchUsers),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingXs),
                        OutlinedButton(
                          onPressed: () {
                            AppNavigation.toSettings(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: overlayAccent,
                            side: BorderSide(color: overlayBorder, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                          child: const Icon(Icons.settings, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  // User Suggestions (Keşfet) - Üstte
                  if (isKesfetVisible)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Keşfet başlığı
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppTheme.spacingMd,
                                  bottom: AppTheme.spacingMd,
                                ),
                                child: Text(
                                  'Keşfet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: overlayText,
                                  ),
                                ),
                              ),
                              // Keşfet içeriği
                              UserSuggestionsWidget(
                                currentUserId: user.uid,
                                followingIds: user.following,
                                followersIds: user.followers,
                                isExpanded: true,
                              ),
                            ],
                          ),
                          // X butonu (sağ üst köşe)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  isKesfetVisible = false;
                                });
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                color: overlayText,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                shape: const CircleBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Ayırıcı çizgi (sadece Keşfet görünürken)
                  if (isKesfetVisible) ...[
                    const SizedBox(height: AppTheme.spacingLg),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      child: Divider(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        thickness: 1,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                  ] else
                    const SizedBox(height: AppTheme.spacingLg),
                  // Etkinliklerim - Dikey Liste
                  ProfileEventsSection(
                    eventsStream: _getUserEventsStream(user.uid),
                    theme: theme,
                    l10n: l10n,
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
      },
    );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [PROFILEVIEW] Build error: $e');
        debugPrint('❌ [PROFILEVIEW] Stack trace: $stackTrace');
      }
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.error)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e'),
            ],
          ),
        ),
      );
    }
  }


  Widget _buildStatColumn(String label, int count, ThemeData theme, VoidCallback? onTap) {
    final brightness = theme.brightness;
    final overlayText = AppColorConfig.getOverlayTextPrimary(brightness);
    final overlayTextSecondary = AppColorConfig.getOverlayTextSecondary(brightness);
    return GestureDetector(
      onTap: onTap,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
            style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold, 
              color: overlayText,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: overlayTextSecondary,
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