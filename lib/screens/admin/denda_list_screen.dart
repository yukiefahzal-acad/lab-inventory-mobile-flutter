import 'package:flutter/material.dart';
// import '../../core/api_service.dart';
// import '../../models/models.dart';
import 'package:http/http.dart' as http;
import '../../core/api_client.dart';
import '../../models/denda_model.dart';
import '../../services/denda_service.dart';

class DendaListScreen extends StatefulWidget {
  const DendaListScreen({super.key});

  @override
  State<DendaListScreen> createState() => _DendaListScreenState();
}

class _DendaListScreenState extends State<DendaListScreen> {
  List<Denda> _dendaList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDenda();
  }

  Future<void> _fetchDenda() async {
    setState(() => _isLoading = true);
    // final res = await ApiService.get('api/admin/denda');
    final res = await DendaService.fetchAdminDendaGlobal();
    if (res.status == 'success' && res.data != null) {
      // final List<dynamic> data = res.data;
      final List<dynamic> data = res.data['data'] ?? [];
      setState(() {
        _dendaList = data.map((e) => Denda.fromJson(e)).toList();
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateStatusLunas(int dendaId) async {
    // final res = await ApiService.put('api/admin/denda/$dendaId/lunas', {});
    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}api/admin/denda/$dendaId/lunas'),
      headers: await ApiClient.getHeaders(),
    );
    final res = ApiClient.processResponse(response);
    if (res.status == 'success') {
      _fetchDenda();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status denda diperbarui ke Lunas.')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validasi Denda')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _dendaList.length,
              itemBuilder: (context, index) {
                final denda = _dendaList[index];
                return ListTile(
                  title: Text('User ID: ${denda.userId} - Peminjaman: ${denda.peminjamanId}'),
                  subtitle: Text('Rp ${denda.jumlah} | Status: ${denda.status}'),
                  trailing: denda.status == 'Belum Lunas'
                      ? ElevatedButton(
                          onPressed: () => _updateStatusLunas(denda.id!),
                          child: const Text('Set Lunas'),
                        )
                      : const Icon(Icons.check_circle, color: Colors.green),
                );
              },
            ),
    );
  }
}
