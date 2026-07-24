import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/hive_config.dart';
import '../../../../core/services/mongodb_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final NetworkInfo networkInfo;
  final MongoDBService mongoDBService;
  final Dio dio; // We can use the dio from MongoDBService or pass it directly

  ProfileRepositoryImpl({
    required this.networkInfo,
    required this.mongoDBService,
    required this.dio,
  });

  @override
  Future<Either<Failure, User>> getUserProfile(String username) async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          final response = await dio.get('/users/profile/$username');
          if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
            final userModel = UserModel.fromJson(response.data['data']);
            // Cache locally
            final box = await Hive.openBox(HiveConfig.userBox);
            await box.put('current_user', userModel);
            return Right(userModel);
          }
        } catch (e) {
          debugPrint('Error fetching user profile from remote: $e');
        }
      }

      // Fetch from local cache if offline or error
      final box = await Hive.openBox(HiveConfig.userBox);
      final cached = box.get('current_user') as UserModel?;
      if (cached != null) {
        return Right(cached);
      }

      // Default mock if nothing is found
      return Right(User(
        id: '1',
        username: username,
        role: username.contains('admin') ? 'admin' : 'vocero',
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    required User user,
    File? imageFile,
    String? newPassword,
  }) async {
    try {
      final isConnected = await networkInfo.isConnected;
      UserModel updatedModel = UserModel.fromEntity(user);

      if (isConnected) {
        try {
          final Map<String, dynamic> dataMap = {
            'username': user.username,
            'role': user.role,
            'nombres': user.nombres ?? '',
            'apellidos': user.apellidos ?? '',
            'cedula': user.cedula ?? '',
            'email': user.email ?? '',
            'telefono': user.telefono ?? '',
          };

          if (newPassword != null && newPassword.isNotEmpty) {
            dataMap['password'] = newPassword;
          }

          if (imageFile != null) {
            final fileName = imageFile.path.split('/').last;
            dataMap['photo'] = await MultipartFile.fromFile(
              imageFile.path,
              filename: fileName,
            );
          }

          final formData = FormData.fromMap(dataMap);
          
          final response = await dio.put(
            '/users/profile',
            data: formData,
            options: Options(
              headers: {
                'x-username': user.username,
                'x-user-role': user.role,
              },
            ),
          );

          if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
            final responseData = response.data['data'];
            // Server responds with the updated user profile including the photoUrl.
            // If the photoUrl starts with /uploads, we prefix it with the API base URL to load correctly on Flutter
            String? photoUrl = responseData['photoUrl'];
            if (photoUrl != null && photoUrl.startsWith('/uploads')) {
              // Extract host from baseUrl
              final uri = Uri.parse(dio.options.baseUrl);
              photoUrl = '${uri.scheme}://${uri.host}:${uri.port}$photoUrl';
            }

            updatedModel = UserModel(
              id: user.id,
              username: user.username,
              role: user.role,
              nombres: responseData['nombres'] ?? user.nombres,
              apellidos: responseData['apellidos'] ?? user.apellidos,
              cedula: responseData['cedula'] ?? user.cedula,
              email: responseData['email'] ?? user.email,
              telefono: responseData['telefono'] ?? user.telefono,
              photoUrl: photoUrl ?? user.photoUrl,
            );
          }
        } catch (e) {
          debugPrint('Error updating profile on remote API: $e');
        }
      }

      // Save locally (always offline-first)
      final box = await Hive.openBox(HiveConfig.userBox);
      await box.put('current_user', updatedModel);

      // If password changed, update recovered_credentials too so offline login matches
      if (newPassword != null && newPassword.isNotEmpty) {
        final recoveredBox = await Hive.openBox('recovered_credentials');
        await recoveredBox.put(user.username, newPassword);
      }

      return Right(updatedModel);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
