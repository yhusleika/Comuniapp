import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<Either<Failure, User>> getUserProfile(String username);
  Future<Either<Failure, User>> updateProfile({
    required User user,
    File? imageFile,
    String? newPassword,
  });
}
