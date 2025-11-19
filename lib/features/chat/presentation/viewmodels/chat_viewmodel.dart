import 'package:flutter/material.dart';
import '../../../../models/chat_model.dart';
import '../../../../models/message_model.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/get_or_create_private_chat_usecase.dart';
import '../../domain/usecases/create_group_chat_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/load_older_messages_usecase.dart';
import '../../domain/usecases/get_user_chats_usecase.dart';
import '../../domain/usecases/mark_message_as_read_usecase.dart';
import '../../domain/usecases/delete_message_usecase.dart';
import '../../domain/usecases/edit_message_usecase.dart';
import '../../domain/usecases/update_typing_status_usecase.dart';
import '../../domain/usecases/add_reaction_usecase.dart';
import '../../domain/usecases/remove_reaction_usecase.dart';
import '../../domain/usecases/send_voice_message_usecase.dart';
import '../../domain/usecases/send_file_message_usecase.dart';
import '../../domain/usecases/forward_message_usecase.dart';
import '../../domain/usecases/search_messages_usecase.dart';
import '../../domain/usecases/search_all_messages_usecase.dart';

/// ChatViewModel - Clean Architecture Implementation
/// 
/// Presentation Layer - State Management
/// Bu ViewModel Clean Architecture'ın presentation katmanında yer alır.
class ChatViewModel extends ChangeNotifier {
  String? error;
  bool isLoading = false;

  final ChatRepository _chatRepository;

  // Use Cases - Clean Architecture Domain Layer
  late final GetOrCreatePrivateChatUseCase _getOrCreatePrivateChatUseCase;
  late final CreateGroupChatUseCase _createGroupChatUseCase;
  late final SendMessageUseCase _sendMessageUseCase;
  late final GetMessagesUseCase _getMessagesUseCase;
  late final LoadOlderMessagesUseCase _loadOlderMessagesUseCase;
  late final GetUserChatsUseCase _getUserChatsUseCase;
  late final MarkMessageAsReadUseCase _markMessageAsReadUseCase;
  late final DeleteMessageUseCase _deleteMessageUseCase;
  late final EditMessageUseCase _editMessageUseCase;
  late final UpdateTypingStatusUseCase _updateTypingStatusUseCase;
  late final AddReactionUseCase _addReactionUseCase;
  late final RemoveReactionUseCase _removeReactionUseCase;
  late final SendVoiceMessageUseCase _sendVoiceMessageUseCase;
  late final SendFileMessageUseCase _sendFileMessageUseCase;
  late final ForwardMessageUseCase _forwardMessageUseCase;
  late final SearchMessagesUseCase _searchMessagesUseCase;
  late final SearchAllMessagesUseCase _searchAllMessagesUseCase;

  ChatViewModel({
    required ChatRepository chatRepository,
  }) : _chatRepository = chatRepository {
    _initializeUseCases();
  }

  /// Use Cases'i oluştur
  void _initializeUseCases() {
    _getOrCreatePrivateChatUseCase = GetOrCreatePrivateChatUseCase(_chatRepository);
    _createGroupChatUseCase = CreateGroupChatUseCase(_chatRepository);
    _sendMessageUseCase = SendMessageUseCase(_chatRepository);
    _getMessagesUseCase = GetMessagesUseCase(_chatRepository);
    _loadOlderMessagesUseCase = LoadOlderMessagesUseCase(_chatRepository);
    _getUserChatsUseCase = GetUserChatsUseCase(_chatRepository);
    _markMessageAsReadUseCase = MarkMessageAsReadUseCase(_chatRepository);
    _deleteMessageUseCase = DeleteMessageUseCase(_chatRepository);
    _editMessageUseCase = EditMessageUseCase(_chatRepository);
    _updateTypingStatusUseCase = UpdateTypingStatusUseCase(_chatRepository);
    _addReactionUseCase = AddReactionUseCase(_chatRepository);
    _removeReactionUseCase = RemoveReactionUseCase(_chatRepository);
    _sendVoiceMessageUseCase = SendVoiceMessageUseCase(_chatRepository);
    _sendFileMessageUseCase = SendFileMessageUseCase(_chatRepository);
    _forwardMessageUseCase = ForwardMessageUseCase(_chatRepository);
    _searchMessagesUseCase = SearchMessagesUseCase(_chatRepository);
    _searchAllMessagesUseCase = SearchAllMessagesUseCase(_chatRepository);
  }

  /// İki kullanıcı için benzersiz chatId üretir
  String getChatId(String userA, String userB) {
    return _chatRepository.getChatId(userA, userB);
  }

