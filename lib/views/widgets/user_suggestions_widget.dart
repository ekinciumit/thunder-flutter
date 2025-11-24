import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../services/user_service.dart';
import '../user_profile_page.dart';
import '../../core/widgets/modern_components.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_color_config.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserSuggestionsWidget extends StatelessWidget {
  final String currentUserId;
  final List<String> followingIds;
  final List<String> followersIds;

  const UserSuggestionsWidget({
    super.key,
    required this.currentUserId,
    required this.followingIds,
    required this.followersIds,
  });

  Future<List<UserModel>> _getSuggestions() async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final suggestions = <UserModel>[];
    final seenIds = <String>{currentUserId, ...followingIds};

    // 1. Takip edilenlerin takip ettikleri (en iyi öneriler)
    if (followingIds.isNotEmpty) {
      final followingUsers = await Future.wait(
        followingIds.take(5).map((id) => usersRef.doc(id).get()),
      );

      for (final doc in followingUsers) {
        if (!doc.exists) continue;
        final userData = doc.data()!;
        final userFollowing = List<String>.from(userData['following'] ?? []);
        
        for (final suggestedId in userFollowing.take(10)) {
          if (!seenIds.contains(suggestedId)) {
            seenIds.add(suggestedId);
            final suggestedDoc = await usersRef.doc(suggestedId).get();
            if (suggestedDoc.exists) {
              suggestions.add(UserModel.fromMap(suggestedDoc.data()!, suggestedDoc.id));
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
        followersIds.take(10).map((id) => usersRef.doc(id).get()),
      );

      for (final doc in followersUsers) {
        if (!doc.exists) continue;
        final userData = doc.data()!;
        final userFollowing = List<String>.from(userData['following'] ?? []);
        
        for (final suggestedId in userFollowing) {
          if (!seenIds.contains(suggestedId)) {
            seenIds.add(suggestedId);
            final suggestedDoc = await usersRef.doc(suggestedId).get();
            if (suggestedDoc.exists) {
              suggestions.add(UserModel.fromMap(suggestedDoc.data()!, suggestedDoc.id));
              if (suggestions.length >= 5) break;
            }
          }
        }
        if (suggestions.length >= 5) break;
      }
    }

    // 3. Popüler kullanıcılar (rastgele seçilen aktif kullanıcılar)
    if (suggestions.length < 5) {
      final allUsers = await usersRef.limit(50).get();
      final candidates = <UserModel>[];

      for (final doc in allUsers.docs) {
        if (!seenIds.contains(doc.id)) {
          final user = UserModel.fromMap(doc.data(), doc.id);
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

    return FutureBuilder<List<UserModel>>(
      future: _getSuggestions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final suggestions = snapshot.data!;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: theme.colorScheme.outline.withAlpha(AppTheme.alphaVeryLight),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.explore,
                      color: AppColorConfig.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      'Keşfet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
                LayoutBuilder(
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionItem(BuildContext context, UserModel user, ThemeData theme, double itemWidth) {
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserProfilePage(
                      user: user,
                      currentUserId: currentUser.uid,
                    ),
                  ),
                );
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
                    : Colors.white,
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

