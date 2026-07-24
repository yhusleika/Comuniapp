import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../services/mongodb_service.dart';
import '../services/hive_config.dart';
import '../di/injection_container.dart';
import '../../features/auth/data/models/user_model.dart';

class UserRolesHelper {
  static List<String> _dynamicOperadores = [];

  /// Permite actualizar manualmente la lista de operadores desde la DB o modales.
  static void updateOperadoresFromList(List<dynamic> users) {
    final ops = <String>[];
    for (var u in users) {
      if (u is Map) {
        final role = (u['role'] ?? '').toString().toLowerCase().trim();
        if (role == 'operador' || role.contains('operador') || role == 'admin' || role == 'vocero') {
          final nombres = (u['nombres'] ?? '').toString().trim();
          final apellidos = (u['apellidos'] ?? '').toString().trim();
          final username = (u['username'] ?? '').toString().trim();

          String displayName = username;
          if (nombres.isNotEmpty || apellidos.isNotEmpty) {
            displayName = '$nombres $apellidos'.trim();
          }
          if (displayName.isNotEmpty) {
            ops.add(displayName);
          }
        }
      }
    }
    if (ops.isNotEmpty) {
      _dynamicOperadores = ops.toSet().toList(); // Evitar duplicados
      _dynamicOperadores.sort();
    }
  }

  /// Carga de forma asíncrona los usuarios con rol operador/admin/vocero desde la API y Hive local.
  static Future<List<String>> fetchOperadoresAsync() async {
    final ops = <String>[];

    // 1. Intentar cargar desde Hive local si la caja está abierta
    try {
      if (Hive.isBoxOpen(HiveConfig.userBox)) {
        final box = Hive.box(HiveConfig.userBox);
        for (var u in box.values) {
          if (u is UserModel) {
            final role = u.role.toLowerCase().trim();
            if (role == 'operador' || role.contains('operador') || role == 'admin' || role == 'vocero') {
              final nombres = u.nombres ?? '';
              final apellidos = u.apellidos ?? '';
              final name = nombres.isNotEmpty
                  ? '$nombres $apellidos'.trim()
                  : u.username;
              if (name.isNotEmpty) ops.add(name);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error leyendo usuarios de Hive: $e');
    }

    // 2. Intentar cargar desde la API remota de MongoDB
    try {
      final mongo = sl<MongoDBService>();
      final users = await mongo.getUsers();
      for (var u in users) {
        if (u is Map) {
          final role = (u['role'] ?? '').toString().toLowerCase().trim();
          if (role == 'operador' || role.contains('operador') || role == 'admin' || role == 'vocero') {
            final nombres = (u['nombres'] ?? '').toString().trim();
            final apellidos = (u['apellidos'] ?? '').toString().trim();
            final username = (u['username'] ?? '').toString().trim();

            String displayName = username;
            if (nombres.isNotEmpty || apellidos.isNotEmpty) {
              displayName = '$nombres $apellidos'.trim();
            }
            if (displayName.isNotEmpty) ops.add(displayName);
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando usuarios remotos en UserRolesHelper: $e');
    }

    if (ops.isNotEmpty) {
      _dynamicOperadores = ops.toSet().toList();
      _dynamicOperadores.sort();
    }

    return getOperadores();
  }

  /// Retorna la lista de responsables con rol operador (dinámica o fallback por defecto).
  static List<String> getOperadores() {
    if (_dynamicOperadores.isNotEmpty) {
      return List<String>.from(_dynamicOperadores);
    }
    return [
      'Alejandro Colmenarez',
      'Gabriela Mendoza',
      'Ricardo Espinoza',
      'María Rodríguez',
      'Juan Pérez',
    ];
  }
}
