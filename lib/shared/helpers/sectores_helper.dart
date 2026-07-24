import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../core/services/mongodb_service.dart';
import '../../core/di/injection_container.dart';

class SectoresHelper {
  static final List<String> defaultSectores = [
    'Sector 1 - Centro',
    'Sector 2 - Norte',
    'Sector 3 - Sur',
    'Sector 4 - Este',
  ];

  static Future<List<String>> getAvailableSectores() async {
    final Set<String> sectoresSet = {};

    // 1. Cargar desde Hive local
    try {
      final box = await Hive.openBox('sectores_box');
      for (var val in box.values) {
        if (val is Map) {
          final nombre = (val['nombre'] ?? '').toString().trim();
          if (nombre.isNotEmpty) {
            sectoresSet.add(nombre);
          }
        }
      }
    } catch (e) {
      debugPrint('Error leyendo sectores de Hive: $e');
    }

    // 2. Intentar refrescar desde MongoDB remoto
    try {
      final mongoService = sl<MongoDBService>();
      final remoteSectores = await mongoService.getRecords('sectores');
      if (remoteSectores.isNotEmpty) {
        for (var s in remoteSectores) {
          final nombre = (s['nombre'] ?? '').toString().trim();
          if (nombre.isNotEmpty) {
            sectoresSet.add(nombre);
          }
        }
      }
    } catch (_) {}

    // 3. Fallback con sectores por defecto si estuviera vacío
    if (sectoresSet.isEmpty) {
      sectoresSet.addAll(defaultSectores);
    }

    final result = sectoresSet.toList();
    result.sort();
    return result;
  }
}
