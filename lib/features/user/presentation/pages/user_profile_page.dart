import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:ui' as ui;
import '../../../../features/user/domain/entities/user_entity.dart';
import '../../../../features/event/domain/entities/event_entity.dart';
import '../../../../views/widgets/user_suggestions_widget.dart';
import '../../../../views/widgets/app_gradient_container.dart';
import '../../../../core/widgets/modern_components.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../core/widgets/skeleton_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../services/user_service.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../features/event/presentation/viewmodels/event_viewmodel.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserProfilePage extends StatefulWidget {
  final UserEntity user;
  final String currentUserId;
  const UserProfilePage({super.key, required this.user, required this.currentUserId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final UserService _userService = UserService();
  bool isMutualFollow = false; // Karşılıklı takip
  bool hasSentRequest = false; // Takip isteği gönderilmiş
  bool hasPendingRequest = false; // Bekleyen takip isteği var
  int followersCount = 0;
  int followingCount = 0;
  int eventsCount = 0;
  bool isKesfetVisible = true; // Keşfet bölümü görünürlüğü (başlangıçta görünür)
  UserEntity? _currentUser;
  StreamSubscription<UserEntity?>? _userStreamSubscription;
  StreamSubscription<UserEntity?>? _currentUserStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Clean Architecture: AuthViewModel üzerinden user işlemleri
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    
    // Mevcut kullanıcıyı getir
    final userEntity = await authViewModel.fetchUserProfile(widget.currentUserId);
    // UI direkt Entity kullanıyor (Clean Architecture)
    _currentUser = userEntity;
    if (_currentUser != null && mounted) {
      setState(() {});
    }

    // Kullanıcı verilerini stream ile dinle (AuthViewModel üzerinden)
    // Not: AuthViewModel'de user stream yok, bu yüzden getAllUsersStream kullanıp filtreleyeceğiz
    // ViewModel Entity döndürüyor, UI Model kullanıyor - dönüşüm yapıyoruz
    _userStreamSubscription = authViewModel.getAllUsersStream()
        .map((userEntities) {
          return userEntities.firstWhere(
            (u) => u.uid == widget.user.uid,
            orElse: () => widget.user,
          );
        })
        .listen((user) {
      if (mounted) {
        _updateFollowStatus(user);
      }
    });

    // Mevcut kullanıcı verilerini de dinle
    _currentUserStreamSubscription = authViewModel.getAllUsersStream()
        .map((userEntities) {
          try {
            return userEntities.firstWhere((u) => u.uid == widget.currentUserId);
          } catch (_) {
            return _currentUser;
          }
        })
        .where((user) => user != null)
        .cast<UserEntity?>()
        .listen((user) {
      if (mounted) {
        _currentUser = user;
        _updateFollowStatus(widget.user);
      }
    });

    // Etkinlik sayısını al (EventViewModel üzerinden)
    final userEventsStream = eventViewModel.getUserEventsStream(widget.user.uid);
    try {
      final events = await userEventsStream.first;
      if (mounted) {
        setState(() {
          eventsCount = events.length;
        });
      }
    } catch (e) {
      // Stream hatası - sessizce devam et
      if (mounted) {
        setState(() {
          eventsCount = 0;
        });
      }
    }
  }

  void _updateFollowStatus(UserEntity targetUser) {
    if (_currentUser == null) return;

    final isCurrentFollowingTarget = _currentUser!.following.contains(targetUser.uid);
    final isTargetFollowingCurrent = targetUser.followers.contains(widget.currentUserId);
    
    setState(() {
      isMutualFollow = isCurrentFollowingTarget && isTargetFollowingCurrent;
      hasSentRequest = _currentUser!.sentFollowRequests.contains(targetUser.uid);
      hasPendingRequest = targetUser.pendingFollowRequests.contains(widget.currentUserId);
      followersCount = targetUser.followers.length;
      followingCount = targetUser.following.length;
    });
  }

  Future<void> _handleFollowAction() async {
    try {
      if (isMutualFollow) {
        // Takibi bırak
        await _userService.unfollowUser(widget.currentUserId, widget.user.uid);
        if (mounted) {
          ModernSnackbar.showSuccess(context, 'Takip bırakıldı');
        }
      } else if (hasSentRequest) {
        // İsteği iptal et
        await _userService.cancelFollowRequest(widget.currentUserId, widget.user.uid);
        if (mounted) {
          ModernSnackbar.showSuccess(context, 'Takip isteği iptal edildi');
        }
      } else {
        // Takip isteği gönder
        await _userService.sendFollowRequest(widget.currentUserId, widget.user.uid);
        if (mounted) {
          ModernSnackbar.showSuccess(context, 'Takip isteği gönderildi');
        }
      }
    } catch (e) {
      if (mounted) {
        ModernSnackbar.showError(context, 'Bir hata oluştu: ${e.toString()}');
      }
    }
  }

  Stream<List<EventEntity>> _userEventsStream() {
    // Clean Architecture: EventViewModel üzerinden user events stream
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    // ViewModel Entity döndürüyor, UI direkt Entity kullanıyor (Clean Architecture)
    return eventViewModel.getUserEventsStream(widget.user.uid);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AppGradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              MediaQuery.of(context).padding.top,
              AppTheme.spacingMd,
              AppTheme.spacingXl + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Geri Butonu (Sol Üst - Profil fotoğrafının dışında)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 0,
                    bottom: AppTheme.spacingMd,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? theme.colorScheme.surface.withValues(alpha: 0.9)
                            : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: theme.brightness == Brightness.dark
                            ? AppColorConfig.cardColor
                            : Colors.black,
                        size: 20,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                // Instagram tarzı üst kısım - Profil fotoğrafı ve istatistikler yan yana
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                  child: Row(
                    children: [
                      // Profil Fotoğrafı
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: AppTheme.alphaMedium / 255.0),
                            width: 2,
                          ),
                        ),
                        child: widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: widget.user.photoUrl!,
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
                                color: AppColorConfig.primaryColor.withValues(alpha: AppTheme.alphaVeryLight / 255.0),
                                child: Icon(
                                  Icons.person,
                                  size: 45,
                                  color: AppColorConfig.primaryColor,
                                ),
                              ),
                      ),
                      const SizedBox(width: AppTheme.spacingLg),
                      // İstatistikler
                      Expanded(
                        child: StreamBuilder<List<EventEntity>>(
                          stream: _userEventsStream(),
                          builder: (context, snapshot) {
                            if (!mounted) {
                              return const SizedBox.shrink();
                            }
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
                                  followersCount,
                                  theme,
                                  () {
                                    AppNavigation.toFollowers(context: context, userId: widget.user.uid);
                                  },
                                ),
                                _buildStatColumn(
                                  l10n.following,
                                  followingCount,
                                  theme,
                                  () {
                                    AppNavigation.toFollowing(context: context, userId: widget.user.uid);
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
                      Text(
                        widget.user.displayName ?? l10n.user,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColorConfig.cardColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      if (widget.user.bio != null && widget.user.bio!.isNotEmpty)
                        Text(
                          widget.user.bio!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColorConfig.cardColor.withValues(alpha: 0.78),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                // Mesaj Yaz ve Arkadaş Ekle Butonları
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            AppNavigation.toChat(
                              context: context,
                              currentUserId: widget.currentUserId,
                              currentUserName: _currentUser?.displayName ?? 'Kullanıcı',
                              otherUserId: widget.user.uid,
                              otherUserName: widget.user.displayName ?? 'Kullanıcı',
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: Text(l10n.startChat),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColorConfig.cardColor,
                            side: const BorderSide(color: AppColorConfig.cardColor, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _handleFollowAction,
                          icon: Icon(
                            hasSentRequest
                                ? Icons.check_circle_outline_rounded
                                : isMutualFollow
                                    ? Icons.person_remove_outlined
                                    : Icons.person_add_outlined,
                            size: 18,
                          ),
                          label: Text(
                            hasSentRequest
                                ? 'İstek Gönderildi'
                                : isMutualFollow
                                    ? l10n.unfollow
                                    : 'Arkadaş Ekle',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: hasSentRequest
                                ? theme.colorScheme.surfaceContainerHighest
                                : isMutualFollow
                                    ? theme.colorScheme.errorContainer
                                    : AppColorConfig.primaryColor,
                            foregroundColor: hasSentRequest
                                ? theme.colorScheme.onSurface
                                : isMutualFollow
                                    ? theme.colorScheme.onErrorContainer
                                    : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                        ),
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
                                  color: AppColorConfig.cardColor,
                                ),
                              ),
                            ),
                            // Keşfet içeriği
                            UserSuggestionsWidget(
                              currentUserId: widget.currentUserId,
                              followingIds: widget.user.following,
                              followersIds: widget.user.followers,
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
                              color: AppColorConfig.cardColor,
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
                StreamBuilder<List<EventEntity>>(
                  stream: _userEventsStream(),
                  builder: (context, snapshot) {
                    if (!mounted) {
                      return const SizedBox.shrink();
                    }
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 200,
                        child: EventListSkeleton(itemCount: 2),
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
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: AppTheme.alphaMedium / 255.0),
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            Text(
                              l10n.noData,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Dikey liste görünümü
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      itemCount: events.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingMd),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return GestureDetector(
                          onTap: () {
                            AppNavigation.toEventDetail(context: context, event: event);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(
                                sigmaX: theme.brightness == Brightness.dark ? 10 : 0,
                                sigmaY: theme.brightness == Brightness.dark ? 10 : 0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                                  color: theme.brightness == Brightness.dark
                                      ? theme.colorScheme.surface.withValues(alpha: 0.1)
                                      : theme.colorScheme.surface.withValues(alpha: 0.9),
                                  border: Border.all(
                                    color: theme.brightness == Brightness.dark
                                        ? theme.colorScheme.outline.withValues(alpha: 0.2)
                                        : theme.colorScheme.outline.withValues(alpha: 0.1),
                                    width: 1.0,
                                  ),
                                  boxShadow: theme.brightness == Brightness.dark
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 20,
                                            offset: const Offset(0, 5),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Etkinlik başlığı
                                    Padding(
                                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                                      child: Text(
                                        event.title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColorConfig.cardColor,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Etkinlik görseli
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(AppTheme.radiusXl),
                                        bottomRight: Radius.circular(AppTheme.radiusXl),
                                      ),
                                      child: event.coverPhotoUrl != null && event.coverPhotoUrl!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: event.coverPhotoUrl!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: 200,
                                              memCacheWidth: 600,
                                              memCacheHeight: 400,
                                              placeholder: (context, url) => Container(
                                                height: 200,
                                                color: theme.colorScheme.surfaceContainerHighest,
                                                child: const Center(
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                height: 200,
                                                color: theme.colorScheme.surfaceContainerHighest,
                                                child: Icon(
                                                  Icons.event_note_rounded,
                                                  size: 48,
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              height: 200,
                                              color: theme.colorScheme.surfaceContainerHighest,
                                              child: Icon(
                                                Icons.event_note_rounded,
                                                size: 48,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
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
              color: AppColorConfig.cardColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColorConfig.cardColor.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _userStreamSubscription?.cancel();
    _currentUserStreamSubscription?.cancel();
    super.dispose();
  }
}
