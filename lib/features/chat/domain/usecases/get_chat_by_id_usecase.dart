import '../../../../core/errors/failures.dart';
import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

/// Get Chat By Id Use Case
/// 
/// Clean Architecture Domain Layer
/// Chat ID'ye göre chat getirme iş kuralını içerir.
class GetChatByIdUseCase {
  final ChatRepository _repository;

  GetChatByIdUseCase(this._repository);

  /// Chat ID'ye göre chat getir
  /// 
  /// Returns: `Either<Failure, ChatEntity?>`
  Future<Either<Failure, ChatEntity?>> call(String chatId) async {
    // Business logic: Validation
    if (chatId.isEmpty) {
      return Either.left(ValidationFailure('Chat ID boş olamaz'));
    }

    return await _repository.getChatById(chatId);
  }
}
