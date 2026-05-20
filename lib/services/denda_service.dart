import 'package:http/http.dart' as http;
import '../core/api_client.dart';

class DendaService {
  static Future<ApiResponse<dynamic>> fetchUserDenda() async {
    if (ApiClient.isSimulation) {
      return ApiResponse(
        status: 'success',
        message: 'User denda fetched (Simulation)',
        data: {
          'data': [
            {'id': 1, 'peminjaman_id': 1, 'jumlah': 25000, 'status': 'Belum Lunas'},
          ]
        },
      );
    }

    try {
      final response = await http.get(Uri.parse('${ApiClient.baseUrl}api/user/denda'), headers: await ApiClient.getHeaders());
      return ApiClient.processResponse(response);
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }

  static Future<ApiResponse<dynamic>> fetchAdminDendaGlobal() async {
    if (ApiClient.isSimulation) {
      return ApiResponse(
        status: 'success',
        message: 'Admin denda global fetched (Simulation)',
        data: {
          'data': [
            {'id': 1, 'user_id': 2, 'peminjaman_id': 1, 'jumlah': 50000, 'status': 'Belum Lunas'},
          ]
        },
      );
    }

    try {
      final response = await http.get(Uri.parse('${ApiClient.baseUrl}api/admin/denda'), headers: await ApiClient.getHeaders());
      return ApiClient.processResponse(response);
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }
}