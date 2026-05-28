import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';

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
    final res = await ApiService.get('api/user/denda');
    if (res.status == 'success' && res.data != null) {
      final List<dynamic> data = res.data;
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
                          color: denda.status == 'unpaid' ? AppColors.error : AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
