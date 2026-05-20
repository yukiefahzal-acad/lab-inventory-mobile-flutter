import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_client.dart';

class PeminjamanService {
  static Future<ApiResponse<dynamic>> createBooking({
    required int alatId,
    required String tanggalPinjam,
    required String tanggalKembaliRencana,
  }) async {
    if (ApiClient.isSimulation) {
      return ApiResponse(status: 'success', message: 'Booking berhasil diajukan (Simulation)');
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}api/booking'),
        headers: await ApiClient.getHeaders(),
        body: jsonEncode({
          'alat_id': alatId,
          'tanggal_pinjam': tanggalPinjam,
          'tanggal_kembali_rencana': tanggalKembaliRencana,
        }),
      );
      return ApiClient.processResponse(response);
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }

  static Future<ApiResponse<dynamic>> fetchActivePeminjaman() async {
    if (ApiClient.isSimulation) {
      return ApiResponse(
        status: 'success',
        message: 'Active peminjaman fetched (Simulation)',
        data: {
          'data': [
            {'id': 1, 'alat_id': 1, 'tanggal_pinjam': '2026-05-10', 'tanggal_kembali_rencana': '2026-05-15', 'status': 'Menunggu'},
          ]
        },
      );
    }

    try {
      final response = await http.get(Uri.parse('${ApiClient.baseUrl}api/user/peminjaman/active'), headers: await ApiClient.getHeaders());
      return ApiClient.processResponse(response);
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }
}