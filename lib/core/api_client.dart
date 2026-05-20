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
    // Menyesuaikan format response PHP backend kita yang langsung melempar data objek/array
    return ApiResponse(
      status: json['token'] != null || json['message'] != null ? 'success' : 'error',
      message: json['message'] ?? '',
      data: fromJsonData != null ? fromJsonData(json) : json as T?,
    );
  }
}

class ApiClient {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://10.0.2.2/labbackend/';
  static bool get isSimulation => dotenv.env['simulation_app'] == 'true' || dotenv.env['SIMULATION_APP'] == 'true';

  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static ApiResponse<dynamic> processResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(status: 'success', message: decoded['message'] ?? '', data: decoded);
      } else {
        return ApiResponse(
          status: 'error',
          message: decoded['message'] ?? 'Error ${response.statusCode}',
          data: decoded,
        );
      }
    } catch (e) {
      return ApiResponse(status: 'error', message: 'Format response server tidak valid');
    }
  }
}