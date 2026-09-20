import 'package:dio/dio.dart';

import '../config/env.dart';

class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: Env.apiBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {'content-type': 'application/json'},
              ),
            );

  final Dio _dio;

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _dio.get<Map<String, dynamic>>(path);
    return response.data ?? <String, dynamic>{};
  }

  /// Para endpoints que devuelven un array en la raiz (ej. GET
  /// /elections/public), a diferencia de [getJson] que solo tipa objetos.
  Future<List<dynamic>> getJsonList(String path) async {
    final response = await _dio.get<List<dynamic>>(path);
    return response.data ?? <dynamic>[];
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: body);
    return response.data ?? <String, dynamic>{};
  }
}
