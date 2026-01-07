import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/user/domain/entities/user_entity.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../services/user_service.dart';
import '../../core/widgets/modern_components.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_color_config.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserSuggestionsWidget extends StatelessWidget {
  final String currentUserId;
  final List<String> followingIds;
  final List<String> followersIds;
  final bool isExpanded;

  const UserSuggestionsWidget({
    super.key,
    required this.currentUserId,
    required this.followingIds,
    required this.followersIds,
    this.isExpanded = true,
  });

  Future<List<UserEntity>> _getSuggestions(BuildContext context) async {
    // Clean Architecture: AuthViewModel üzerinden user işlemleri
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final suggestions = <UserEntity>[];
    final seenIds = <String>{currentUserId, ...followingIds};

    // 1. Takip edilenlerin takip ettikleri (en iyi öneriler)
    if (followingIds.isNotEmpty) {
      final followingUsers = await Future.wait(
        followingIds.take(5).map((id) => authViewModel.fetchUserProfile(id)),
      );

      for (final user in followingUsers) {
        if (user == null) continue;
        
        for (final suggestedId in user.following.take(10)) {
          if (!seenIds.contains(suggestedId)) {
            seenIds.add(suggestedId);
            final suggestedUser = await authViewModel.fetchUserProfile(suggestedId);
            if (suggestedUser != null) {
              suggestions.add(suggestedUser);
              if (suggestions.length >= 5) break;
            }
          }
        }
        if (suggestions.length >= 5) break;
      }
    }

    // 2. Ortak takipçiler
    if (suggestions.length < 5 && followersIds.isNotEmpty) {
      final followersUsers = await Future.wait(
        followersIds.take(10).map((id) => authViewModel.fetchUserProfile(id)),
      );

      for (final user in followersUsers) {
        if (user == null) continue;
        
        for (final suggestedId in user.following) {
          if (!seenIds.contains(suggestedId)) {
            seenIds.add(suggestedId);
            final suggestedUser = await authViewModel.fetchUserProfile(suggestedId);
            if (suggestedUser != null) {
              suggestions.add(suggestedUser);
              if (suggestions.length >= 5) break;
            }
          }
        }
        if (suggestions.length >= 5) break;
      }
    }

    // 3. Popüler kullanıcılar (rastgele seçilen aktif kullanıcılar)
    if (suggestions.length < 5) {
      // Clean Architecture: getAllUsersStream kullan
      final allUsersStream = authViewModel.getAllUsersStream();
      final allUserEntities = await allUsersStream.first;
      final candidates = <UserEntity>[];

      for (final user in allUserEntities) {
        if (!seenIds.contains(user.uid)) {
          // En az 1 takipçisi olan kullanıcıları önceliklendir
          if (user.followers.isNotEmpty) {
            candidates.add(user);
          }
        }
      }

      // Takipçi sayısına göre sırala
      candidates.sort((a, b) => b.followers.length.compareTo(a.followers.length));
      
      suggestions.addAll(candidates.take(5 - suggestions.length));
    }

    return suggestions.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<UserEntity>>(
      future: _getSuggestions(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final suggestions = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: GlassContainer(
            borderRadius: AppTheme.radiusXl,
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            blurStrength: 10,
            glassAlpha: AppTheme.glassAlphaLight,
            borderAlpha: AppTheme.glassAlphaMedium,
            child: isExpanded
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          // Ekran genişliğinin 1/3'ü kadar genişlik (yan yana 3 tane sığsın)
                          final itemWidth = (constraints.maxWidth - (AppTheme.spacingMd * 4)) / 3;
                          return SizedBox(
                            height: 170,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: suggestions.length,
                              itemBuilder: (context, index) {
                                final user = suggestions[index];
                                return _buildSuggestionItem(context, user, theme, itemWidth);
                              },
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionItem(BuildContext context, UserEntity user, ThemeData theme, double itemWidth) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.user;
    // Karşılıklı takip kontrolü
    final isMutualFollow = currentUser != null && 
                          currentUser.following.contains(user.uid) && 
                          user.followers.contains(currentUser.uid);
    final userService = UserService();

    return Container(
      width: itemWidth,
      margin: const EdgeInsets.only(right: AppTheme.spacingMd),
      constraints: const BoxConstraints(maxHeight: 170),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (currentUser != null) {
                AppNavigation.toUserProfile(context: context, userId: user.uid);
              }
            },
            child: CircleAvatar(
              radius: 35,
              backgroundColor: AppColorConfig.primaryColor.withAlpha(AppTheme.alphaVeryLight),
              backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(user.photoUrl!)
                  : null,
              child: user.photoUrl == null || user.photoUrl!.isEmpty
                  ? Icon(
                      Icons.person,
                      color: AppColorConfig.primaryColor,
                      size: 35,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.displayName ?? 'İsimsiz',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                if (currentUser == null) return;
                
                try {
                  // Karşılıklı takip kontrolü
                  final isMutualFollow = currentUser.following.contains(user.uid) && 
                                         user.followers.contains(currentUser.uid);
                  
                  if (isMutualFollow) {
                    await userService.unfollowUser(currentUser.uid, user.uid);
                    if (context.mounted) {
                      ModernSnackbar.showSuccess(context, 'Takip bırakıldı');
                    }
                  } else {
                    // Takip isteği gönder
                    await userService.sendFollowRequest(currentUser.uid, user.uid);
                    if (context.mounted) {
                      ModernSnackbar.showSuccess(context, 'Takip isteği gönderildi');
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ModernSnackbar.showError(
                      context,
                      'Bir hata oluştu',
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: isMutualFollow
                    ? theme.colorScheme.surfaceContainerHighest
                    : AppColorConfig.primaryColor,
                foregroundColor: isMutualFollow
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                minimumSize: const Size(0, 26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              child: Text(
                isMutualFollow ? 'Takip' : 'Takip Et',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

