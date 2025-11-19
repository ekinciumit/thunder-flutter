import '../../../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

/// Add Reaction Use Case
/// 
/// Clean Architecture Domain Layer
/// Mesaja tepki ekleme iş kuralını içerir.
class AddReactionUseCase {
  final ChatRepository _repository;

  AddReactionUseCase(this._repository);

  /// Mesaja tepki ekle
  /// 
  /// Returns: Either<Failure, void>
  Future<Either<Failure, void>> call(String messageId, String userId, String emoji) async {
    // Business logic: Validation
    if (messageId.isEmpty || userId.isEmpty || emoji.isEmpty) {
      return Either.left(ValidationFailure('Mesaj ID, kullanıcı ID ve emoji boş olamaz'));
    }

    return await _repository.addReaction(messageId, userId, emoji);
  }
}

