import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiResponse<T> {
  final String status;
  final String message;
  final T? data;

  ApiResponse({required this.status, required this.message, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json, {T Function(dynamic)? fromJsonData}) {
    return ApiResponse(
      status: json['status'] ?? 'error',
      message: json['message'] ?? 'Unknown error',
      data: json['data'] != null && fromJsonData != null ? fromJsonData(json['data']) : null,
    );
  }
}

class ApiService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://10.0.2.2/';
  
  static bool get _isSimulation => dotenv.env['simulation_app'] == 'true' || dotenv.env['SIMULATION_APP'] == 'true';

  static ApiResponse<dynamic> _getDummyResponse(String endpoint, String method, {Map<String, dynamic>? body}) {
    print('--- SIMULATION MODE: $method request to $endpoint intercepted ---');
    
    if (endpoint == 'api/login') {
      final role = (body != null && body['username'] == 'admin') ? 'admin' : 'user';
      return ApiResponse(
        status: 'success',
        message: 'Login successful (Simulation)',
        data: {'token': 'dummy_token_123', 'role': role},
      );
    }
    
    if (endpoint == 'api/register') {
      return ApiResponse(
        status: 'success',
        message: 'Registration successful (Simulation)',
        data: {'id': 1},
      );
    }

    if (endpoint == 'api/alat' && method == 'GET') {
      return ApiResponse(
        status: 'success',
        message: 'Alat fetched (Simulation)',
        data: [
          {'id': 1, 'nama': 'Proyektor Epson', 'deskripsi': 'Proyektor 1080p', 'status_awal': 'baik', 'qr_code': 'QR001'},
          {'id': 2, 'nama': 'Kabel HDMI 5m', 'deskripsi': 'Kabel HDMI panjang', 'status_awal': 'baik', 'qr_code': 'QR002'},
        ],
      );
    }
    
    if (endpoint == 'api/admin/denda' && method == 'GET') {
      return ApiResponse(
        status: 'success',
        message: 'Denda fetched (Simulation)',
        data: [
          {'id': 1, 'user_id': 2, 'peminjaman_id': 1, 'jumlah': 50000, 'status': 'unpaid'},
        ],
      );
    }

    if (endpoint == 'api/user/peminjaman/active' && method == 'GET') {
      return ApiResponse(
        status: 'success',
        message: 'Active peminjaman fetched (Simulation)',
        data: [
          {'id': 1, 'user_id': 1, 'alat_id': 1, 'tanggal_pinjam': '2026-05-10', 'tanggal_kembali': '2026-05-15', 'status': 'active'},
        ],
      );
    }

    if (endpoint == 'api/user/denda' && method == 'GET') {
      return ApiResponse(
        status: 'success',
        message: 'User denda fetched (Simulation)',
        data: [
          {'id': 1, 'user_id': 1, 'peminjaman_id': 1, 'jumlah': 25000, 'status': 'unpaid'},
        ],
      );
    }

    return ApiResponse(
      status: 'success',
      message: 'Simulation data for $endpoint',
      data: {
        'id': 999,
        'message': 'This is a generic simulated response',
      },
    );
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<ApiResponse<dynamic>> get(String endpoint) async {
    if (_isSimulation) return _getDummyResponse(endpoint, 'GET');
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders());
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }

  static Future<ApiResponse<dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    if (_isSimulation) return _getDummyResponse(endpoint, 'POST', body: body);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }

  static Future<ApiResponse<dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    if (_isSimulation) return _getDummyResponse(endpoint, 'PUT', body: body);
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }
  
  static Future<ApiResponse<dynamic>> delete(String endpoint) async {
    if (_isSimulation) return _getDummyResponse(endpoint, 'DELETE');
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }

  static ApiResponse<dynamic> _processResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.fromJson(decoded);
      } else {
        return ApiResponse(
          status: 'error',
          message: decoded['message'] ?? 'Error ${response.statusCode}',
          data: decoded['data'],
        );
      }
    } catch (e) {
      return ApiResponse(status: 'error', message: 'Invalid response format');
    }
  }
}
