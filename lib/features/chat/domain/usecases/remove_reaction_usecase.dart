import '../../../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

/// Remove Reaction Use Case
/// 
/// Clean Architecture Domain Layer
/// Mesaj tepkisini kaldırma iş kuralını içerir.
class RemoveReactionUseCase {
  final ChatRepository _repository;

  RemoveReactionUseCase(this._repository);

  /// Mesaj tepkisini kaldır
  /// 
  /// Returns: Either<Failure, void>
  Future<Either<Failure, void>> call(String messageId, String userId, String emoji) async {
    // Business logic: Validation
    if (messageId.isEmpty || userId.isEmpty || emoji.isEmpty) {
      return Either.left(ValidationFailure('Mesaj ID, kullanıcı ID ve emoji boş olamaz'));
    }

    return await _repository.removeReaction(messageId, userId, emoji);
  }
}

