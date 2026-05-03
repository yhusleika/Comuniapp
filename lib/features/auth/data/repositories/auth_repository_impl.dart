import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, User>> login(String username, String password) async {
    try {
      // Admin user for verification
      if (username == 'admin' && password == 'admin') {
        final user = UserModel(
          id: 'admin_1',
          username: 'admin',
          role: 'admin',
          passwordHash: 'admin_hash',
        );
        await localDataSource.cacheUser(user);
        return Right(user);
      }

      final user = UserModel(
        id: '1',
        username: username,
        role: username.toLowerCase().contains('admin') ? 'admin' : 'vocero',
        passwordHash: 'mock_hash',
      );

      await localDataSource.cacheUser(user);
      return Right(user);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearUser();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await localDataSource.getLastUser();
      if (user != null) {
        return Right(user);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
