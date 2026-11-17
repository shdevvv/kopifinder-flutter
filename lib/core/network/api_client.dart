import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;
  final String? requestId;

  ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.requestId,
  });

  @override
  String toString() => 'ApiException [$statusCode | $code]: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _client = http.Client();
  final Duration _timeout = const Duration(seconds: 15);

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Map<String, String> _buildHeaders([Map<String, String>? extraHeaders]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = AppConfig.backendBaseUrl.endsWith('/')
        ? AppConfig.backendBaseUrl.substring(0, AppConfig.backendBaseUrl.length - 1)
        : AppConfig.backendBaseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$base$cleanPath';

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final sanitized = <String, String>{};
      queryParameters.forEach((key, value) {
        if (value != null) {
          sanitized[key] = value.toString();
        }
      });
      return Uri.parse(fullUrl).replace(queryParameters: sanitized);
    }
    return Uri.parse(fullUrl);
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final response = await _client
          .get(uri, headers: _buildHeaders(headers))
          .timeout(_timeout);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Tidak dapat terhubung ke server backend: ${e.message}');
    } on TimeoutException {
      throw NetworkException('Koneksi ke server timeout (15s). Silakan periksa jaringan Anda.');
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Tidak dapat terhubung ke server backend: ${e.message}');
    } on TimeoutException {
      throw NetworkException('Koneksi ke server timeout (15s).');
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final response = await _client
          .patch(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Tidak dapat terhubung ke server backend: ${e.message}');
    } on TimeoutException {
      throw NetworkException('Koneksi ke server timeout (15s).');
    }
  }

  Future<dynamic> delete(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final response = await _client
          .delete(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Tidak dapat terhubung ke server backend: ${e.message}');
    } on TimeoutException {
      throw NetworkException('Koneksi ke server timeout (15s).');
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = {'message': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    String code = 'API_ERROR';
    String message = 'Terjadi kesalahan pada server';
    String? requestId;

    if (decoded is Map<String, dynamic>) {
      if (decoded['error'] is Map) {
        final err = decoded['error'] as Map;
        code = err['code']?.toString() ?? code;
        message = err['message']?.toString() ?? message;
      } else if (decoded['message'] != null) {
        message = decoded['message'].toString();
      }
      if (decoded['meta'] is Map) {
        requestId = decoded['meta']['request_id']?.toString();
      }
    }

    throw ApiException(
      code: code,
      message: message,
      statusCode: response.statusCode,
      requestId: requestId,
    );
  }
}
