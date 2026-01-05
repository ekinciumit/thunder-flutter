import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
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
import '../../domain/usecases/get_chat_by_id_usecase.dart';

/// ChatViewModel - Clean Architecture Implementation
/// 
/// Presentation Layer - State Management
/// Bu ViewModel Clean Architecture'ın presentation katmanında yer alır.
class ChatViewModel extends ChangeNotifier {
  String? error;
  bool isLoading = false;

  final ChatRepository _chatRepository;
  
  // Performance: Mesajları cache'le (chatId -> messages)
  final Map<String, List<MessageEntity>> _messagesCache = {};
  final Map<String, StreamSubscription<List<MessageEntity>>> _messageSubscriptions = {};

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
  late final GetChatByIdUseCase _getChatByIdUseCase;

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
    _getChatByIdUseCase = GetChatByIdUseCase(_chatRepository);
  }

  /// İki kullanıcı için benzersiz chatId üretir
  String getChatId(String userA, String userB) {
    return _chatRepository.getChatId(userA, userB);
  }

  /// Özel sohbet oluştur veya getir
  Future<ChatEntity?> getOrCreatePrivateChat(String userA, String userB) async {
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
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in getOrCreatePrivateChat: $e');
      }
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Grup sohbeti oluştur
  Future<ChatEntity?> createGroupChat({
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
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in createGroupChat: $e');
      }
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Mesaj gönder
  Future<MessageEntity?> sendMessage({
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
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in sendMessage: $e');
      }
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Mesajları stream olarak getir
  Stream<List<MessageEntity>> getMessagesStream(String chatId, {int limit = 50}) {
    return _getMessagesUseCase(chatId, limit: limit);
  }
  
  /// Performance: Cache'lenmiş mesajları getir (Selector için)
  List<MessageEntity> getMessagesForChat(String chatId) {
    return _messagesCache[chatId] ?? [];
  }
  
  /// Performance: Mesaj stream'ini başlat ve cache'le
  void startListeningToMessages(String chatId, {int limit = 50}) {
    // Eğer zaten dinleniyorsa, tekrar başlatma
    if (_messageSubscriptions.containsKey(chatId)) {
      return;
    }
    
    final subscription = getMessagesStream(chatId, limit: limit).listen(
      (messages) {
        _messagesCache[chatId] = messages;
        notifyListeners(); // Sadece mesajlar değiştiğinde notify et
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('❌ Chat messages stream error: $error');
        }
      },
    );
    
    _messageSubscriptions[chatId] = subscription;
  }
  
  /// Performance: Mesaj stream'ini durdur
  void stopListeningToMessages(String chatId) {
    _messageSubscriptions[chatId]?.cancel();
    _messageSubscriptions.remove(chatId);
    _messagesCache.remove(chatId);
  }

  /// Daha eski mesajları yükle
  Future<List<MessageEntity>> loadOlderMessages(
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
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in loadOlderMessages: $e');
      }
      error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Kullanıcının sohbetlerini getir
  Stream<List<ChatEntity>> getUserChats(String userId) {
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
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in markMessageAsRead: $e');
      }
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
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in deleteMessage: $e');
      }
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
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in editMessage: $e');
      }
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
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in updateTypingStatus: $e');
      }
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
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in addReaction: $e');
      }
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
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in removeReaction: $e');
      }
      error = e.toString();
      notifyListeners();
    }
  }

  /// Sesli mesaj gönder
  Future<MessageEntity?> sendVoiceMessage({
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
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in sendVoiceMessage: $e');
      }
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Dosya mesajı gönder
  Future<MessageEntity?> sendFileMessage({
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
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in sendFileMessage: $e');
      }
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Ses dosyasını yükle ve URL'ini döndür
  Future<String?> uploadVoiceMessage(String audioFilePath) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final result = await _chatRepository.uploadVoiceMessage(audioFilePath);
      return result.fold(
        (failure) {
          error = failure.message;
          isLoading = false;
          notifyListeners();
          return null;
        },
        (url) {
          isLoading = false;
          notifyListeners();
          return url;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in uploadVoiceMessage: $e');
      }
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Dosyayı yükle ve URL'ini döndür
  Future<String?> uploadFileMessage(String filePath, String fileName) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final result = await _chatRepository.uploadFileMessage(filePath, fileName);
      return result.fold(
        (failure) {
          error = failure.message;
          isLoading = false;
          notifyListeners();
          return null;
        },
        (url) {
          isLoading = false;
          notifyListeners();
          return url;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in uploadFileMessage: $e');
      }
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Chat medya (image/video) dosyasını yükle ve URL'ini döndür
  /// Progress callback ile progress güncellemesi yapılabilir
  Future<String?> uploadChatMedia(String filePath, String storagePath, {String? contentType, void Function(double progress)? onProgress}) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final result = await _chatRepository.uploadChatMedia(filePath, storagePath, contentType: contentType, onProgress: onProgress);
      return result.fold(
        (failure) {
          error = failure.message;
          isLoading = false;
          notifyListeners();
          return null;
        },
        (url) {
          isLoading = false;
          notifyListeners();
          return url;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in uploadChatMedia: $e');
      }
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Mesaj ilet
  Future<MessageEntity?> forwardMessage({
    required MessageEntity originalMessage,
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
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in forwardMessage: $e');
      }
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Mesajlarda arama yap
  Future<List<MessageEntity>> searchMessages(
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
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in searchMessages: $e');
      }
      error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Tüm sohbetlerde arama yap
  Future<List<MessageEntity>> searchAllMessages(
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
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in searchAllMessages: $e');
      }
      error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Chat ID'ye göre chat getir
  /// 
  /// Clean Architecture: UseCase kullanır
  Future<ChatEntity?> getChatById(String chatId) async {
    try {
      final result = await _getChatByIdUseCase(chatId);
      return result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
          return null;
        },
        (chat) {
          return chat;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ChatViewModel] Error in getChatById: $e');
      }
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    // Performance: Tüm stream subscription'ları iptal et
    for (final subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    _messageSubscriptions.clear();
    _messagesCache.clear();
    super.dispose();
  }
}

