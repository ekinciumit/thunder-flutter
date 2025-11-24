import '../../../../core/errors/failures.dart';
import '../../../../models/chat_model.dart';
import '../repositories/chat_repository.dart';

/// Create Group Chat Use Case
/// 
/// Clean Architecture Domain Layer
/// Grup sohbeti oluşturma iş kuralını içerir.
class CreateGroupChatUseCase {
  final ChatRepository _repository;

  CreateGroupChatUseCase(this._repository);

  /// Grup sohbeti oluştur
  /// 
  /// Returns: ``Either<Failure, ChatModel>``
  Future<Either<Failure, ChatModel>> call({
    required String name,
    required String createdBy,
    required List<String> participants,
    String? description,
    String? photoUrl,
  }) async {
    // Business logic: Validation
    if (name.isEmpty) {
      return Either.left(ValidationFailure('Grup adı boş olamaz'));
    }
    if (createdBy.isEmpty) {
      return Either.left(ValidationFailure('Oluşturan kullanıcı ID\'si boş olamaz'));
    }
    if (participants.isEmpty) {
      return Either.left(ValidationFailure('En az bir katılımcı olmalıdır'));
    }
    if (!participants.contains(createdBy)) {
      return Either.left(ValidationFailure('Oluşturan kullanıcı katılımcılar arasında olmalıdır'));
    }

    return await _repository.createGroupChat(
      name: name,
      createdBy: createdBy,
      participants: participants,
      description: description,
      photoUrl: photoUrl,
    );
  }
}

