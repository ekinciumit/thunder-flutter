import 'package:flutter/material.dart';
import '../../features/chat/domain/entities/message_entity.dart';
import '../../l10n/app_localizations.dart';
import 'message_renderer.dart';

/// Message list widget - displays messages in a scrollable list with pagination support
class MessageList extends StatelessWidget {
  final List<MessageEntity> messages;
  final String currentUserId;
  final String currentUserName;
  final ScrollController scrollController;
  final bool isLoadingOlderMessages;
  final String Function(MessageEntity) getDisplayName;
  final String Function(DateTime) formatMessageTime;
  final void Function(MessageEntity) onLongPress;
  final void Function(MessageEntity, String) onReactionTap;

  const MessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.currentUserName,
    required this.scrollController,
    required this.isLoadingOlderMessages,
    required this.getDisplayName,
    required this.formatMessageTime,
    required this.onLongPress,
    required this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)?.noMessagesYet ?? 'No messages yet'),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)?.sendFirstMessage ?? 'Send the first message!'),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      reverse: false, // Normal sıralama (en eski üstte, en yeni altta)
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (isLoadingOlderMessages ? 1 : 0),
      // Performance: Her item için unique key (rebuild optimizasyonu)
      itemExtent: null, // Variable height items
      cacheExtent: 500, // Cache optimization
      itemBuilder: (context, index) {
        // Loading indicator for older messages (en üstte)
        if (index == 0 && isLoadingOlderMessages) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final messageIndex = isLoadingOlderMessages ? index - 1 : index;
        final message = messages[messageIndex];

        // Silinen mesajları göster
        if (message.isDeleted) {
          return const SizedBox.shrink();
        }

        final isMe = message.senderId == currentUserId;

        return MessageRenderer(
          message: message,
          isMe: isMe,
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          getDisplayName: getDisplayName,
          formatMessageTime: formatMessageTime,
          onLongPress: onLongPress,
          onReactionTap: onReactionTap,
        );
      },
    );
  }
}

