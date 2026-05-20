import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/api_client.dart';

class AlatService {
  static Future<ApiResponse<dynamic>> fetchAlat() async {
    if (ApiClient.isSimulation) {
      return ApiResponse(
        status: 'success',
        message: 'Alat fetched (Simulation)',
        data: {
          'data': [
            {'id': 1, 'kode_alat': 'AL-001', 'nama_alat': 'Proyektor Epson', 'stok_total': 5, 'spesifikasi': '1080p', 'foto': ''},
            {'id': 2, 'kode_alat': 'AL-002', 'nama_alat': 'Multimeter Digital', 'stok_total': 10, 'spesifikasi': 'Fluke v1', 'foto': ''},
          ]
        },
      );
    }

    try {
      final response = await http.get(Uri.parse('${ApiClient.baseUrl}api/alat'), headers: await ApiClient.getHeaders());
      return ApiClient.processResponse(response);
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }

  static Future<ApiResponse<dynamic>> createAlat({
    required String kodeAlat,
    required String namaAlat,
    required int stokTotal,
    required String spesifikasi,
    File? imageFile,
  }) async {
    if (ApiClient.isSimulation) {
      return ApiResponse(status: 'success', message: 'Alat berhasil ditambahkan (Simulation)');
    }

    try {
      final uri = Uri.parse('${ApiClient.baseUrl}api/alat');
      final request = http.MultipartRequest('POST', uri);

      final headers = await ApiClient.getHeaders();
      request.headers.addAll(headers);

      request.fields['kode_alat'] = kodeAlat;
      request.fields['nama_alat'] = namaAlat;
      request.fields['stok_total'] = stokTotal.toString();
      request.fields['spesifikasi'] = spesifikasi;

      if (imageFile != null) {
        final multipartFile = await http.MultipartFile.fromPath('foto', imageFile.path);
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return ApiClient.processResponse(response);
    } catch (e) {
      return ApiResponse(status: 'error', message: e.toString());
    }
  }
}