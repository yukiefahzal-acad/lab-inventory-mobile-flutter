import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import '../../core/api_service.dart';
// import '../../models/models.dart';
import '../../core/api_client.dart';
import '../../models/denda_model.dart';

class UserDendaScreen extends StatefulWidget {
  const UserDendaScreen({super.key});

  @override
  State<UserDendaScreen> createState() => _UserDendaScreenState();
}

class _UserDendaScreenState extends State<UserDendaScreen> {
  List<Denda> _dendaList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDenda();
  }

  Future<void> _fetchDenda() async {
    setState(() => _isLoading = true);
    // final res = await ApiService.get('api/user/denda');
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}api/user/denda'),
      headers: await ApiClient.getHeaders(),
    );
    final res = ApiClient.processResponse(response);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tagihan Denda Saya')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dendaList.isEmpty
              ? const Center(child: Text('Tidak ada denda.'))
              : ListView.builder(
                  itemCount: _dendaList.length,
                  itemBuilder: (context, index) {
                    final denda = _dendaList[index];
                    return ListTile(
                      title: Text('Peminjaman ID: ${denda.peminjamanId}'),
                      subtitle: Text('Jumlah: Rp ${denda.jumlah}'),
                      trailing: Text(
                        denda.status.toUpperCase(),
                        style: TextStyle(
                          // color: denda.status == 'unpaid' ? Colors.red : Colors.green,
                          color: denda.status == 'Belum Lunas' ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
