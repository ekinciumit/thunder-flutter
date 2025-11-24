import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../models/chat_model.dart';
import '../../../../models/message_model.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

/// Chat Repository Implementation
/// 
/// Clean Architecture Data Layer
/// Domain repository interface'ini implement eder ve
/// Exception'ları Failure'lara çevirir.
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  String getChatId(String userA, String userB) {
    return _remoteDataSource.getChatId(userA, userB);
  }

  @override
  Future<Either<Failure, ChatModel>> getOrCreatePrivateChat(String userA, String userB) async {
    try {
      final chat = await _remoteDataSource.getOrCreatePrivateChat(userA, userB);
      return Either.right(chat);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Özel sohbet oluşturulurken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ChatModel>> createGroupChat({
    required String name,
    required String createdBy,
    required List<String> participants,
    String? description,
    String? photoUrl,
  }) async {
    try {
      final chat = await _remoteDataSource.createGroupChat(
        name: name,
        createdBy: createdBy,
        participants: participants,
        description: description,
        photoUrl: photoUrl,
      );
      return Either.right(chat);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Grup sohbeti oluşturulurken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, MessageModel>> sendMessage({
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
      final message = await _remoteDataSource.sendMessage(
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
      return Either.right(message);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Mesaj gönderilirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Stream<List<MessageModel>> getMessagesStream(String chatId, {int limit = 50}) {
    try {
      return _remoteDataSource.getMessagesStream(chatId, limit: limit);
    } catch (e) {
      // Stream'ler için hata durumunda boş stream döndür
      return Stream.value(<MessageModel>[]);
    }
  }

  @override
  Future<Either<Failure, List<MessageModel>>> loadOlderMessages(
    String chatId,
    DateTime lastMessageTime, {
    int limit = 20,
  }) async {
    try {
      final messages = await _remoteDataSource.loadOlderMessages(chatId, lastMessageTime, limit: limit);
      return Either.right(messages);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Eski mesajlar yüklenirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Stream<List<ChatModel>> getUserChats(String userId) {
    try {
      return _remoteDataSource.getUserChats(userId);
    } catch (e) {
      // Stream'ler için hata durumunda boş stream döndür
      return Stream.value(<ChatModel>[]);
    }
  }

  @override
  Future<Either<Failure, void>> markMessageAsRead(String messageId, String userId) async {
    try {
      await _remoteDataSource.markMessageAsRead(messageId, userId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Mesaj okundu olarak işaretlenirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageId, String userId) async {
    try {
      await _remoteDataSource.deleteMessage(messageId, userId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Mesaj silinirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> editMessage(String messageId, String newText) async {
    try {
      await _remoteDataSource.editMessage(messageId, newText);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Mesaj düzenlenirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTypingStatus(String chatId, String userId, bool isTyping) async {
    try {
      await _remoteDataSource.updateTypingStatus(chatId, userId, isTyping);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Yazıyor durumu güncellenirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> addReaction(String messageId, String userId, String emoji) async {
    try {
      await _remoteDataSource.addReaction(messageId, userId, emoji);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Tepki eklenirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> removeReaction(String messageId, String userId, String emoji) async {
    try {
      await _remoteDataSource.removeReaction(messageId, userId, emoji);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Tepki kaldırılırken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, MessageModel>> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String audioUrl,
    required Duration duration,
  }) async {
    try {
      final message = await _remoteDataSource.sendVoiceMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        audioUrl: audioUrl,
        duration: duration,
      );
      return Either.right(message);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Sesli mesaj gönderilirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, MessageModel>> sendFileMessage({
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
      final message = await _remoteDataSource.sendFileMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        fileExtension: fileExtension,
      );
      return Either.right(message);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Dosya mesajı gönderilirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, MessageModel>> forwardMessage({
    required MessageModel originalMessage,
    required String targetChatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
  }) async {
    try {
      final message = await _remoteDataSource.forwardMessage(
        originalMessage: originalMessage,
        targetChatId: targetChatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
      );
      return Either.right(message);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Mesaj iletilemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<MessageModel>>> searchMessages(
    String chatId,
    String query, {
    int limit = 50,
  }) async {
    try {
      final messages = await _remoteDataSource.searchMessages(chatId, query, limit: limit);
      return Either.right(messages);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Mesajlar aranırken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<MessageModel>>> searchAllMessages(
    String userId,
    String query, {
    int limit = 100,
  }) async {
    try {
      final messages = await _remoteDataSource.searchAllMessages(userId, query, limit: limit);
      return Either.right(messages);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Tüm mesajlar aranırken bir hata oluştu: ${e.toString()}'));
    }
  }
}

/// Factory function for creating ChatRepositoryImpl
Future<ChatRepository> createChatRepository() async {
  return ChatRepositoryImpl(
    remoteDataSource: ChatRemoteDataSourceImpl(),
  );
}

