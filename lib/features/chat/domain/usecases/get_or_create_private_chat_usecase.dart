import '../../../../core/errors/failures.dart';
import '../../../../models/chat_model.dart';
import '../repositories/chat_repository.dart';

/// Get Or Create Private Chat Use Case
/// 
/// Clean Architecture Domain Layer
/// Özel sohbet oluşturma veya getirme iş kuralını içerir.
class GetOrCreatePrivateChatUseCase {
  final ChatRepository _repository;

  GetOrCreatePrivateChatUseCase(this._repository);

  /// Özel sohbet oluştur veya getir
  /// 
  /// Returns: ``Either<Failure, ChatModel>``
  Future<Either<Failure, ChatModel>> call(String userA, String userB) async {
    // Business logic: Validation
    if (userA.isEmpty || userB.isEmpty) {
      return Either.left(ValidationFailure('Kullanıcı ID\'leri boş olamaz'));
    }
    if (userA == userB) {
      return Either.left(ValidationFailure('Aynı kullanıcı ile sohbet oluşturulamaz'));
    }

    return await _repository.getOrCreatePrivateChat(userA, userB);
  }
}

