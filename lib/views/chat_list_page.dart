import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/chat/domain/entities/chat_entity.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'widgets/app_gradient_container.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/skeleton_widgets.dart';
import '../core/widgets/modern_components.dart';
import '../l10n/app_localizations.dart';
import '../core/navigation/app_navigation.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatLastMessageTime(DateTime? lastMessageAt) {
    if (lastMessageAt == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(lastMessageAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dk önce';
    } else {
      return 'Şimdi';
    }
  }

  String _getChatDisplayName(ChatEntity chat, String currentUserId, AppLocalizations l10n) {
    if (chat.type == ChatType.private) {
      final otherParticipant = chat.participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      return chat.participantDetails[otherParticipant]?.name ?? l10n.noData;
    }
    return chat.name;
  }

  String? _getChatPhotoUrl(ChatEntity chat, String currentUserId) {
    if (chat.type == ChatType.private) {
      final otherParticipant = chat.participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      return chat.participantDetails[otherParticipant]?.photoUrl;
    }
    return chat.photoUrl;
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final authViewModel = Provider.of<AuthViewModel>(context);
    final currentUser = authViewModel.user;
    final l10n = AppLocalizations.of(context)!;
    
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text(
            l10n.noData,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }
    
    return AppGradientContainer(
      backgroundImagePath: 'assets/backgrounds/background_2.png',
      backgroundOpacity: 0.7,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: AppBar(
          title: Text(
            l10n.chat,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: brightness == Brightness.dark 
                  ? theme.colorScheme.onSurface 
                  : Colors.white,
              letterSpacing: -0.5,
              shadows: brightness == Brightness.dark ? null : [
                Shadow(
                  color: Colors.black.withAlpha(AppTheme.alphaMediumDark),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: brightness == Brightness.dark 
              ? theme.colorScheme.onSurface 
              : Colors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingMd),
              child: FilledButton.icon(
                onPressed: () {
                  AppNavigation.toMessageSearch(context: context);
                },
                icon: const Icon(Icons.search_rounded, size: 20),
                label: const Text('Ara'),
                style: FilledButton.styleFrom(
                  backgroundColor: brightness == Brightness.dark
                      ? theme.colorScheme.surface.withAlpha(AppTheme.alphaMedium)
                      : Colors.white.withAlpha(AppTheme.alphaMedium),
                  foregroundColor: brightness == Brightness.dark
                      ? theme.colorScheme.onSurface
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            StreamBuilder<List<ChatEntity>>(
          stream: Provider.of<ChatViewModel>(context, listen: false).getUserChats(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ChatListSkeleton();
            }

            if (snapshot.hasError) {
              final isDark = brightness == Brightness.dark;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? theme.colorScheme.surfaceContainerHighest.withAlpha(AppTheme.alphaVeryLight)
                              : theme.colorScheme.surfaceContainerHighest.withAlpha(AppTheme.alphaVeryLight),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Bir hata oluştu',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tekrar Dene'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final chats = snapshot.data ?? [];
            
            if (chats.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Henüz sohbet yok',
                message: 'Etkinliklere katılarak yeni insanlarla tanışın ve sohbet başlatın!',
                actionLabel: 'Etkinlikleri Keşfet',
                onAction: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                backgroundColor: Colors.transparent,
                textColor: brightness == Brightness.dark 
                    ? theme.colorScheme.onSurface 
                    : theme.colorScheme.onSurface,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final otherParticipant = chat.type == ChatType.private
                    ? chat.participants.firstWhere(
                        (id) => id != currentUser.uid,
                        orElse: () => '',
                      )
                    : '';
                
                // Eğer participantDetails yoksa, Firestore'dan çek (Clean Architecture: AuthViewModel kullan)
                if (chat.type == ChatType.private && 
                    otherParticipant.isNotEmpty &&
                    !chat.participantDetails.containsKey(otherParticipant)) {
                  final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
                  return FutureBuilder(
                    future: authViewModel.fetchUserProfile(otherParticipant),
                    builder: (context, snapshot) {
                      String displayName = 'Bilinmeyen Kullanıcı';
                      String? photoUrl;
                      
                      if (snapshot.hasData && snapshot.data != null) {
                        displayName = snapshot.data!.displayName ?? 'Bilinmeyen Kullanıcı';
                        photoUrl = snapshot.data!.photoUrl;
                      }
                      
                      return _buildChatItem(
                        chat: chat,
                        currentUser: currentUser,
                        displayName: displayName,
                        photoUrl: photoUrl,
                        theme: theme,
                      );
                    },
                  );
                }
                
                final displayName = _getChatDisplayName(chat, currentUser.uid, l10n);
                final photoUrl = _getChatPhotoUrl(chat, currentUser.uid);
                
                return _buildChatItem(
                  chat: chat,
                  currentUser: currentUser,
                  displayName: displayName,
                  photoUrl: photoUrl,
                  theme: theme,
                );
              },
            );
          },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem({
    required ChatEntity chat,
    required currentUser,
    required String displayName,
    required String? photoUrl,
    required ThemeData theme,
  }) {
    final unreadCount = chat.unreadCounts[currentUser.uid] ?? 0;
    final lastMessageTime = _formatLastMessageTime(chat.lastMessageAt);
    final hasUnread = unreadCount > 0;
    
    final isDark = theme.brightness == Brightness.dark;
    
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: isDark
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(0), // Tamamen şeffaf
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1), // İnce şeffaf border
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1), // Subtle shadow
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (chat.type == ChatType.private) {
                            final otherParticipant = chat.participants.firstWhere(
                              (id) => id != currentUser.uid,
                              orElse: () => '',
                            );
                            final otherParticipantName = chat.participantDetails[otherParticipant]?.name ?? displayName;
                            
                            AppNavigation.toChat(
                              context: context,
                              currentUserId: currentUser.uid,
                              currentUserName: currentUser.displayName ?? 'Kullanıcı',
                              otherUserId: otherParticipant,
                              otherUserName: otherParticipantName,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: _buildChatItemContent(
                          chat: chat,
                          currentUser: currentUser,
                          displayName: displayName,
                          photoUrl: photoUrl,
                          theme: theme,
                          hasUnread: hasUnread,
                          lastMessageTime: lastMessageTime,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(AppTheme.alphaVeryLight),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: theme.colorScheme.primary.withAlpha(AppTheme.alphaVeryLight),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (chat.type == ChatType.private) {
                        final otherParticipant = chat.participants.firstWhere(
                          (id) => id != currentUser.uid,
                          orElse: () => '',
                        );
                        final otherParticipantName = chat.participantDetails[otherParticipant]?.name ?? displayName;
                        
                        AppNavigation.toChat(
                          context: context,
                          currentUserId: currentUser.uid,
                          currentUserName: currentUser.displayName ?? 'Kullanıcı',
                          otherUserId: otherParticipant,
                          otherUserName: otherParticipantName,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: _buildChatItemContent(
                      chat: chat,
                      currentUser: currentUser,
                      displayName: displayName,
                      photoUrl: photoUrl,
                      theme: theme,
                      hasUnread: hasUnread,
                      lastMessageTime: lastMessageTime,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildChatItemContent({
    required ChatEntity chat,
    required currentUser,
    required String displayName,
    required String? photoUrl,
    required ThemeData theme,
    required bool hasUnread,
    required String lastMessageTime,
  }) {
    final unreadCount = chat.unreadCounts[currentUser.uid] ?? 0;
    
    // Diğer kullanıcının ID'sini al (profil sayfasına gitmek için)
    final otherUserId = chat.type == ChatType.private
        ? chat.participants.firstWhere(
            (id) => id != currentUser.uid,
            orElse: () => '',
          )
        : '';
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar - Tıklanabilir (profil sayfasına gider)
          GestureDetector(
            onTap: () async {
              if (otherUserId.isEmpty) return;
              
              // Kullanıcı profilini çek
              final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
              final userProfile = await authViewModel.fetchUserProfile(otherUserId);
              
              if (userProfile != null && mounted) {
                AppNavigation.toUserProfile(context: context, userId: userProfile.uid);
              }
            },
            child: Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withAlpha(AppTheme.alphaMediumDark),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  displayName.isNotEmpty 
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            displayName.isNotEmpty 
                                ? displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lastMessageTime,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.lastMessage?.text ?? 'Medya mesajı',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasUnread) ...[
                      const SizedBox(width: 8),
                      Badge(
                        label: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.primary,
                        textColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
