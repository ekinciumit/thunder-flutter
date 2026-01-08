import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../domain/entities/message_entity.dart';
import 'message_reactions.dart';

/// Message Bubble Widget
/// 
/// Text mesajları için reusable bubble widget
/// Dark mode'da otomatik glassmorphism uygular
class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final String displayName;
  final VoidCallback? onLongPress;
  final Function(String)? onReactionTap;
  final String currentUserId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.displayName,
    this.onLongPress,
    this.onReactionTap,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              _buildAvatar(message, isDark, theme),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: _buildBubbleContent(message, isMe, isDark, theme),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              _buildMyAvatar(displayName, isDark, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(MessageEntity message, bool isDark, ThemeData theme) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isDark
          ? theme.colorScheme.surfaceContainerHighest
          : Colors.grey[300],
      backgroundImage: message.senderPhotoUrl != null
          ? NetworkImage(message.senderPhotoUrl!)
          : null,
      child: message.senderPhotoUrl == null
          ? Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? theme.colorScheme.onSurface : Colors.black87,
              ),
            )
          : null,
    );
  }

  Widget _buildMyAvatar(String displayName, bool isDark, ThemeData theme) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isDark
          ? theme.colorScheme.primaryContainer
          : AppColorConfig.primaryColor.withAlpha(AppTheme.alphaLight),
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark
              ? theme.colorScheme.onPrimaryContainer
              : AppColorConfig.primaryColor,
        ),
      ),
    );
  }

  Widget _buildBubbleContent(
    MessageEntity message,
    bool isMe,
    bool isDark,
    ThemeData theme,
  ) {
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isMe ? 20 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 20),
    );

    if (isDark) {
      // Dark mode: Glassmorphism
      return GlassContainer(
        customBorderRadius: borderRadius,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        blurStrength: 20,
        glassAlpha: isMe
            ? AppTheme.glassAlphaPrimary
            : AppTheme.glassAlphaVeryLight,
        borderAlpha: isMe
            ? AppTheme.glassAlphaDark
            : AppTheme.glassAlphaMedium,
        backgroundColor: isMe
            ? AppColorConfig.primaryColor.withValues(alpha: AppTheme.glassAlphaPrimary)
            : null,
        borderColor: isMe
            ? AppColorConfig.primaryColor.withValues(alpha: AppTheme.glassAlphaDark)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        child: _buildMessageContent(message, isMe, isDark, theme),
      );
    } else {
      // Light mode: Normal container
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColorConfig.primaryColor : Colors.grey[200],
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildMessageContent(message, isMe, isDark, theme),
      );
    }
  }

  Widget _buildMessageContent(
    MessageEntity message,
    bool isMe,
    bool isDark,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe) ...[
          Text(
            displayName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isDark
                  ? theme.colorScheme.primary
                  : AppColorConfig.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          message.text ?? '',
          style: TextStyle(
            color: isMe
                ? (isDark ? theme.colorScheme.onPrimary : Colors.white)
                : (isDark ? theme.colorScheme.onSurface : Colors.black87),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatMessageTime(message.timestamp),
              style: TextStyle(
                color: isMe
                    ? (isDark
                        ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                        : Colors.white70)
                    : (isDark
                        ? theme.colorScheme.onSurfaceVariant
                        : Colors.grey[600]),
                fontSize: 11,
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 4),
              Icon(
                _getMessageStatusIcon(message.status),
                size: 12,
                color: isDark
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                    : Colors.white70,
              ),
            ],
          ],
        ),
        // Tepkiler
        if (message.reactions.isNotEmpty)
          MessageReactions(
            reactions: message.reactions,
            currentUserId: currentUserId,
            onReactionTap: onReactionTap,
          ),
      ],
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dk';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} sa';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  IconData _getMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      default:
        return Icons.access_time;
    }
  }
}

