import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'user_profile_page.dart';
import 'widgets/modern_loading_widget.dart';
import 'widgets/app_gradient_container.dart';
import '../core/widgets/modern_components.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_color_config.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<UserModel>> _userStream() {
    return FirebaseFirestore.instance.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthViewModel>(context, listen: false).user?.uid ?? '';
    final theme = Theme.of(context);
    
    return AppGradientContainer(
      gradientColors: AppTheme.gradientPrimary,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
        children: [
              // Header with back button and title
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spacingMd,
                  MediaQuery.of(context).padding.top + AppTheme.spacingMd,
                  AppTheme.spacingMd,
                  AppTheme.spacingMd,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha(AppTheme.alphaLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
              ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Text(
                        'Kullanıcı Ara',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                ),
                      ),
                    ),
                  ],
                ),
              ),
              // Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: ModernInputField(
                    controller: _searchController,
                    hint: 'Kullanıcı ara (isim, e-posta)',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColorConfig.primaryColor,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                      )
                    : null,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              // Results
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _userStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: ModernLoadingWidget(
                          message: 'Kullanıcılar yükleniyor...',
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return ErrorStateWidget(
                        message: 'Kullanıcılar yüklenirken bir hata oluştu',
                        error: snapshot.error.toString(),
                        onRetry: () => setState(() {}),
                        backgroundColor: Colors.transparent,
                        textColor: Colors.white,
                      );
                }

                final users = snapshot.data ?? [];
                final filtered = users.where((user) {
                      if (user.uid == currentUserId) return false; // Kendi profilini gösterme
                      if (_searchQuery.isEmpty) return false; // Arama yoksa gösterme
                  final query = _searchQuery.toLowerCase();
                  return (user.displayName ?? '').toLowerCase().contains(query) ||
                             user.email.toLowerCase().contains(query) ||
                             (user.username ?? '').toLowerCase().contains(query);
                }).toList();

                    if (_searchQuery.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.search_rounded,
                        title: 'Kullanıcı ara',
                        message: 'Aramak istediğiniz kullanıcının ismini veya e-postasını yazın',
                        backgroundColor: Colors.transparent,
                        textColor: Colors.white,
                      );
                    }

                if (filtered.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.person_search_rounded,
                        title: 'Kullanıcı bulunamadı',
                        message: 'Farklı arama terimleri deneyin',
                        backgroundColor: Colors.transparent,
                        textColor: Colors.white,
                  );
                }

                return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                  itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingXs),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMd,
                              vertical: AppTheme.spacingXs,
                            ),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColorConfig.primaryColor.withAlpha(AppTheme.alphaVeryLight),
                              backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                  ? CachedNetworkImageProvider(user.photoUrl!)
                                  : null,
                              child: user.photoUrl == null || user.photoUrl!.isEmpty
                                  ? Icon(
                                      Icons.person_rounded,
                                      color: AppColorConfig.primaryColor,
                                      size: 28,
                                    )
                                  : null,
                            ),
                            title: Text(
                              user.displayName ?? user.username ?? 'İsimsiz',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (user.email.isNotEmpty)
                                  Text(
                                    user.email,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                  ),
                                if (user.bio != null && user.bio!.isNotEmpty)
                                      Text(
                                    user.bio!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => UserProfilePage(
                                    user: user,
                                    currentUserId: currentUserId,
                            ),
                          ),
                              );
                            },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
} 