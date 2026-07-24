import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/mongodb_service.dart';
import '../../../../core/services/hive_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, User>> login(String username, String password) async {
    final String cleanUsername = username.trim().toLowerCase();
    final String cleanPassword = password.trim();

    if (cleanUsername.isEmpty || cleanPassword.isEmpty) {
      return const Left(ServerFailure('Por favor ingrese usuario y contraseña'));
    }

    try {
      final mongo = sl<MongoDBService>();

      // 1. Intentar autenticación contra la API backend (MongoDB)
      try {
        final response = await mongo.dio.post('/users/login', data: {
          'username': cleanUsername,
          'password': cleanPassword,
        });

        if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
          final token = response.data['token'];
          if (token != null) {
            const storage = FlutterSecureStorage();
            await storage.write(key: 'jwt_token', value: token.toString());
          }

          final userData = response.data['data'] ?? {};
          final String roleRaw = (userData['role'] ?? '').toString().toLowerCase().trim();
          String role = 'visor';
          if (roleRaw.contains('admin')) {
            role = 'admin';
          } else if (roleRaw.contains('operador') || roleRaw.contains('vocero')) {
            role = 'operador';
          } else if (roleRaw.contains('visor') || roleRaw.contains('auditor')) {
            role = 'visor';
          } else if (roleRaw.isNotEmpty) {
            role = roleRaw;
          }

          final user = UserModel(
            id: userData['id'] ?? userData['_id'] ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
            username: userData['username'] ?? cleanUsername,
            role: role,
            nombres: (userData['nombres'] != null && userData['nombres'].toString().isNotEmpty)
                ? userData['nombres'].toString()
                : cleanUsername,
            apellidos: userData['apellidos']?.toString() ?? '',
            email: userData['email']?.toString() ?? '$cleanUsername@comuniapp.org',
            passwordHash: 'remote_hash',
          );

          // Guardar credenciales validadas localmente para poder operar offline si se va la red
          final recoveredBox = await Hive.openBox('recovered_credentials');
          await recoveredBox.put(cleanUsername, cleanPassword);

          await localDataSource.cacheUser(user);
          return Right(user);
        } else {
          final errorMsg = response.data?['error'] ?? 'Usuario o contraseña incorrectos';
          return Left(ServerFailure(errorMsg));
        }
      } on DioException catch (e) {
        if (e.response != null) {
          // El servidor respondió explícitamente con un error (ej. 401 Credenciales Inválidas)
          final errorMsg = e.response?.data is Map 
              ? (e.response?.data['error'] ?? 'Usuario o contraseña incorrectos') 
              : 'Usuario o contraseña incorrectos';
          return Left(ServerFailure(errorMsg.toString()));
        }
        // Si e.response es null, se debe a problemas de red/conexion. Procedemos al modo offline.
      }

      // 2. Modo Offline (Fallback solo cuando NO hay conexión con el backend)
      final recoveredBox = await Hive.openBox('recovered_credentials');
      
      // Credenciales default locales si aún no existen
      if (recoveredBox.get('admin') == null) {
        await recoveredBox.put('admin', 'admin');
      }

      final savedPassword = recoveredBox.get(cleanUsername);
      if (savedPassword != null && savedPassword == cleanPassword) {
        String role = 'visor';
        String nombres = cleanUsername;
        String apellidos = '';
        String email = '$cleanUsername@comuniapp.org';

        if (Hive.isBoxOpen(HiveConfig.userBox)) {
          final box = Hive.box(HiveConfig.userBox);
          for (var u in box.values) {
            if (u is UserModel && u.username.toLowerCase() == cleanUsername.toLowerCase()) {
              final r = u.role.toLowerCase().trim();
              if (r.contains('admin')) role = 'admin';
              else if (r.contains('operador') || r.contains('vocero')) role = 'operador';
              else role = 'visor';
              nombres = u.nombres ?? cleanUsername;
              apellidos = u.apellidos ?? '';
              email = u.email ?? '$cleanUsername@comuniapp.org';
              break;
            }
          }
        }

        if (role != 'admin' && role != 'operador') {
          final cleanLower = cleanUsername.toLowerCase();
          if (cleanLower.contains('admin')) role = 'admin';
          else if (cleanLower.contains('operador') || cleanLower.contains('vocero')) role = 'operador';
          else role = 'visor';
        }

        final user = UserModel(
          id: role == 'admin' ? 'admin_1' : 'usr_${DateTime.now().millisecondsSinceEpoch}',
          username: cleanUsername,
          role: role,
          nombres: nombres,
          apellidos: apellidos,
          email: email,
          passwordHash: 'local_hash',
        );
        await localDataSource.cacheUser(user);
        return Right(user);
      }

      return const Left(ServerFailure('Usuario o contraseña incorrectos'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearUser();
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'jwt_token');
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
