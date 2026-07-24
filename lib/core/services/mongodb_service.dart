import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'hive_config.dart';
import '../../features/auth/data/models/user_model.dart';

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
      return kIsWeb 
          ? 'http://localhost:3000/v1' 
          : 'http://10.0.2.2:3000/v1';
    }
    
    // ===== PRODUCCIÓN =====
    // TODO: Reemplaza esta URL con la de tu servicio en Render.com
    // Ejemplo: https://comuniapp-api.onrender.com/v1
    return 'https://comuniapp-cmpr.onrender.com/v1';
  }

  MongoDBService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    baseUrl: _defaultBaseUrl,
    // Timeouts más largos para el tier gratuito de Render (cold start ~30s)
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  )) {
    debugPrint('🌐 API Base URL: ${_dio.options.baseUrl}');
    
    // Interceptor para autenticación mediante JWT y logs
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        debugPrint('=== API REQUEST ===');
        debugPrint('-> [${options.method}] ${options.baseUrl}${options.path}');
        
        try {
          const storage = FlutterSecureStorage();
          final token = await storage.read(key: 'jwt_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint('Injected Authorization Bearer Token');
          }
          if (Hive.isBoxOpen(HiveConfig.userBox)) {
            final box = Hive.box(HiveConfig.userBox);
            final user = box.get('current_user');
            if (user != null && user is UserModel) {
              options.headers['x-user-role'] = user.role;
              options.headers['x-username'] = user.username;
            }
          }
        } catch (e) {
          debugPrint('Error obteniendo token en Interceptor: $e');
        }

        if (options.data != null) {
          debugPrint('Payload: ${options.data}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('=== API RESPONSE ===');
        debugPrint('<- [${response.statusCode}] ${response.requestOptions.path}');
        debugPrint('Data: ${response.data}');
        handler.next(response);
      },
      onError: (DioException e, handler) {
        debugPrint('=== API ERROR ===');
        debugPrint('Error: ${e.message}');
        debugPrint('URL: ${e.requestOptions.baseUrl}${e.requestOptions.path}');
        handler.next(e);
      }
    ));
  }

  Future<bool> createRecord(String collection, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/$collection', data: data);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('MongoDB Remote API Error: $e');
      return false;
    }
  }

  Future<bool> updateRecord(String collection, String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/$collection/$id', data: data);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('MongoDB Remote API Error: $e');
      return false;
    }
  }

  Future<bool> deleteRecord(String collection, String id) async {
    try {
      final response = await _dio.delete('/$collection/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('MongoDB Remote API Error: $e');
      return false;
    }
  }

  Future<List<dynamic>> getRecords(String collection) async {
    try {
      final response = await _dio.get('/$collection');
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('MongoDB Remote API Error: $e');
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
    } catch (e) {
      debugPrint('MongoDB Remote API Error: $e');
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
}
