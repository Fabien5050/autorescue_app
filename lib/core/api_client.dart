import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'session.dart';

/// Thrown for any non-2xx response. [message] is the backend's
/// human-readable error, extracted from its `{timestamp,status,message}`
/// error body (see `GlobalExceptionHandler` on the backend).
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Thin wrapper over `package:http` for talking to the AutoRecue backend.
class ApiClient {
  ApiClient._();

  static final http.Client _client = http.Client();

  static Map<String, String> get _headers {
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final String? token = Session.instance.token;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  static Future<dynamic> get(String path) async {
    final http.Response response = await _client.get(
      _uri(path),
      headers: _headers,
    );
    return _decode(response);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final http.Response response = await _client.post(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final http.Response response = await _client.put(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final http.Response response = await _client.patch(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  /// Like [put], but for endpoints whose body is a raw JSON array rather
  /// than an object (e.g. `PUT /me/hours`).
  static Future<dynamic> putList(String path, List<dynamic> body) async {
    final http.Response response = await _client.put(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  static Future<dynamic> delete(String path) async {
    final http.Response response = await _client.delete(
      _uri(path),
      headers: _headers,
    );
    return _decode(response);
  }

  /// Multipart upload — `fields` are plain form fields, `file` is the
  /// binary payload under form field name `file`.
  static Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final http.MultipartRequest request = http.MultipartRequest(
      'POST',
      _uri(path),
    );
    final String? token = Session.instance.token;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    final http.StreamedResponse streamed = await request.send();
    final http.Response response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  static Future<dynamic> _decode(http.Response response) async {
    final bool ok = response.statusCode >= 200 && response.statusCode < 300;
    final String body = response.body;
    final dynamic decoded = body.isEmpty ? null : jsonDecode(body);

    if (!ok) {
      final String message = decoded is Map && decoded['message'] is String
          ? decoded['message'] as String
          : 'Request failed (${response.statusCode})';

      // A 401 on a request that carried a token means that token is no
      // longer valid (expired/revoked) — clear the stale session so the
      // app doesn't keep acting as if it's signed in. A 401 with no token
      // attached is just a public endpoint like /login rejecting bad
      // credentials, not a session problem, so it's left alone.
      if (response.statusCode == 401 && Session.instance.token != null) {
        await Session.instance.clear();
      }

      throw ApiException(message, statusCode: response.statusCode);
    }
    return decoded;
  }
}
