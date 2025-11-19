import '../../../../core/errors/failures.dart';
import '../../../../models/message_model.dart';
import '../repositories/chat_repository.dart';

/// Load Older Messages Use Case
/// 
/// Clean Architecture Domain Layer
/// Daha eski mesajları yükleme (pagination) iş kuralını içerir.
class LoadOlderMessagesUseCase {
  final ChatRepository _repository;

  LoadOlderMessagesUseCase(this._repository);

  /// Daha eski mesajları yükle
  /// 
  /// Returns: Either<Failure, List<MessageModel>>
  Future<Either<Failure, List<MessageModel>>> call(
    String chatId,
    DateTime lastMessageTime, {
    int limit = 20,
  }) async {
    // Business logic: Validation
    if (chatId.isEmpty) {
      return Either.left(ValidationFailure('Chat ID boş olamaz'));
    }
    if (limit <= 0) {
      return Either.left(ValidationFailure('Limit 0\'dan büyük olmalıdır'));
    }
    if (limit > 100) {
      return Either.left(ValidationFailure('Limit 100\'den küçük olmalıdır'));
    }

    return await _repository.loadOlderMessages(chatId, lastMessageTime, limit: limit);
  }
}

