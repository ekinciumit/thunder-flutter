import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/notification/domain/entities/notification_entity.dart';
import '../../features/user/domain/entities/user_entity.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_color_config.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl;

/// Notification item widget - displays a single notification
class NotificationItem extends StatelessWidget {
  final NotificationEntity notification;
  final UserEntity? user;
  final String currentUserId;
  final void Function(NotificationEntity) onTap;
  final Future<void> Function(String, NotificationEntity) onAcceptFollowRequest;
  final Future<void> Function(String, NotificationEntity) onRejectFollowRequest;

  const NotificationItem({
    super.key,
    required this.notification,
    this.user,
    required this.currentUserId,
    required this.onTap,
    required this.onAcceptFollowRequest,
    required this.onRejectFollowRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                _NotificationAvatar(notification: notification, user: user),
                const SizedBox(width: AppTheme.spacingMd),
                // İçerik - Flexible
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(notification),
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
          _FollowRequestActions(
            notification: notification,
            currentUserId: currentUserId,
            user: user,
            onAccept: () => onAcceptFollowRequest(currentUserId, notification),
            onReject: () => onRejectFollowRequest(currentUserId, notification),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'follow':
      case 'follow_request':
      case 'follow_request_accepted':
        return AppColorConfig.primaryColor;
      case 'event':
        return Colors.orange;
      case 'message':
      case 'message_request':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'follow':
      case 'follow_request':
      case 'follow_request_accepted':
        return Icons.person_add;
      case 'event':
        return Icons.event;
      case 'message':
      case 'message_request':
        return Icons.message;
      default:
        return Icons.notifications;
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
      return intl.DateFormat('dd MMM yyyy').format(date);
    }
  }
}

/// Notification avatar widget
class _NotificationAvatar extends StatelessWidget {
  final NotificationEntity notification;
  final UserEntity? user;

  const _NotificationAvatar({
    required this.notification,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);

    if (user != null && user!.photoUrl != null && user!.photoUrl!.isNotEmpty) {
      return Container(
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
            imageUrl: user!.photoUrl!,
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
      );
    }

    return Container(
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
      child: Icon(icon, color: color, size: 24),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'follow':
      case 'follow_request':
      case 'follow_request_accepted':
        return AppColorConfig.primaryColor;
      case 'event':
        return Colors.orange;
      case 'message':
      case 'message_request':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'follow':
      case 'follow_request':
      case 'follow_request_accepted':
        return Icons.person_add;
      case 'event':
        return Icons.event;
      case 'message':
      case 'message_request':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }
}

/// Follow request actions widget
class _FollowRequestActions extends StatelessWidget {
  final NotificationEntity notification;
  final String currentUserId;
  final UserEntity? user;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _FollowRequestActions({
    required this.notification,
    required this.currentUserId,
    this.user,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // Sadece follow_request tipindeyse ve relatedUserId varsa kontrol et
    if (notification.type != 'follow_request' || notification.relatedUserId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<UserEntity?>(
      stream: authViewModel.getAllUsersStream()
          .map((userEntities) {
            try {
              final userEntity = userEntities.firstWhere((u) => u.uid == currentUserId);
              return userEntity;
            } catch (_) {
              return user;
            }
          }),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final currentUserData = snapshot.data!;
        final pendingRequests = currentUserData.pendingFollowRequests;
        final followers = currentUserData.followers;

        final isPending = pendingRequests.contains(notification.relatedUserId);
        final isNowFollower = followers.contains(notification.relatedUserId);

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
                  Icon(Icons.check_circle_rounded, color: Colors.green[700], size: 20),
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
                    onPressed: onAccept,
                    icon: Icons.check_rounded,
                    label: 'Kabul Et',
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: _FollowActionButton(
                    onPressed: onReject,
                    icon: Icons.close_rounded,
                    label: 'Reddet',
                    isPrimary: false,
                  ),
                ),
              ],
            ),
          );
        }

        // İstek işlendi
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
}

/// Follow action button widget
class _FollowActionButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? AppColorConfig.primaryColor
            : theme.colorScheme.surfaceContainerHighest,
        foregroundColor: isPrimary
            ? Colors.white
            : theme.colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }
}

