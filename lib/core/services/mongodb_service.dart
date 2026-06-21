import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class MongoDBService {
  final Dio _dio;

  MongoDBService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    // URL del backend local (Cambia localhost por tu IP local si usas un dispositivo físico o 10.0.2.2 para emulador Android)
    baseUrl: 'http://localhost:3000/v1',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  )) {
    // Interceptor para logs reales
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('=== API REQUEST ===');
        debugPrint('-> [${options.method}] ${options.baseUrl}${options.path}');
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
}
