import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../services/user_service.dart';
import 'user_profile_page.dart';
import 'event_detail_page.dart';
import 'private_chat_page.dart';
import 'widgets/app_gradient_container.dart';
import 'widgets/modern_loading_widget.dart';
import '../core/widgets/modern_components.dart';
import '../core/widgets/glass_container.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_color_config.dart';
import '../l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final UserService _userService = UserService();
  final _notificationsRef = FirebaseFirestore.instance.collection('notifications');

  Stream<List<NotificationModel>> _getNotificationsStream(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<UserModel?> _getUserById(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<EventModel?> _getEventById(String eventId) async {
    final doc = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .get();
    if (doc.exists) {
      return EventModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Context'i async öncesi sakla
    if (!mounted) return;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    // Bildirimi okundu olarak işaretle
    await _userService.markNotificationAsRead(notification.id);
    
    if (!mounted) return;
    final currentUserId = authViewModel.user?.uid;

    if (currentUserId == null) return;

    // Bildirim tipine göre yönlendir
    if (['follow', 'follow_request', 'follow_request_accepted'].contains(notification.type) && notification.relatedUserId != null) {
      final user = await _getUserById(notification.relatedUserId!);
      if (user != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserProfilePage(
              user: user,
              currentUserId: currentUserId,
            ),
          ),
        );
      }
    } else if (notification.type == 'event' && notification.relatedEventId != null && mounted) {
      final event = await _getEventById(notification.relatedEventId!);
      if (event != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EventDetailPage(event: event),
          ),
        );
      }
    } else if (['message', 'message_request'].contains(notification.type) && notification.relatedChatId != null && mounted) {
      // Chat bilgilerini çek
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(notification.relatedChatId!)
          .get();
      
      if (chatDoc.exists && mounted) {
        final chatData = chatDoc.data()!;
        final participants = List<String>.from(chatData['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );
        
        if (otherUserId.isNotEmpty) {
          final otherUser = await _getUserById(otherUserId);
          final currentUser = authViewModel.user;
          
          if (otherUser != null && currentUser != null && mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PrivateChatPage(
                  currentUserId: currentUserId,
                  currentUserName: currentUser.displayName ?? currentUser.email,
                  otherUserId: otherUser.uid,
                  otherUserName: otherUser.displayName ?? otherUser.email,
                ),
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final currentUser = authViewModel.user;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.notifications)),
        body: Center(child: Text(l10n.userInfoNotFound)),
      );
    }

    return AppGradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            l10n.notifications,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            StreamBuilder<List<NotificationModel>>(
              stream: _getNotificationsStream(currentUser.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final hasUnread = snapshot.data!.any((n) => !n.isRead);
                if (!hasUnread) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.done_all, color: Colors.white),
                  tooltip: l10n.markAllAsRead,
                  onPressed: () async {
                    if (!mounted) return;
                    final currentContext = context;
                    await _userService.markAllNotificationsAsRead(currentUser.uid);
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    ModernSnackbar.showSuccess(
                      currentContext,
                      l10n.allNotificationsRead,
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: StreamBuilder<List<NotificationModel>>(
            stream: _getNotificationsStream(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: ModernLoadingWidget(
                    message: l10n.loadingNotifications,
                  ),
                );
              }

              if (snapshot.hasError) {
                return ErrorStateWidget(
                  message: l10n.notificationsLoadError,
                  error: snapshot.error.toString(),
                  onRetry: () => setState(() {}),
                  backgroundColor: Colors.transparent,
                  textColor: Colors.white,
                );
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.notifications_none,
                  title: l10n.noNotifications,
                  message: l10n.notificationsWillAppear,
                  backgroundColor: Colors.transparent,
                  textColor: Colors.white,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationItem(notification, theme, currentUser.uid);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    ThemeData theme,
    String currentUserId,
  ) {
    return FutureBuilder<UserModel?>(
      future: notification.relatedUserId != null
          ? _getUserById(notification.relatedUserId!)
          : Future.value(null),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final l10n = AppLocalizations.of(context)!;

        return GlassContainer(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          borderRadius: AppTheme.radiusLg,
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          glassAlpha: notification.isRead
              ? AppTheme.glassAlphaVeryLight
              : AppTheme.glassAlphaLight,
          borderAlpha: notification.isRead
              ? AppTheme.glassAlphaMedium
              : AppTheme.glassAlphaDark,
          backgroundColor: notification.isRead
              ? null
              : AppColorConfig.primaryColor.withValues(alpha: AppTheme.glassAlphaVeryLight),
          borderColor: notification.isRead
              ? null
              : AppColorConfig.primaryColor.withValues(alpha: AppTheme.glassAlphaMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ana satır - Avatar, içerik ve unread indicator
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar - Sabit boyut
                    _buildNotificationAvatar(notification, user, theme),
                    const SizedBox(width: AppTheme.spacingMd),
                    // İçerik - Flexible
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _handleNotificationTap(notification),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Başlık satırı
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: notification.isRead
                                          ? theme.colorScheme.onSurface
                                          : _getNotificationColor(notification.type),
                                    ),
                                  ),
                                ),
                                // Okunmadı göstergesi - sağ üst köşede
                                if (!notification.isRead)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(
                                      color: _getNotificationColor(notification.type),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getNotificationColor(notification.type).withValues(alpha: 0.4),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Mesaj
                            Text(
                              notification.body,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Zaman ve durum göstergesi
                            Row(
                              children: [
                                Icon(
                                  _getNotificationIcon(notification.type),
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(notification.createdAt, l10n),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Takip isteği butonları - SADECE bekleyen istek varsa göster
              _buildFollowRequestActions(notification, currentUserId, user, theme, l10n),
            ],
          ),
        );
      },
    );
  }

  /// Bildirim avatarı
  Widget _buildNotificationAvatar(NotificationModel notification, UserModel? user, ThemeData theme) {
    final color = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);
    
    if (user != null && user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: user.photoUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: color.withValues(alpha: 0.1),
                child: Icon(Icons.person, color: color, size: 24),
              ),
              errorWidget: (context, url, error) => Container(
                color: color.withValues(alpha: 0.1),
                child: Icon(Icons.person, color: color, size: 24),
              ),
            ),
          ),
        ),
      );
    }
    
    return GestureDetector(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }

  /// Takip isteği için butonlar - SADECE bekleyen istek varsa göster
  Widget _buildFollowRequestActions(
    NotificationModel notification,
    String currentUserId,
    UserModel? user,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    // Sadece follow_request tipindeyse ve relatedUserId varsa kontrol et
    if (notification.type != 'follow_request' || notification.relatedUserId == null) {
      return const SizedBox.shrink();
    }

    // Gerçek zamanlı olarak pending durumunu kontrol et
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox.shrink();

        final pendingRequests = List<String>.from(userData['pendingFollowRequests'] ?? []);
        final followers = List<String>.from(userData['followers'] ?? []);
        
        final isPending = pendingRequests.contains(notification.relatedUserId);
        // Tek yönlü takip sistemi: İstek kabul edildiyse, requester artık bizi takip ediyor
        final isNowFollower = followers.contains(notification.relatedUserId);
        // NOT: isNowFriends için karşılıklı takip kontrolü KALDIRILDI
        // Çünkü artık tek yönlü takip sistemi var

        // İstek kabul edildi - Yeşil başarı göstergesi
        if (isNowFollower && !isPending) {
          return Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingMd),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Seni takip ediyor ✓',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // İstek hala beklemede - Butonları göster
        if (isPending) {
          return Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingMd),
            child: Row(
              children: [
                Expanded(
                  child: _FollowActionButton(
                    onPressed: () => _acceptFollowRequest(currentUserId, notification),
                    icon: Icons.check_rounded,
                    label: 'Kabul Et',
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: _FollowActionButton(
                    onPressed: () => _rejectFollowRequest(currentUserId, notification),
                    icon: Icons.close_rounded,
                    label: 'Reddet',
                    isPrimary: false,
                  ),
                ),
              ],
            ),
          );
        }

        // İstek işlendi ama arkadaş değiller (reddedilmiş olabilir)
        return Padding(
          padding: const EdgeInsets.only(top: AppTheme.spacingMd),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'İstek işlendi',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Takip isteğini kabul et
  Future<void> _acceptFollowRequest(String currentUserId, NotificationModel notification) async {
    if (!mounted) return;
    
    try {
      await _userService.acceptFollowRequest(
        currentUserId,
        notification.relatedUserId!,
      );
      
      // Bildirimi sil ve yenisini ekle (type'ı değiştirmek yerine)
      await _userService.markNotificationAsRead(notification.id);
      
      if (mounted) {
        final authVM = Provider.of<AuthViewModel>(context, listen: false);
        await authVM.refreshUserProfile();
        ModernSnackbar.showSuccess(context, 'Takip isteği kabul edildi ✓');
      }
    } catch (e) {
      if (mounted) {
        ModernSnackbar.showError(context, 'Hata: ${e.toString()}');
      }
    }
  }

  /// Takip isteğini reddet
  Future<void> _rejectFollowRequest(String currentUserId, NotificationModel notification) async {
    if (!mounted) return;
    
    try {
      await _userService.rejectFollowRequest(
        currentUserId,
        notification.relatedUserId!,
      );
      await _userService.markNotificationAsRead(notification.id);
      
      if (mounted) {
        ModernSnackbar.showSuccess(context, 'Takip isteği reddedildi');
      }
    } catch (e) {
      if (mounted) {
        ModernSnackbar.showError(context, 'Hata: ${e.toString()}');
      }
    }
  }

  /// Bildirim tipine göre renk
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'follow_request':
        return Colors.blue;
      case 'follow_request_accepted':
        return Colors.green;
      case 'follow':
        return AppColorConfig.primaryColor;
      case 'event':
      case 'event_invitation':
      case 'event_reminder':
        return Colors.orange;
      case 'event_join_request':
      case 'event_join_approved':
        return Colors.teal;
      case 'message':
      case 'message_request':
        return Colors.purple;
      default:
        return AppColorConfig.primaryColor;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'follow':
      case 'follow_request':
        return Icons.person_add_alt_1_rounded;
      case 'follow_request_accepted':
        return Icons.check_circle_rounded;
      case 'event':
        return Icons.event_note_rounded;
      case 'message':
      case 'message_request':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return l10n.justNow;
        }
        return '${difference.inMinutes} ${l10n.minutesAgo}';
      }
      return '${difference.inHours} ${l10n.hoursAgo}';
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${l10n.daysAgo}';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }
}

/// Takip işlem butonu - Loading state destekli
class _FollowActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;

  const _FollowActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isPrimary,
  });

  @override
  State<_FollowActionButton> createState() => _FollowActionButtonState();
}

class _FollowActionButtonState extends State<_FollowActionButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      widget.onPressed();
      // Callback'in bitmesini beklemiyoruz çünkü VoidCallback async değil
      // Ama işlem başladığını göstermek için kısa bir gecikme
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPrimary) {
      return FilledButton(
        onPressed: _isLoading ? null : _handlePress,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      );
    }

    return OutlinedButton(
      onPressed: _isLoading ? null : _handlePress,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red[700],
        side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
      child: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.red[700],
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 18),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
    );
  }
}

