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
  bool _allowRefresh = true;

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res.message)));
      }
    }
    setState(() => _isLoading = false);
  }

  String _formatCurrency(double amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tagihan Denda Saya')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDenda,
              color: AppColors.primary,
              notificationPredicate: (n) => n.depth == 0 && _allowRefresh,
              child: Listener(
                onPointerDown: (_) => _allowRefresh = false,
                onPointerUp: (_) => _allowRefresh = true,
                onPointerCancel: (_) => _allowRefresh = true,
                child: _dendaList.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: const Center(child: Text('tidak ditemukan denda')),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _dendaList.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final denda = _dendaList[index];
                          final isUnpaid = denda.status.toLowerCase() != 'paid';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Peminjaman #${denda.peminjamanId}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.black,
                                          ),
                                        ),
                                        if (denda.namaAlat != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Alat: ${denda.namaAlat}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.black87,
                                            ),
                                          ),
                                        ],
                                        if (denda.jenisDenda != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            denda.jenisDenda!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.grey,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Rp ${_formatCurrency(denda.jumlah.toDouble())}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isUnpaid ? AppColors.error : AppColors.success,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isUnpaid ? AppColors.errorBg : AppColors.successBg,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isUnpaid ? 'Belum Lunas' : 'Lunas',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isUnpaid ? AppColors.error : AppColors.success,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
    );
  }
}
