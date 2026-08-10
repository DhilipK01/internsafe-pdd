import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:internsfe/core/config/env_config.dart';
import 'package:internsfe/data/api/api_exception.dart';
import 'package:internsfe/data/services/auth_token_storage.dart';

class ApiClient {
  ApiClient(this._tokenStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) {
          final msg = _messageFromDio(e);
          handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: ApiException(msg, statusCode: e.response?.statusCode),
            ),
          );
        },
      ),
    );
  }

  final AuthTokenStorage _tokenStorage;
  late final Dio _dio;

  Dio get dio => _dio;

  static String _messageFromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Check your network.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach server. Verify API_BASE_URL in .env.';
    }
    return e.message ?? 'Request failed';
  }

  Future<Map<String, dynamic>> getJson(String path,
      {Map<String, dynamic>? query}) async {
    final res = await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    Duration? receiveTimeout,
    Duration? connectTimeout,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      path,
      data: body,
      options: (receiveTimeout != null || connectTimeout != null)
          ? Options(
              receiveTimeout: receiveTimeout,
              sendTimeout: receiveTimeout,
              connectTimeout: connectTimeout,
            )
          : null,
    );
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(path, data: body);
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final res = await _dio.delete<Map<String, dynamic>>(path);
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> uploadFile({
    required String path,
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    required String uploadType,
  }) async {
    final form = FormData.fromMap({
      'uploadType': uploadType,
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    });
    final res = await _dio.post<Map<String, dynamic>>(path, data: form);
    return res.data ?? {};
  }
}
