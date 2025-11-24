import '../../../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

/// Update Typing Status Use Case
/// 
/// Clean Architecture Domain Layer
/// Yazıyor durumunu güncelleme iş kuralını içerir.
class UpdateTypingStatusUseCase {
  final ChatRepository _repository;

  UpdateTypingStatusUseCase(this._repository);

  /// Yazıyor durumunu güncelle
  /// 
  /// Returns: Either<Failure, void>
  Future<Either<Failure, void>> call(String chatId, String userId, bool isTyping) async {
    // Business logic: Validation
    if (chatId.isEmpty || userId.isEmpty) {
      return Either.left(ValidationFailure('Chat ID ve kullanıcı ID boş olamaz'));
    }

    return await _repository.updateTypingStatus(chatId, userId, isTyping);
  }
}

