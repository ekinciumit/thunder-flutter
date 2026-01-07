import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/chat/presentation/viewmodels/chat_viewmodel.dart';
import '../../../features/chat/domain/entities/message_entity.dart';

/// Helper class for chat pagination (loading older messages)
class ChatPaginationHelper {
  /// Setup scroll listener for pagination
  static void setupScrollListener({
    required ScrollController scrollController,
    required bool isLoadingOlderMessages,
    required bool hasMoreMessages,
    required VoidCallback onLoadOlderMessages,
  }) {
    scrollController.addListener(() {
      // Load older messages when near top
      if (scrollController.position.pixels <= 100 &&
          !isLoadingOlderMessages &&
          hasMoreMessages) {
        onLoadOlderMessages();
      }
    });
  }

  /// Load older messages
  static Future<ChatPaginationResult> loadOlderMessages({
    required BuildContext context,
    required String chatId,
    required List<MessageEntity> currentMessages,
    required ScrollController scrollController,
  }) async {
    if (chatId.isEmpty || currentMessages.isEmpty) {
      return ChatPaginationResult(
        messages: currentMessages,
        hasMore: true,
      );
    }

    try {
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      final oldestMessage = currentMessages.first;
      
      final olderMessages = await chatViewModel.loadOlderMessages(
        chatId,
        oldestMessage.timestamp,
        limit: 20,
      );

      if (olderMessages.isEmpty) {
        return ChatPaginationResult(
          messages: currentMessages,
          hasMore: false,
        );
      }

      // Preserve scroll position
      final scrollPosition = scrollController.hasClients
          ? scrollController.position.pixels
          : 0;
      
      final updatedMessages = [...olderMessages, ...currentMessages];
      
      // Restore scroll position after messages are loaded
      if (scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            final newScrollPosition =
                scrollController.position.maxScrollExtent - scrollPosition;
            scrollController.jumpTo(newScrollPosition);
          }
        });
      }

      return ChatPaginationResult(
        messages: updatedMessages,
        hasMore: true,
      );
    } catch (e) {
      // Return current messages on error
      return ChatPaginationResult(
        messages: currentMessages,
        hasMore: true,
      );
    }
  }
}

/// Result of pagination operation
class ChatPaginationResult {
  final List<MessageEntity> messages;
  final bool hasMore;

  ChatPaginationResult({
    required this.messages,
    required this.hasMore,
  });
}

