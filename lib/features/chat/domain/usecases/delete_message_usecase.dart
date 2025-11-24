import '../../../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

/// Delete Message Use Case
/// 
/// Clean Architecture Domain Layer
/// Mesaj silme iş kuralını içerir.
class DeleteMessageUseCase {
  final ChatRepository _repository;

  DeleteMessageUseCase(this._repository);

  /// Mesajı sil
  /// 
  /// Returns: ``Either<Failure, void>``
  Future<Either<Failure, void>> call(String messageId, String userId) async {
    // Business logic: Validation
    if (messageId.isEmpty || userId.isEmpty) {
      return Either.left(ValidationFailure('Mesaj ID ve kullanıcı ID boş olamaz'));
    }

    return await _repository.deleteMessage(messageId, userId);
  }
}

