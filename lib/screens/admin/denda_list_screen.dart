import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';

class DendaListScreen extends StatefulWidget {
  final bool isTab;
  const DendaListScreen({super.key, this.isTab = false});

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
    final res = await ApiService.get('api/admin/denda');
    if (res.status == 'success' && res.data != null) {
      final List<dynamic> data = res.data;
      setState(() {
        _dendaList = data.map((e) => Denda.fromJson(e)).toList();
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res.message)));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateStatusLunas(int dendaId) async {
    final res = await ApiService.put('api/admin/denda/$dendaId/lunas', {});
    if (res.status == 'success') {
      _fetchDenda();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status denda diperbarui ke Lunas.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primaryLight),
          )
        : _dendaList.isEmpty
        ? Center(
            child: Text(
              'Tidak ada denda yang perlu divalidasi.',
              style: TextStyle(
                color: widget.isTab ? AppColors.white : AppColors.black,
                fontSize: 16,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _dendaList.length,
            itemBuilder: (context, index) {
              final denda = _dendaList[index];
              final isUnpaid = denda.status == 'unpaid';
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isTab
                      ? AppColors.white.withValues(alpha: 0.08)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isUnpaid
                        ? AppColors.errorBg
                        : AppColors.successBg,
                    child: Icon(
                      isUnpaid ? Icons.money_off : Icons.monetization_on,
                      color: isUnpaid ? AppColors.error : AppColors.success,
                    ),
                  ),
                  title: Text(
                    'User ID: ${denda.userId} | Pinjam ID: ${denda.peminjamanId}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.isTab ? AppColors.white : AppColors.black,
                    ),
                  ),
                  subtitle: Text(
                    'Rp ${denda.jumlah} | Status: ${denda.status}',
                    style: TextStyle(
                      color: widget.isTab ? AppColors.grey : AppColors.grey600,
                    ),
                  ),
                  trailing: isUnpaid
                      ? ElevatedButton(
                          onPressed: () => _updateStatusLunas(denda.id!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Set Lunas',
                            style: TextStyle(fontSize: 12),
                          ),
                        )
                      : const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                        ),
                ),
              );
            },
          );

    if (widget.isTab) {
      return Scaffold(
        backgroundColor: AppColors.darkSurface,
        body: bodyContent,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Validasi Denda')),
      body: bodyContent,
    );
  }
}
