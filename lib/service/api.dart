import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  /// Hosted backend by default. Override for local development with:
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://jatiluxe-api.vercel.app',
  );
  static const String _authKey = "auth";

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      body = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String message = 'Terjadi kesalahan (${response.statusCode})';
    if (body is Map) {
      if (body['message'] != null) {
        message = body['message'].toString();
      } else if (body['error'] != null) {
        if (body['error'] is List && (body['error'] as List).isNotEmpty) {
          final firstIssue = (body['error'] as List).first;
          message = firstIssue is Map && firstIssue['message'] != null
              ? firstIssue['message'].toString()
              : body['error'].toString();
        } else {
          message = body['error'].toString();
        }
      }
    }
    throw Exception(message);
  }

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    String? fileField,
    String? filePath,
    Uint8List? fileBytes,
    String? filename,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl$endpoint'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (fileField != null) {
      if (fileBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            fileField,
            fileBytes,
            filename: filename ?? 'upload.jpg',
          ),
        );
      } else if (filePath != null && filePath.isNotEmpty) {
        if (kIsWeb) {
          throw Exception(
            'MultipartFile.fromPath is not supported on web. Provide fileBytes.',
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(fileField, filePath),
          );
        }
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  static Future<dynamic> putMultipart(
    String endpoint, {
    Map<String, String>? fields,
    String? fileField,
    String? filePath,
    Uint8List? fileBytes,
    String? filename,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$_baseUrl$endpoint'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (fileField != null) {
      if (fileBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            fileField,
            fileBytes,
            filename: filename ?? 'upload.jpg',
          ),
        );
      } else if (filePath != null && filePath.isNotEmpty) {
        if (kIsWeb) {
          throw Exception(
            'MultipartFile.fromPath is not supported on web. Provide fileBytes.',
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(fileField, filePath),
          );
        }
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }
}
