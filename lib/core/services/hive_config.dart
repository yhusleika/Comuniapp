import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/habitantes/data/models/habitante_model.dart';
import '../../features/reports/data/models/reporte_model.dart';
import '../../features/ayudas/data/models/ayuda_type_model.dart';
import '../../features/censos/data/models/censo_model.dart';
import '../../features/censos/data/models/censo_record_model.dart';
import '../../features/auditoria/data/models/audit_log_model.dart';
import '../../features/eventos/data/models/evento_model.dart';

class HiveConfig {
  static const _secureStorage = FlutterSecureStorage();
  static const String _encryptionKeyName = 'hive_master_encryption_key';

  /// Obtiene o genera la clave maestra de cifrado AES-256 desde el almacenamiento seguro del SO
  static Future<List<int>?> _getOrCreateEncryptionKey() async {
    if (kIsWeb) {
      // En Web, IndexedDB ofrece aislamiento por origen y evita bloqueos de FlutterSecureStorage
      return null;
    }
    try {
      final existingKey = await _secureStorage.read(key: _encryptionKeyName);
      if (existingKey != null && existingKey.isNotEmpty) {
        return base64Url.decode(existingKey);
      } else {
        final newKey = Hive.generateSecureKey();
        await _secureStorage.write(
          key: _encryptionKeyName,
          value: base64UrlEncode(newKey),
        );
        return newKey;
      }
    } catch (e) {
      debugPrint('Error al acceder al almacenamiento seguro, usando clave en memoria: $e');
      return Hive.generateSecureKey();
    }
  }

  static Future<Box> _openSafeBox(String name, {HiveAesCipher? cipher}) async {
    try {
      final box = await Hive.openBox(name, encryptionCipher: cipher);
      try {
        // Forzar la lectura de valores para detectar entradas cifradas o corruptas
        final _ = box.values.toList();
      } catch (e) {
        debugPrint('Error de lectura en datos de caja Hive $name: $e. Limpiando contenido corrupto...');
        await box.clear();
      }
      return box;
    } catch (e) {
      debugPrint('Error abriendo caja Hive $name: $e. Recreando la caja...');
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {}
      return await Hive.openBox(name, encryptionCipher: cipher);
    }
  }

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(HabitanteModelAdapter());
    Hive.registerAdapter(ReporteModelAdapter());
    Hive.registerAdapter(AyudaTypeModelAdapter());
    Hive.registerAdapter(CensoModelAdapter());
    Hive.registerAdapter(CensoRecordModelAdapter());
    Hive.registerAdapter(AuditLogModelAdapter());
    Hive.registerAdapter(EventoModelAdapter());

    final encryptionKey = await _getOrCreateEncryptionKey();
    final cipher = encryptionKey != null ? HiveAesCipher(encryptionKey) : null;

    await _openSafeBox(userBox, cipher: cipher);
    await _openSafeBox(habitantsBox, cipher: cipher);
    await _openSafeBox(reportsBox, cipher: cipher);
    await _openSafeBox(syncQueueBox, cipher: cipher);
    await _openSafeBox(ayudasBox, cipher: cipher);
    await _openSafeBox(censosBox, cipher: cipher);
    await _openSafeBox(censoRecordsBox, cipher: cipher);
    await _openSafeBox(auditoriaBox, cipher: cipher);
    await _openSafeBox(eventosBox, cipher: cipher);
    await _openSafeBox(recoveredCredentialsBox, cipher: cipher);
  }

  static const String habitantsBox = 'habitants';
  static const String reportsBox = 'reports';
  static const String syncQueueBox = 'sync_queue';
  static const String userBox = 'user_session';
  static const String ayudasBox = 'ayudas_types';
  static const String censosBox = 'censos';
  static const String censoRecordsBox = 'censo_records';
  static const String auditoriaBox = 'auditoria_logs';
  static const String eventosBox = 'eventos';
  static const String recoveredCredentialsBox = 'recovered_credentials';
}

