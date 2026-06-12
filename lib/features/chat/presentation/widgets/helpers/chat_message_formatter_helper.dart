import '../../../domain/entities/message_entity.dart';

/// Helper class for formatting chat messages (time, display names)
class ChatMessageFormatterHelper {
  /// Format message timestamp
  static String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Get display name for message sender
  static String getDisplayName({
    required MessageEntity message,
    required String currentUserId,
    required String currentUserName,
    required String otherUserName,
  }) {
    // If senderName is "Kullanıcı" or empty, use correct name
    if (message.senderName == 'Kullanıcı' || message.senderName.isEmpty) {
      // Message from other user
      if (message.senderId != currentUserId) {
        return otherUserName.isNotEmpty ? otherUserName : 'Bilinmeyen';
      }
      // Message from current user
      return currentUserName.isNotEmpty ? currentUserName : 'Ben';
    }
    // Normal case: use senderName
    return message.senderName;
  }
}

