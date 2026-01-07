import 'dart:io';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../mappers/chat_mapper.dart';
import '../mappers/message_mapper.dart';
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
  Future<Either<Failure, ChatEntity?>> getChatById(String chatId) async {
    try {
      final chatModel = await _remoteDataSource.getChatById(chatId);
      if (chatModel == null) {
        return Either.right(null);
      }
      // Model -> Entity dönüşümü
      final chatEntity = ChatMapper.toEntity(chatModel);
      return Either.right(chatEntity);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Chat getirilirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ChatEntity>> getOrCreatePrivateChat(String userA, String userB) async {
    try {
      final chatModel = await _remoteDataSource.getOrCreatePrivateChat(userA, userB);
      // Model -> Entity dönüşümü
      final chatEntity = ChatMapper.toEntity(chatModel);
      return Either.right(chatEntity);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Özel sohbet oluşturulurken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ChatEntity>> createGroupChat({
    required String name,
    required String createdBy,
    required List<String> participants,
    String? description,
    String? photoUrl,
  }) async {
    try {
      final chatModel = await _remoteDataSource.createGroupChat(
        name: name,
        createdBy: createdBy,
        participants: participants,
        description: description,
        photoUrl: photoUrl,
      );
      // Model -> Entity dönüşümü
      final chatEntity = ChatMapper.toEntity(chatModel);
      return Either.right(chatEntity);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Grup sohbeti oluşturulurken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> sendMessage({
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
      // Entity enum'u -> Model enum'a çevir
      final modelType = MessageMapper.messageTypeToModel(type);
      final messageModel = await _remoteDataSource.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        text: text,
        type: modelType,
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
      // DTO -> Entity dönüşümü
      return Either.right(MessageMapper.toEntity(messageModel));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Mesaj gönderilirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Stream<List<MessageEntity>> getMessagesStream(String chatId, {int limit = 50}) {
    try {
      // DTO stream'i -> Entity stream'e çevir
      return _remoteDataSource.getMessagesStream(chatId, limit: limit).map((messageModels) {
        return MessageMapper.toEntityList(messageModels);
      });
    } catch (e) {
      // Stream'ler için hata durumunda boş stream döndür
      return Stream.value(<MessageEntity>[]);
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> loadOlderMessages(
    String chatId,
    DateTime lastMessageTime, {
    int limit = 20,
  }) async {
    try {
      final messageModels = await _remoteDataSource.loadOlderMessages(chatId, lastMessageTime, limit: limit);
      // DTO -> Entity dönüşümü
      return Either.right(MessageMapper.toEntityList(messageModels));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Eski mesajlar yüklenirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Stream<List<ChatEntity>> getUserChats(String userId) {
    try {
      // DTO stream'i -> Entity stream'e çevir
      return _remoteDataSource.getUserChats(userId).map((chatModels) {
        return ChatMapper.toEntityList(chatModels);
      });
    } catch (e) {
      // Stream'ler için hata durumunda boş stream döndür
      return Stream.value(<ChatEntity>[]);
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
  Future<Either<Failure, MessageEntity>> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String audioUrl,
    required Duration duration,
  }) async {
    try {
      final messageModel = await _remoteDataSource.sendVoiceMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        audioUrl: audioUrl,
        duration: duration,
      );
      // DTO -> Entity dönüşümü
      return Either.right(MessageMapper.toEntity(messageModel));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Sesli mesaj gönderilirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> sendFileMessage({
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
      final messageModel = await _remoteDataSource.sendFileMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        fileExtension: fileExtension,
      );
      // DTO -> Entity dönüşümü
      return Either.right(MessageMapper.toEntity(messageModel));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Dosya mesajı gönderilirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> forwardMessage({
    required MessageEntity originalMessage,
    required String targetChatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
  }) async {
    try {
      // Entity -> DTO dönüşümü
      final originalMessageModel = MessageMapper.toModel(originalMessage);
      final messageModel = await _remoteDataSource.forwardMessage(
        originalMessage: originalMessageModel,
        targetChatId: targetChatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
      );
      // DTO -> Entity dönüşümü
      return Either.right(MessageMapper.toEntity(messageModel));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Mesaj iletilemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> searchMessages(
    String chatId,
    String query, {
    int limit = 50,
  }) async {
    try {
      final messageModels = await _remoteDataSource.searchMessages(chatId, query, limit: limit);
      // DTO -> Entity dönüşümü
      return Either.right(MessageMapper.toEntityList(messageModels));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Mesajlar aranırken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> searchAllMessages(
    String userId,
    String query, {
    int limit = 100,
  }) async {
    try {
      final messageModels = await _remoteDataSource.searchAllMessages(userId, query, limit: limit);
      // DTO -> Entity dönüşümü
      return Either.right(MessageMapper.toEntityList(messageModels));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Tüm mesajlar aranırken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadVoiceMessage(String audioFilePath, {required String chatId, required String senderId}) async {
    try {
      final file = File(audioFilePath);
      final url = await _remoteDataSource.uploadVoiceMessage(file, chatId: chatId, senderId: senderId);
      return Either.right(url);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Ses dosyası yüklenirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadFileMessage(String filePath, String fileName, {required String chatId, required String senderId}) async {
    try {
      final file = File(filePath);
      final url = await _remoteDataSource.uploadFileMessage(file, fileName, chatId: chatId, senderId: senderId);
      return Either.right(url);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Dosya yüklenirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadChatMedia(String filePath, String storagePath, {String? contentType, void Function(double progress)? onProgress}) async {
    try {
      final file = File(filePath);
      final url = await _remoteDataSource.uploadChatMedia(file, storagePath, contentType: contentType, onProgress: onProgress);
      return Either.right(url);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Medya dosyası yüklenirken bir hata oluştu: ${e.toString()}'));
    }
  }
}

/// Factory function for creating ChatRepositoryImpl
Future<ChatRepository> createChatRepository() async {
  return ChatRepositoryImpl(
    remoteDataSource: ChatRemoteDataSourceImpl(),
  );
}

