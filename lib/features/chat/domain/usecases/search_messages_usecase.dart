import '../../../../core/errors/failures.dart';
import '../../../../models/message_model.dart';
import '../repositories/chat_repository.dart';

/// Search Messages Use Case
/// 
/// Clean Architecture Domain Layer
/// Mesajlarda arama yapma iş kuralını içerir.
class SearchMessagesUseCase {
  final ChatRepository _repository;

  SearchMessagesUseCase(this._repository);

  /// Mesajlarda arama yap
  /// 
  /// Returns: `Either<Failure, List<MessageModel>>`
  Future<Either<Failure, List<MessageModel>>> call(
    String chatId,
    String query, {
    int limit = 50,
  }) async {
    // Business logic: Validation
    if (chatId.isEmpty) {
      return Either.left(ValidationFailure('Chat ID boş olamaz'));
    }
    if (query.trim().isEmpty) {
      return Either.left(ValidationFailure('Arama sorgusu boş olamaz'));
    }
    if (limit <= 0) {
      return Either.left(ValidationFailure('Limit 0\'dan büyük olmalıdır'));
    }
    if (limit > 200) {
      return Either.left(ValidationFailure('Limit 200\'den küçük olmalıdır'));
    }

    return await _repository.searchMessages(chatId, query, limit: limit);
  }
}

