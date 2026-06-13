import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class MongoDBService {
  final Dio _dio;

  MongoDBService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    baseUrl: 'https://api.comuniapp.org/v1',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  )) {
    // Add mock interceptor to simulate the remote MongoDB Atlas REST API
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        debugPrint('=== MONGODB REMOTE API SERVICE ===');
        debugPrint('Request: [${options.method}] ${options.baseUrl}${options.path}');
        if (options.data != null) {
          debugPrint('Payload: ${options.data}');
        }
        // Simulate network latency
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Return a mock successful response with HTTP 200/201 and mock object details
        final mockResponse = Response(
          requestOptions: options,
          statusCode: options.method == 'POST' ? 201 : 200,
          data: {
            'success': true,
            'message': 'Operation simulated successfully in MongoDB Atlas REST API',
            'data': options.data ?? {},
          },
        );
        handler.resolve(mockResponse);
      },
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
}
