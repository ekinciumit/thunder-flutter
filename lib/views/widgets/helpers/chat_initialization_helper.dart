import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/chat/presentation/viewmodels/chat_viewmodel.dart';
import '../../../features/chat/domain/entities/message_entity.dart';

/// Helper class for chat initialization and message stream management
class ChatInitializationHelper {
  /// Initialize chat and get/create chat ID
  static Future<String?> initializeChat({
    required BuildContext context,
    required String currentUserId,
    required String otherUserId,
    required Function(String chatId) onChatIdSet,
  }) async {
    if (!context.mounted) return null;
    
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    
    try {
      final chat = await chatViewModel.getOrCreatePrivateChat(
        currentUserId,
        otherUserId,
      );
      
      if (!context.mounted) return null;
      
      if (chat != null) {
        onChatIdSet(chat.id);
        return chat.id;
      } else {
        // Fallback: Generate chat ID
        final fallbackChatId = chatViewModel.getChatId(currentUserId, otherUserId);
        onChatIdSet(fallbackChatId);
        return fallbackChatId;
      }
    } catch (e) {
      if (!context.mounted) return null;
      
      // Fallback: Generate chat ID on error
      final fallbackChatId = chatViewModel.getChatId(currentUserId, otherUserId);
      onChatIdSet(fallbackChatId);
      return fallbackChatId;
    }
  }

  /// Start listening to messages and load initial messages
  static void startListeningToMessages({
    required BuildContext context,
    required String chatId,
    required ScrollController scrollController,
    required Function(List<MessageEntity> messages) onMessagesLoaded,
  }) {
    if (!context.mounted) return;
    
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    chatViewModel.startListeningToMessages(chatId, limit: 50);
    
    // Load initial messages - sadece bir kez, addPostFrameCallback kullanma
    Future.microtask(() {
      if (!context.mounted) return;
      
      final cachedMessages = chatViewModel.getMessagesForChat(chatId);
      if (cachedMessages.isNotEmpty) {
        final sortedMessages = List<MessageEntity>.from(cachedMessages);
        sortedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        onMessagesLoaded(sortedMessages);
        
        // Scroll to bottom on initial load - WhatsApp gibi son mesajlara odaklan
        // WidgetsBinding kullanarak mesajlar render edildikten sonra scroll yap
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Bir frame daha bekle ki mesajlar tamamen render edilsin
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollController.hasClients && sortedMessages.isNotEmpty) {
              // En alta scroll yap
              scrollController.jumpTo(scrollController.position.maxScrollExtent);
            }
          });
        });
      }
    });
  }

  /// Stop listening to messages
  /// Note: This method should be called before widget is disposed
  /// If context is already disposed, use ChatViewModel directly
  static void stopListeningToMessages({
    required BuildContext context,
    required String chatId,
  }) {
    // Don't use context if widget is already disposed
    // Instead, get ViewModel from a global provider or pass it directly
    try {
      if (context.mounted) {
        final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
        chatViewModel.stopListeningToMessages(chatId);
      }
    } catch (e) {
      // Context already disposed, ignore
    }
  }
}

