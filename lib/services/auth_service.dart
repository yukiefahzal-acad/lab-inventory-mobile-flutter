import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

class AuthService {
  static Future<ApiResponse<dynamic>> login(String nimNip, String password) async {
    if (ApiClient.isSimulation) {
      final role = (nimNip == 'admin') ? 'Admin' : 'Mahasiswa';
      return ApiResponse(
        status: 'success',
        message: 'Login berhasil (Simulation)',
        data: {'token': 'dummy_token_jwt_123', 'role': role, 'nama': 'User Simulasi'},
      );
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}api/login'),
        headers: await ApiClient.getHeaders(),
        body: jsonEncode({'nim_nip': nimNip, 'password': password}),
      );

      final apiResponse = ApiClient.processResponse(response);

      if (apiResponse.status == 'success' && apiResponse.data != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', apiResponse.data['token']);
        await prefs.setString('role', apiResponse.data['role']);
        await prefs.setString('nama', apiResponse.data['nama']);
      }
      return apiResponse;
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }

  static Future<ApiResponse<dynamic>> register(String nimNip, String nama, String role, String password) async {
    if (ApiClient.isSimulation) {
      return ApiResponse(status: 'success', message: 'Registrasi berhasil (Simulation)');
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}api/login'),
        body: jsonEncode({'nim_nip': nimNip, 'nama': nama, 'role': role, 'password': password}),
      );
      return ApiClient.processResponse(response);
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }

  static Future<void> logout() async {
    if (!ApiClient.isSimulation) {
      try {
        await http.post(Uri.parse('${ApiClient.baseUrl}api/logout'));
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('nama');
  }
}