import '../../domain/repositories/user_repository_interface.dart';
import '../../domain/entities/user_entity.dart';

class GetUserUseCase {
  final IUserRepository repository;
  GetUserUseCase(this.repository);

  Future<UserEntity?> call(String uid) async {
    return await repository.getUser(uid);
  }
}
