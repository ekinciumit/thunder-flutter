import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../features/auth/presentation/pages/complete_profile_page.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/user/domain/entities/user_entity.dart';

/// Development Preview Page
/// 
/// Bu sayfa geliştirme sırasında tüm ekranları mock data ile görüntülemek için kullanılır.
/// Uygulamayı çalıştırmadan ekranları inceleyebilirsin.
class DevPreviewPage extends StatelessWidget {
  const DevPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.devPreviewTitle),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('🔐 Authentication', theme),
          _buildPreviewCard(
            context: context,
            title: 'Profil Tamamlama',
            description: 'Complete Profile Page',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _buildCompleteProfilePreview(context),
                ),
              );
            },
            theme: theme,
          ),
          _buildPreviewCard(
            context: context,
            title: 'Giriş Sayfası',
            description: 'Auth Page',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthPage(),
                ),
              );
            },
            theme: theme,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('📝 Notlar', theme),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Kullanım',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Herhangi bir ekrana tıklayarak o ekranı tam ekran görüntüleyebilirsin\n'
                  '• Mock data ile çalışır, gerçek veri gerekmez\n'
                  '• Uygulamayı çalıştırmadan ekranları inceleyebilirsin\n'
                  '• Geri butonu ile bu sayfaya dönebilirsin',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPreviewCard({
    required BuildContext context,
    required String title,
    required String description,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.phone_android,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Complete Profile Page Preview with Mock Data
  Widget _buildCompleteProfilePreview(BuildContext context) {
    // Mock AuthViewModel oluştur
    final mockAuthViewModel = _MockAuthViewModel();
    
    // Mock user oluştur (profil tamamlanmamış)
    mockAuthViewModel.user = UserEntity(
      uid: 'mock-user-id',
      email: 'mock@example.com',
      displayName: null, // Profil tamamlanmamış
      username: null,
      bio: null,
      photoUrl: null,
      followers: const [],
      following: const [],
      fcmTokens: const [],
      pendingFollowRequests: const [],
      sentFollowRequests: const [],
      isPrivate: false,
      showLocation: true,
      showOnlineStatus: true,
      blockedUsers: const [],
    );
    mockAuthViewModel.needsProfileCompletion = true;
    mockAuthViewModel.isLoading = false;
    mockAuthViewModel.error = null;
    
    return ChangeNotifierProvider.value(
      value: mockAuthViewModel,
      child: Scaffold(
        body: const CompleteProfilePage(),
      ),
    );
  }
}

/// Mock AuthViewModel for Preview
/// 
/// Gerçek AuthViewModel'i extend etmeden sadece preview için gerekli özellikleri sağlar
class _MockAuthViewModel extends ChangeNotifier {
  UserEntity? user;
  bool isLoading = false;
  String? error;
  bool needsProfileCompletion = true;
  bool justSignedUp = false;
  
  Future<void> completeProfile({
    required String displayName,
    String? bio,
    String? photoUrl,
  }) async {
    // Mock implementation - sadece state'i güncelle
    isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (user != null) {
      user = UserEntity(
        uid: user!.uid,
        email: user!.email,
        displayName: displayName,
        username: user!.username,
        bio: bio,
        photoUrl: photoUrl ?? user!.photoUrl,
        followers: user!.followers,
        following: user!.following,
        fcmTokens: user!.fcmTokens,
        pendingFollowRequests: user!.pendingFollowRequests,
        sentFollowRequests: user!.sentFollowRequests,
        isPrivate: user!.isPrivate,
        showLocation: user!.showLocation,
        showOnlineStatus: user!.showOnlineStatus,
        blockedUsers: user!.blockedUsers,
      );
    }
    
    needsProfileCompletion = false;
    isLoading = false;
    notifyListeners();
  }
  
  Future<String?> uploadProfilePhoto(String photoFilePath) async {
    // Mock implementation - sadece fake URL döndür
    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://via.placeholder.com/300?text=Mock+Photo';
  }
}

