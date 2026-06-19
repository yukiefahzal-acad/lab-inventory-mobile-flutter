import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_uas/core/cookie_handler.dart';

class ApiResponse<T> {
  final String status;
  final String message;
  final T? data;

  ApiResponse({required this.status, required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic)? fromJsonData,
  }) {
    return ApiResponse(
      status: json['status'] ?? 'error',
      message: json['message'] ?? 'Unknown error',
      data: json['data'] != null && fromJsonData != null
          ? fromJsonData(json['data'])
          : null,
    );
  }
}

class ApiService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://10.0.2.2/';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final infinityCookie = prefs.getString('infinity_cookie') ?? '';
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36',
      if (token != null) 'Authorization': 'Bearer $token',
      if (infinityCookie.isNotEmpty) 'Cookie': infinityCookie,
    };
  }

  static bool _isBlocked(http.Response response) {
    if (response.headers['content-type']?.contains('text/html') == true) {
      return true;
    }
    if (response.body.contains('aes.js') || response.body.contains('__test')) {
      return true;
    }
    return false;
  }

  static Future<ApiResponse<dynamic>> get(String endpoint, {bool isRetry = false}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );
      if (!isRetry && _isBlocked(response)) {
        await CookieHandler.fetchInfinityCookie();
        return get(endpoint, isRetry: true);
      }
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }

  static Future<ApiResponse<dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool isRetry = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
      if (!isRetry && _isBlocked(response)) {
        await CookieHandler.fetchInfinityCookie();
        return post(endpoint, body, isRetry: true);
      }
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }

  static Future<ApiResponse<dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool isRetry = false,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
      if (!isRetry && _isBlocked(response)) {
        await CookieHandler.fetchInfinityCookie();
        return put(endpoint, body, isRetry: true);
      }
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }

  static Future<ApiResponse<dynamic>> delete(
    String endpoint, [
    Map<String, dynamic>? body,
    bool isRetry = false,
  ]) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      if (!isRetry && _isBlocked(response)) {
        await CookieHandler.fetchInfinityCookie();
        return delete(endpoint, body, true);
      }
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }

  static Future<ApiResponse<dynamic>> uploadFile(
    String endpoint,
    Uint8List fileBytes,
    String fileName, {
    String fieldName = 'foto',
    bool isRetry = false,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );
      
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      request.files.add(http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: fileName,
      ));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      
      if (!isRetry && _isBlocked(response)) {
        await CookieHandler.fetchInfinityCookie();
        return uploadFile(endpoint, fileBytes, fileName, fieldName: fieldName, isRetry: true);
      }
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }

  static ApiResponse<dynamic> _processResponse(http.Response response) {
    print('========== API RESPONSE ==========');
    print('URL: ${response.request?.url}');
    print('Status Code: ${response.statusCode}');
    print('Response Headers: ${response.headers}');
    print('Response Body: ${response.body}');
    print('==================================');
    
    try {
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          status: decoded['status'] ?? 'success',
          message: decoded['message'] ?? 'Success',
          data: decoded['data'] ?? decoded,
        );
      } else {
        return ApiResponse(
          status: decoded['status'] ?? 'error',
          message: decoded['message'] ?? 'Error ${response.statusCode}',
          data: decoded['data'],
        );
      }
    } catch (e) {
      print('JSON Decode Error: $e');
      return ApiResponse(status: 'error', message: 'Invalid response format');
    }
  }
}
