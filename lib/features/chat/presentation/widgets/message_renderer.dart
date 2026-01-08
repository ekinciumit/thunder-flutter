import 'package:flutter/material.dart';
import '../../domain/entities/message_entity.dart';
import 'message_bubble.dart';
import 'media_message_bubble.dart';
import 'voice_message_bubble.dart';
import 'file_message_wrapper.dart';

/// Message Renderer Widget
/// 
/// Renders different message types based on message content.
/// This widget centralizes the message type switching logic.
class MessageRenderer extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final String currentUserId;
  final String currentUserName;
  final String Function(MessageEntity) getDisplayName;
  final String Function(DateTime) formatMessageTime;
  final void Function(MessageEntity) onLongPress;
  final void Function(MessageEntity, String) onReactionTap;

  const MessageRenderer({
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
    // Performance: Her mesaj için unique key (Flutter rebuild optimizasyonu)
    final messageKey = ValueKey('message_${message.id}_${message.timestamp.millisecondsSinceEpoch}');
    
    // Message type'a göre render et
    if (message.imageUrl != null && message.imageUrl!.isNotEmpty) {
      return MediaMessageBubble(
        key: messageKey,
        message: message,
        isMe: isMe,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        getDisplayName: getDisplayName,
        formatMessageTime: formatMessageTime,
        onLongPress: () => onLongPress(message),
        onReactionTap: (emoji) => onReactionTap(message, emoji),
        isVideo: false,
      );
    } else if (message.videoUrl != null && message.videoUrl!.isNotEmpty) {
      return MediaMessageBubble(
        key: messageKey,
        message: message,
        isMe: isMe,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        getDisplayName: getDisplayName,
        formatMessageTime: formatMessageTime,
        onLongPress: () => onLongPress(message),
        onReactionTap: (emoji) => onReactionTap(message, emoji),
        isVideo: true,
      );
    } else if (message.audioUrl != null && message.audioUrl!.isNotEmpty) {
      return VoiceMessageBubble(
        key: messageKey,
        message: message,
        isMe: isMe,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        getDisplayName: getDisplayName,
        formatMessageTime: formatMessageTime,
        onLongPress: onLongPress,
        onReactionTap: onReactionTap,
      );
    } else if (message.fileUrl != null && message.fileUrl!.isNotEmpty) {
      return FileMessageWrapper(
        key: messageKey,
        message: message,
        isMe: isMe,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        getDisplayName: getDisplayName,
        formatMessageTime: formatMessageTime,
        onLongPress: onLongPress,
        onReactionTap: onReactionTap,
      );
    } else {
      // Metin mesajı (default)
      return MessageBubble(
        key: messageKey,
        message: message,
        isMe: isMe,
        displayName: getDisplayName(message),
        onLongPress: () => onLongPress(message),
        onReactionTap: (emoji) => onReactionTap(message, emoji),
        currentUserId: currentUserId,
      );
    }
  }
}

