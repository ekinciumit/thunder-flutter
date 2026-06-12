import '../../../../core/errors/failures.dart';
import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

/// Search All Messages Use Case
/// 
/// Clean Architecture Domain Layer
/// Tüm sohbetlerde arama yapma iş kuralını içerir.
class SearchAllMessagesUseCase {
  final ChatRepository _repository;

  SearchAllMessagesUseCase(this._repository);

  /// Tüm sohbetlerde arama yap
  /// 
  /// Returns: `Either<Failure, List<MessageEntity>>`
  Future<Either<Failure, List<MessageEntity>>> call(
    String userId,
    String query, {
    int limit = 100,
  }) async {
    // Business logic: Validation
    if (userId.isEmpty) {
      return Either.left(ValidationFailure('Kullanıcı ID boş olamaz'));
    }
    if (query.trim().isEmpty) {
      return Either.left(ValidationFailure('Arama sorgusu boş olamaz'));
    }
    if (limit <= 0) {
      return Either.left(ValidationFailure('Limit 0\'dan büyük olmalıdır'));
    }
    if (limit > 500) {
      return Either.left(ValidationFailure('Limit 500\'den küçük olmalıdır'));
    }

    return await _repository.searchAllMessages(userId, query, limit: limit);
  }
}

