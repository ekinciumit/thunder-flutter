import '../../../../core/errors/failures.dart';
import '../../../../models/message_model.dart';
import '../repositories/chat_repository.dart';

/// Send Message Use Case
/// 
/// Clean Architecture Domain Layer
/// Mesaj gönderme iş kuralını içerir.
class SendMessageUseCase {
  final ChatRepository _repository;

  SendMessageUseCase(this._repository);

  /// Mesaj gönder
  /// 
  /// Returns: ``Either<Failure, MessageModel>``
  Future<Either<Failure, MessageModel>> call({
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
    // Business logic: Validation
    if (chatId.isEmpty) {
      return Either.left(ValidationFailure('Chat ID boş olamaz'));
    }
    if (senderId.isEmpty || senderName.isEmpty) {
      return Either.left(ValidationFailure('Gönderen bilgileri boş olamaz'));
    }
    
    // Mesaj tipine göre validation
    if (type == MessageType.text && (text == null || text.isEmpty)) {
      return Either.left(ValidationFailure('Metin mesajı için metin boş olamaz'));
    }
    if (type == MessageType.image && imageUrl == null) {
      return Either.left(ValidationFailure('Resim mesajı için resim URL\'si gerekli'));
    }
    if (type == MessageType.file && (fileUrl == null || fileName == null)) {
      return Either.left(ValidationFailure('Dosya mesajı için dosya bilgileri gerekli'));
    }

    return await _repository.sendMessage(
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
  }
}

