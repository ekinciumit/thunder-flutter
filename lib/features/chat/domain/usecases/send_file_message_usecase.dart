import '../../../../core/errors/failures.dart';
import '../../../../models/message_model.dart';
import '../repositories/chat_repository.dart';

/// Send File Message Use Case
/// 
/// Clean Architecture Domain Layer
/// Dosya mesajı gönderme iş kuralını içerir.
class SendFileMessageUseCase {
  final ChatRepository _repository;

  SendFileMessageUseCase(this._repository);

  /// Dosya mesajı gönder
  /// 
  /// Returns: ``Either<Failure, MessageModel>``
  Future<Either<Failure, MessageModel>> call({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    String? fileExtension,
  }) async {
    // Business logic: Validation
    if (chatId.isEmpty) {
      return Either.left(ValidationFailure('Chat ID boş olamaz'));
    }
    if (senderId.isEmpty || senderName.isEmpty) {
      return Either.left(ValidationFailure('Gönderen bilgileri boş olamaz'));
    }
    if (fileUrl.isEmpty) {
      return Either.left(ValidationFailure('Dosya URL\'si boş olamaz'));
    }
    if (fileName.isEmpty) {
      return Either.left(ValidationFailure('Dosya adı boş olamaz'));
    }
    if (fileSize <= 0) {
      return Either.left(ValidationFailure('Dosya boyutu 0\'dan büyük olmalıdır'));
    }

    return await _repository.sendFileMessage(
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      fileExtension: fileExtension,
    );
  }
}

