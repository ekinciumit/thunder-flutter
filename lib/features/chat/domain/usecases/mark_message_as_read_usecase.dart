import '../../../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

/// Mark Message As Read Use Case
/// 
/// Clean Architecture Domain Layer
/// Mesajı okundu olarak işaretleme iş kuralını içerir.
class MarkMessageAsReadUseCase {
  final ChatRepository _repository;

  MarkMessageAsReadUseCase(this._repository);

  /// Mesajı okundu olarak işaretle
  /// 
  /// Returns: Either<Failure, void>
  Future<Either<Failure, void>> call(String messageId, String userId) async {
    // Business logic: Validation
    if (messageId.isEmpty || userId.isEmpty) {
      return Either.left(ValidationFailure('Mesaj ID ve kullanıcı ID boş olamaz'));
    }

    return await _repository.markMessageAsRead(messageId, userId);
  }
}

