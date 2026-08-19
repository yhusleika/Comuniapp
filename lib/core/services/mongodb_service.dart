import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MongoDBService {
  final Dio _dio;
  Dio get dio => _dio;

  /// Determina la URL base de la API según el entorno.
  /// 
  /// Prioridad:
  /// 1. Si se pasa --dart-define=API_BASE_URL=..., se usa esa URL.
  /// 2. En debug web: http://localhost:3000/v1
  /// 3. En debug Android (emulador): http://10.0.2.2:3000/v1
  /// 4. En release (APK producción): URL pública de Render.com
  static String get _defaultBaseUrl {
    // Si el usuario pasó una URL explícita via --dart-define, usarla
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (kDebugMode) {
      // Desarrollo local
      final isAndroidEmulator = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      return isAndroidEmulator 
          ? 'http://10.0.2.2:3000/v1' 
          : 'http://localhost:3000/v1';
    }
    
    // ===== PRODUCCIÓN =====
    // TODO: Reemplaza esta URL con la de tu servicio en Render.com
    // Ejemplo: https://comuniapp-api.onrender.com/v1
    return 'https://comuniapp-cmpr.onrender.com/v1';
  }

  MongoDBService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    baseUrl: _defaultBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          const storage = FlutterSecureStorage();
          final token = await storage.read(key: 'jwt_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (DioException e, handler) {
        handler.next(e);
      }
    ));
  }

  Future<bool> createRecord(String collection, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/$collection', data: data);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateRecord(String collection, String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/$collection/$id', data: data);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteRecord(String collection, String id) async {
    try {
      final response = await _dio.delete('/$collection/$id');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> getRecords(String collection, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get('/$collection', queryParameters: queryParameters);
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dio.get('/stats');
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<List<dynamic>> getUsers() async {
    return getRecords('users');
  }

  Future<bool> createUser(Map<String, dynamic> userData) async {
    return createRecord('users', userData);
  }

  Future<bool> updateUser(String username, Map<String, dynamic> userData) async {
    return updateRecord('users', username, userData);
  }

  Future<bool> deleteUser(String username) async {
    return deleteRecord('users', username);
  }

  Future<bool> resetPassword(String username, String newPassword) async {
    try {
      final response = await _dio.post('/users/reset-password', data: {
        'username': username,
        'newPassword': newPassword,
      });
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Verifica si el servidor backend y Render están activos (Health check)
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health', options: Options(
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      ));
      return response.statusCode == 200;
    } catch (_) {
      try {
        final response = await _dio.get('/stats', options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ));
        return response.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
  }
}
