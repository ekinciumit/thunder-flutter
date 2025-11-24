import '../../../../core/errors/failures.dart';
import '../../../../models/message_model.dart';
import '../repositories/chat_repository.dart';

/// Forward Message Use Case
/// 
/// Clean Architecture Domain Layer
/// Mesaj iletme iş kuralını içerir.
class ForwardMessageUseCase {
  final ChatRepository _repository;

  ForwardMessageUseCase(this._repository);

  /// Mesaj ilet
  /// 
  /// Returns: ``Either<Failure, MessageModel>``
  Future<Either<Failure, MessageModel>> call({
    required MessageModel originalMessage,
    required String targetChatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
  }) async {
    // Business logic: Validation
    if (targetChatId.isEmpty) {
      return Either.left(ValidationFailure('Hedef chat ID boş olamaz'));
    }
    if (senderId.isEmpty || senderName.isEmpty) {
      return Either.left(ValidationFailure('Gönderen bilgileri boş olamaz'));
    }
    if (originalMessage.chatId == targetChatId) {
      return Either.left(ValidationFailure('Mesaj aynı sohbete iletilemez'));
    }

    return await _repository.forwardMessage(
      originalMessage: originalMessage,
      targetChatId: targetChatId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
    );
  }
}

