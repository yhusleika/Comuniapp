import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hive_config.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getLastUser();
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  @override
  Future<void> cacheUser(UserModel user) async {
    final box = await Hive.openBox(HiveConfig.userBox);
    await box.put('current_user', user);
  }

  @override
  Future<UserModel?> getLastUser() async {
    if (!Hive.isBoxOpen(HiveConfig.userBox)) {
      await Hive.openBox(HiveConfig.userBox);
    }
    final box = Hive.box(HiveConfig.userBox);
    return box.get('current_user') as UserModel?;
  }
  
  @override
  Future<void> clearUser() async {
    final box = await Hive.openBox(HiveConfig.userBox);
    await box.clear();
  }
}
