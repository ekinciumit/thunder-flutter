import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/notification/domain/entities/notification_entity.dart';
import '../features/notification/data/mappers/notification_mapper.dart';
import '../features/user/domain/entities/user_entity.dart';
import '../features/event/domain/entities/event_entity.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../features/event/presentation/viewmodels/event_viewmodel.dart';
import '../features/chat/presentation/viewmodels/chat_viewmodel.dart';
import '../services/user_service.dart';
import 'widgets/app_gradient_container.dart';
import 'widgets/notification_item.dart';
import '../core/widgets/modern_components.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/skeleton_widgets.dart';
import '../l10n/app_localizations.dart';
import '../core/navigation/app_navigation.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final UserService _userService = UserService();

  Stream<List<NotificationEntity>> _getNotificationsStream(String userId) {
    // Clean Architecture: UserService üzerinden notifications stream
    // UserService Map döndürüyor, NotificationMapper ile direkt Entity'ye dönüştürüyoruz
    return _userService.getNotificationsStream(userId).map((list) {
      return list.map((data) {
        return NotificationMapper.fromMap(data, data['id'] as String);
      }).toList();
    });
  }

  Future<UserEntity?> _getUserById(String userId) async {
    // Clean Architecture: AuthViewModel üzerinden user getir
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    return await authViewModel.fetchUserProfile(userId);
  }

  Future<EventEntity?> _getEventById(String eventId) async {
    // Clean Architecture: EventViewModel üzerinden event stream'den ilk değeri al
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    return await eventViewModel.getEventStream(eventId).first;
  }

  Future<void> _handleNotificationTap(NotificationEntity notification) async {
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
        AppNavigation.toUserProfile(context: context, userId: user.uid);
      }
    } else if (notification.type == 'event' && notification.relatedEventId != null && mounted) {
      final event = await _getEventById(notification.relatedEventId!);
      if (event != null && mounted) {
        AppNavigation.toEventDetail(context: context, event: event);
      }
    } else if (['message', 'message_request'].contains(notification.type) && notification.relatedChatId != null && mounted) {
      // Clean Architecture: ChatViewModel üzerinden chat bilgilerini çek
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      final chat = await chatViewModel.getChatById(notification.relatedChatId!);
      
      if (chat != null && mounted) {
        final participants = chat.participants;
        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );
        
        if (otherUserId.isNotEmpty) {
          final otherUser = await _getUserById(otherUserId);
          final currentUser = authViewModel.user;
          
          if (otherUser != null && currentUser != null && mounted) {
            AppNavigation.toChat(
              context: context,
              currentUserId: currentUserId,
              currentUserName: currentUser.displayName ?? currentUser.email,
              otherUserId: otherUser.uid,
              otherUserName: otherUser.displayName ?? otherUser.email,
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
            StreamBuilder<List<NotificationEntity>>(
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
          child: StreamBuilder<List<NotificationEntity>>(
            stream: _getNotificationsStream(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const NotificationListSkeleton();
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
                  return FutureBuilder<UserEntity?>(
                    future: notification.relatedUserId != null
                        ? _getUserById(notification.relatedUserId!)
                        : Future.value(null),
                    builder: (context, userSnapshot) {
                      return NotificationItem(
                        notification: notification,
                        user: userSnapshot.data,
                        currentUserId: currentUser.uid,
                        onTap: _handleNotificationTap,
                        onAcceptFollowRequest: _acceptFollowRequest,
                        onRejectFollowRequest: _rejectFollowRequest,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }


  /// Takip isteğini kabul et
  Future<void> _acceptFollowRequest(String currentUserId, NotificationEntity notification) async {
    if (!mounted) return;
    
    try {
      await _userService.acceptFollowRequest(
        currentUserId,
        notification.relatedUserId!,
      );
      
      // Bildirimi sil ve yenisini ekle (type'ı değiştirmek yerine)
      await _userService.markNotificationAsRead(notification.id);
      
      if (mounted) {
        final currentContext = context;
        final authVM = Provider.of<AuthViewModel>(currentContext, listen: false);
        await authVM.refreshUserProfile();
        if (mounted) {
          ModernSnackbar.showSuccess(currentContext, 'Takip isteği kabul edildi ✓');
        }
      }
    } catch (e) {
      if (mounted) {
        final currentContext = context;
        ModernSnackbar.showError(currentContext, 'Hata: ${e.toString()}');
      }
    }
  }

  /// Takip isteğini reddet
  Future<void> _rejectFollowRequest(String currentUserId, NotificationEntity notification) async {
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

}

