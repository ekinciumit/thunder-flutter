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
import '../core/theme/app_theme.dart';
import '../core/theme/app_color_config.dart';
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
    // Bildirimi okundu olarak işaretle
    await _userService.markNotificationAsRead(notification.id);

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
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

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bildirimler')),
        body: const Center(child: Text('Kullanıcı bilgisi bulunamadı')),
      );
    }

    final unreadCount = StreamBuilder<List<NotificationModel>>(
      stream: _getNotificationsStream(currentUser.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final count = snapshot.data!.where((n) => !n.isRead).length;
        return count > 0
            ? Badge(
                label: Text('$count'),
                child: const SizedBox.shrink(),
              )
            : const SizedBox.shrink();
      },
    );

    return AppGradientContainer(
      gradientColors: AppTheme.gradientPrimary,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Bildirimler',
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
                  tooltip: 'Tümünü okundu işaretle',
                  onPressed: () async {
                    await _userService.markAllNotificationsAsRead(currentUser.uid);
                    if (mounted) {
                      ModernSnackbar.showSuccess(
                        context,
                        'Tüm bildirimler okundu olarak işaretlendi',
                      );
                    }
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
                return const Center(
                  child: ModernLoadingWidget(
                    message: 'Bildirimler yükleniyor...',
                  ),
                );
              }

              if (snapshot.hasError) {
                return ErrorStateWidget(
                  message: 'Bildirimler yüklenirken bir hata oluştu',
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
                  title: 'Henüz bildirim yok',
                  message: 'Yeni bildirimler burada görünecek',
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

        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          elevation: 0,
          color: notification.isRead
              ? theme.colorScheme.surface
              : AppColorConfig.primaryColor.withAlpha(AppTheme.alphaVeryLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            side: BorderSide(
              color: notification.isRead
                  ? Colors.transparent
                  : AppColorConfig.primaryColor.withAlpha(AppTheme.alphaMedium),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _handleNotificationTap(notification),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  if (user != null)
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColorConfig.primaryColor.withAlpha(AppTheme.alphaVeryLight),
                      backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null || user.photoUrl!.isEmpty
                          ? Icon(
                              Icons.person,
                              color: AppColorConfig.primaryColor,
                              size: 24,
                            )
                          : null,
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColorConfig.primaryColor.withAlpha(AppTheme.alphaVeryLight),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: AppColorConfig.primaryColor,
                        size: 24,
                      ),
                    ),
                  const SizedBox(width: AppTheme.spacingMd),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: notification.isRead
                                ? theme.colorScheme.onSurface
                                : AppColorConfig.primaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          notification.body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          _formatDate(notification.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(AppTheme.alphaMedium),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColorConfig.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Az önce';
        }
        return '${difference.inMinutes} dakika önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd MMM yyyy', 'tr_TR').format(date);
    }
  }
}

