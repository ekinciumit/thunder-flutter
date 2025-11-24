import '../../../../core/errors/failures.dart';
import '../../../../models/message_model.dart';
import '../repositories/chat_repository.dart';

/// Send Voice Message Use Case
/// 
/// Clean Architecture Domain Layer
/// Sesli mesaj gönderme iş kuralını içerir.
class SendVoiceMessageUseCase {
  final ChatRepository _repository;

  SendVoiceMessageUseCase(this._repository);

  /// Sesli mesaj gönder
  /// 
  /// Returns: ``Either<Failure, MessageModel>``
  Future<Either<Failure, MessageModel>> call({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String audioUrl,
    required Duration duration,
  }) async {
    // Business logic: Validation
    if (chatId.isEmpty) {
      return Either.left(ValidationFailure('Chat ID boş olamaz'));
    }
    if (senderId.isEmpty || senderName.isEmpty) {
      return Either.left(ValidationFailure('Gönderen bilgileri boş olamaz'));
    }
    if (audioUrl.isEmpty) {
      return Either.left(ValidationFailure('Ses URL\'si boş olamaz'));
    }
    if (duration.inMilliseconds <= 0) {
      return Either.left(ValidationFailure('Ses süresi 0\'dan büyük olmalıdır'));
    }

    return await _repository.sendVoiceMessage(
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      audioUrl: audioUrl,
      duration: duration,
    );
  }
}