  /// Özel sohbet oluştur veya getir
  Future<ChatModel?> getOrCreatePrivateChat(String userA, String userB) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _getOrCreatePrivateChatUseCase(userA, userB);
      return result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
          return null;
        },
        (chat) {
          isLoading = false;
          notifyListeners();
          return chat;
        },
      );
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Grup sohbeti oluştur
  Future<ChatModel?> createGroupChat({
    required String name,
    required String createdBy,
    required List<String> participants,
    String? description,
    String? photoUrl,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _createGroupChatUseCase(
        name: name,
        createdBy: createdBy,
        participants: participants,
        description: description,
        photoUrl: photoUrl,
      );
      return result.fold(
        (failure) {
          error = failure.message;
          isLoading = false;
          notifyListeners();
          return null;
        },
        (chat) {
          isLoading = false;
          notifyListeners();
          return chat;
        },
      );
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Mesaj gönder
  Future<MessageModel?> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    String? text,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? gifUrl,
    String? stickerUrl,
    Map<String, dynamic>? location,
    Map<String, dynamic>? contact,
    String? replyToMessageId,
  }) async {
    try {
      final result = await _sendMessageUseCase(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        text: text,
        type: type,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        gifUrl: gifUrl,
        stickerUrl: stickerUrl,
        location: location,
        contact: contact,
        replyToMessageId: replyToMessageId,
      );
      return result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
          return null;
        },
        (message) {
          return message;
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Mesajları stream olarak getir
  Stream<List<MessageModel>> getMessagesStream(String chatId, {int limit = 50}) {
    return _getMessagesUseCase(chatId, limit: limit);
  }

  /// Daha eski mesajları yükle
  Future<List<MessageModel>> loadOlderMessages(
    String chatId,
    DateTime lastMessageTime, {
    int limit = 20,
  }) async {
    try {
      final result = await _loadOlderMessagesUseCase(chatId, lastMessageTime, limit: limit);
      return result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
          return [];
        },
        (messages) {
          return messages;
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Kullanıcının sohbetlerini getir
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _getUserChatsUseCase(userId);
  }

  /// Mesajı okundu olarak işaretle
  Future<void> markMessageAsRead(String messageId, String userId) async {
    try {
      final result = await _markMessageAsReadUseCase(messageId, userId);
      result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
        },
        (_) {
          // Başarılı
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  /// Mesajı sil
  Future<void> deleteMessage(String messageId, String userId) async {
    try {
      final result = await _deleteMessageUseCase(messageId, userId);
      result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
        },
        (_) {
          // Başarılı
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  /// Mesajı düzenle
  Future<void> editMessage(String messageId, String newText) async {
    try {
      final result = await _editMessageUseCase(messageId, newText);
      result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
        },
        (_) {
          // Başarılı
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  /// Yazıyor durumunu güncelle
  Future<void> updateTypingStatus(String chatId, String userId, bool isTyping) async {
    try {
      final result = await _updateTypingStatusUseCase(chatId, userId, isTyping);
      result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
        },
        (_) {
          // Başarılı
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  /// Mesaja tepki ekle
  Future<void> addReaction(String messageId, String userId, String emoji) async {
    try {
      final result = await _addReactionUseCase(messageId, userId, emoji);
      result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
        },
        (_) {
          // Başarılı
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  /// Mesaj tepkisini kaldır
  Future<void> removeReaction(String messageId, String userId, String emoji) async {
    try {
      final result = await _removeReactionUseCase(messageId, userId, emoji);
      result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
        },
        (_) {
          // Başarılı
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  /// Sesli mesaj gönder
  Future<MessageModel?> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String audioUrl,
    required Duration duration,
  }) async {
    try {
      final result = await _sendVoiceMessageUseCase(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        audioUrl: audioUrl,
        duration: duration,
      );
      return result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
          return null;
        },
        (message) {
          return message;
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Dosya mesajı gönder
  Future<MessageModel?> sendFileMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    String? fileExtension,
  }) async {
    try {
      final result = await _sendFileMessageUseCase(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        fileExtension: fileExtension,
      );
      return result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
          return null;
        },
        (message) {
          return message;
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Mesaj ilet
  Future<MessageModel?> forwardMessage({
    required MessageModel originalMessage,
    required String targetChatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
  }) async {
    try {
      final result = await _forwardMessageUseCase(
        originalMessage: originalMessage,
        targetChatId: targetChatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
      );
      return result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
          return null;
        },
        (message) {
          return message;
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Mesajlarda arama yap
  Future<List<MessageModel>> searchMessages(
    String chatId,
    String query, {
    int limit = 50,
  }) async {
    try {
      final result = await _searchMessagesUseCase(chatId, query, limit: limit);
      return result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
          return [];
        },
        (messages) {
          return messages;
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Tüm sohbetlerde arama yap
  Future<List<MessageModel>> searchAllMessages(
    String userId,
    String query, {
    int limit = 100,
  }) async {
    try {
      final result = await _searchAllMessagesUseCase(userId, query, limit: limit);
      return result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
          return [];
        },
        (messages) {
          return messages;
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return [];
    }
  }
}

