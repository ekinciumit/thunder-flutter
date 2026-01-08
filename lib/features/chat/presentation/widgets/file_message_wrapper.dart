import 'package:flutter/material.dart';
import '../../domain/entities/message_entity.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/modern_components.dart';
import 'file_message_widget.dart';
import 'message_reactions.dart';

/// Wrapper widget for file messages - includes avatar, sender name, timestamp, and reactions
class FileMessageWrapper extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final String currentUserId;
  final String currentUserName;
  final String Function(MessageEntity) getDisplayName;
  final String Function(DateTime) formatMessageTime;
  final void Function(MessageEntity) onLongPress;
  final void Function(MessageEntity, String) onReactionTap;

  const FileMessageWrapper({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    required this.currentUserName,
    required this.getDisplayName,
    required this.formatMessageTime,
    required this.onLongPress,
    required this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final fileExtension = message.metadata?['fileExtension'] as String?;

    return GestureDetector(
      onLongPress: () => onLongPress(message),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : Colors.grey[300],
                backgroundImage: message.senderPhotoUrl != null 
                    ? NetworkImage(message.senderPhotoUrl!)
                    : null,
                child: message.senderPhotoUrl == null
                    ? Text(
                        getDisplayName(message).isNotEmpty 
                            ? getDisplayName(message)[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? theme.colorScheme.onSurface
                              : Colors.black87,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Container(
              constraints: const BoxConstraints(maxWidth: 250),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(
                      message.senderName,
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
                  FileMessageWidget(
                    fileName: message.fileName ?? 'Bilinmeyen dosya',
                    fileUrl: message.fileUrl,
                    fileSize: message.fileSize,
                    fileExtension: fileExtension,
                    isMe: isMe,
                    onTap: () {
                      // Dosya açma/indirme özelliği gelecek versiyonda eklenecek
                      ModernSnackbar.showInfo(
                        context,
                        'Dosya açma özelliği yakında eklenecek',
                      );
                    },
                    onLongPress: () => onLongPress(message),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatMessageTime(message.timestamp),
                    style: TextStyle(
                      color: isDark
                          ? theme.colorScheme.onSurfaceVariant
                          : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  // Tepkiler
                  MessageReactions(
                    reactions: message.reactions,
                    currentUserId: currentUserId,
                    onReactionTap: (emoji) => onReactionTap(message, emoji),
                  ),
                ],
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark
                    ? theme.colorScheme.primaryContainer
                    : AppColorConfig.primaryColor.withAlpha(AppTheme.alphaLight),
                child: Text(
                  currentUserName.isNotEmpty 
                      ? currentUserName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? theme.colorScheme.onPrimaryContainer
                        : AppColorConfig.primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

