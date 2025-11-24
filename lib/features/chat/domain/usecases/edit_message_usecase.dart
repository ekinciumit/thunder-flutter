import '../../../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

/// Edit Message Use Case
/// 
/// Clean Architecture Domain Layer
/// Mesaj düzenleme iş kuralını içerir.
class EditMessageUseCase {
  final ChatRepository _repository;

  EditMessageUseCase(this._repository);

  /// Mesajı düzenle
  /// 
  /// Returns: ``Either<Failure, void>``
  Future<Either<Failure, void>> call(String messageId, String newText) async {
    // Business logic: Validation
    if (messageId.isEmpty) {
      return Either.left(ValidationFailure('Mesaj ID boş olamaz'));
    }
    if (newText.isEmpty) {
      return Either.left(ValidationFailure('Yeni metin boş olamaz'));
    }

    return await _repository.editMessage(messageId, newText);
  }
}

