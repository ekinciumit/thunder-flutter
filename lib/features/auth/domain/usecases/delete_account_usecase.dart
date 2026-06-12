import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class DeleteAccountUseCase {
  final AuthRepository _repository;

  DeleteAccountUseCase(this._repository);

  Future<Either<Failure, void>> call({required String password}) {
    return _repository.deleteAccount(password: password);
  }
}
