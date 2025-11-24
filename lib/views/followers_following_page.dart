import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../services/user_service.dart';
import 'user_profile_page.dart';
import 'widgets/app_gradient_container.dart';
import 'widgets/modern_loading_widget.dart';
import '../core/widgets/modern_components.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_color_config.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FollowersFollowingPage extends StatefulWidget {
  final String userId;
  final bool showFollowers; // true = Takipçiler, false = Takip Edilenler

  const FollowersFollowingPage({
    super.key,
    required this.userId,
    required this.showFollowers,
  });

  @override
  State<FollowersFollowingPage> createState() => _FollowersFollowingPageState();
}

class _FollowersFollowingPageState extends State<FollowersFollowingPage> {
  final UserService _userService = UserService();

  Stream<List<UserModel>> _getUsersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (!snapshot.exists) return [];
      
      final userData = snapshot.data()!;
      final userIds = widget.showFollowers
          ? List<String>.from(userData['followers'] ?? [])
          : List<String>.from(userData['following'] ?? []);

      if (userIds.isEmpty) return [];

      // Her kullanıcı için bilgileri çek
      final users = <UserModel>[];
      for (final id in userIds) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(id)
            .get();
        if (userDoc.exists) {
          users.add(UserModel.fromMap(userDoc.data()!, userDoc.id));
        }
      }
      return users;
    });
  }

  Future<void> _toggleFollow(String targetUserId, UserModel targetUser, bool isCurrentlyFollowing) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUserId = authViewModel.user?.uid;
    final currentUser = authViewModel.user;
    
    if (currentUserId == null || currentUser == null) return;

    try {
      // Karşılıklı takip kontrolü
      final isMutualFollow = currentUser.following.contains(targetUserId) && 
                            targetUser.followers.contains(currentUserId);
      
      if (isMutualFollow) {
        await _userService.unfollowUser(currentUserId, targetUserId);
      } else {
        // Takip isteği gönder
        await _userService.sendFollowRequest(currentUserId, targetUserId);
      }
    } catch (e) {
      if (mounted) {
        ModernSnackbar.showError(
          context,
          'Bir hata oluştu: ${e.toString()}',
        );
      }
    }
  }

  bool _isMutualFollow(UserModel user, String currentUserId) {
    return user.followers.contains(currentUserId) && 
           user.following.contains(currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final currentUser = authViewModel.user;
    final theme = Theme.of(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.showFollowers ? 'Takipçiler' : 'Takip Edilenler')),
        body: const Center(child: Text('Kullanıcı bilgisi bulunamadı')),
      );
    }

    return AppGradientContainer(
      gradientColors: AppTheme.gradientPrimary,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.showFollowers ? 'Takipçiler' : 'Takip Edilenler',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: StreamBuilder<List<UserModel>>(
            stream: _getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: ModernLoadingWidget(
                    message: 'Yükleniyor...',
                  ),
                );
              }

              if (snapshot.hasError) {
                return ErrorStateWidget(
                  message: 'Bir hata oluştu',
                  error: snapshot.error.toString(),
                  onRetry: () => setState(() {}),
                  backgroundColor: Colors.transparent,
                  textColor: Colors.white,
                );
              }

              final users = snapshot.data ?? [];

              if (users.isEmpty) {
                return EmptyStateWidget(
                  icon: widget.showFollowers 
                      ? Icons.people_outline 
                      : Icons.person_outline,
                  title: widget.showFollowers 
                      ? 'Henüz takipçi yok' 
                      : 'Henüz kimseyi takip etmiyorsunuz',
                  message: widget.showFollowers
                      ? 'Profilinizi paylaşarak takipçi kazanabilirsiniz'
                      : 'İlginç kullanıcıları keşfedin ve takip edin',
                  backgroundColor: Colors.transparent,
                  textColor: Colors.white,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isCurrentUser = user.uid == currentUser.uid;
                  final isFollowing = currentUser.following.contains(user.uid);
                  final isMutual = _isMutualFollow(user, currentUser.uid);

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingSm,
                      ),
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UserProfilePage(
                                user: user,
                                currentUserId: currentUser.uid,
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColorConfig.primaryColor.withAlpha(AppTheme.alphaVeryLight),
                          backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null || user.photoUrl!.isEmpty
                              ? Icon(
                                  Icons.person,
                                  color: AppColorConfig.primaryColor,
                                  size: 28,
                                )
                              : null,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => UserProfilePage(
                                      user: user,
                                      currentUserId: currentUser.uid,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName ?? 'İsimsiz',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (user.bio != null && user.bio!.isNotEmpty)
                                    Text(
                                      user.bio!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (isMutual)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingXs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColorConfig.successColor.withAlpha(AppTheme.alphaVeryLight),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(
                                  color: AppColorConfig.successColor.withAlpha(AppTheme.alphaMedium),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Karşılıklı',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColorConfig.successColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: !isCurrentUser
                          ? FilledButton(
                              onPressed: () => _toggleFollow(user.uid, user, isFollowing),
                              style: FilledButton.styleFrom(
                                backgroundColor: isFollowing
                                    ? theme.colorScheme.surfaceContainerHighest
                                    : AppColorConfig.primaryColor,
                                foregroundColor: isFollowing
                                    ? theme.colorScheme.onSurface
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingMd,
                                  vertical: AppTheme.spacingSm,
                                ),
                                minimumSize: const Size(100, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                ),
                              ),
                              child: Text(
                                isFollowing ? 'Takip Ediliyor' : 'Takip Et',
                                style: const TextStyle(fontSize: 12),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}


