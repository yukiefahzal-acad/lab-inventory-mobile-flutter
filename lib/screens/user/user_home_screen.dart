import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_service.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';

class UserHomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToRiwayat;
  const UserHomeScreen({super.key, required this.onNavigateToRiwayat});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  bool _isLoading = true;
  bool _allowRefresh = true;
  String _userName = 'User';
  List<Peminjaman> _activeLoans = [];
  int _totalDendaUnpaid = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('nama') ?? 'User';
      });

      final res = await ApiService.get('api/peminjaman/riwayat');
      if (res.status == 'success' && res.data != null) {
        final data = res.data;
        final List<dynamic> listData = data is Map
            ? (data['data'] ?? [])
            : data;
        final allLoans = listData.map((e) => Peminjaman.fromJson(e)).toList();
        setState(() {
          _activeLoans = allLoans.where((p) {
            final s = p.status.toLowerCase();
            return s == 'disetujui';
          }).toList();
        });
      }

      final resDenda = await ApiService.get('api/user/denda');
      if (resDenda.status == 'success' && resDenda.data != null) {
        final List<dynamic> dendaData = (resDenda.data is Map)
            ? (resDenda.data['data'] ?? [])
            : (resDenda.data is List ? resDenda.data : []);
        int unpaidSum = 0;
        for (var item in dendaData) {
          final statusBayar = (item['status_bayar'] ?? '')
              .toString()
              .toLowerCase();
          if (statusBayar == 'belum lunas') {
            final double amt =
                double.tryParse((item['jumlah_denda'] ?? '0').toString()) ??
                0.0;
            unpaidSum += amt.toInt();
          }
        }
        setState(() {
          _totalDendaUnpaid = unpaidSum;
        });
      }
    } catch (e) {
      debugPrint("Error fetching home data: $e");
    } finally {
      if (showLoading) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  Widget _buildPlaceholderImage({double width = 80, double height = 80}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: height,
        color: AppColors.grey100,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 64,
          itemBuilder: (context, index) {
            final row = index ~/ 8;
            final col = index % 8;
            final isEven = (row + col) % 2 == 0;
            return Container(
              color: isEven ? AppColors.white : AppColors.grey300,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _fetchDashboardData(showLoading: false),
      color: AppColors.primary,
      notificationPredicate: (n) =>
          (n.depth == 0 || n.depth == 1) && _allowRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverAppBar(
            title: Text(
              'Dashboard',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            backgroundColor: AppColors.white,
            elevation: 0,
            pinned: true,
            automaticallyImplyLeading: false,
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat datang, $_userName',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kelola peminjaman dan denda Anda di sini.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Peminjaman Aktif',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_activeLoans.isNotEmpty)
                        TextButton(
                          onPressed: widget.onNavigateToRiwayat,
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.secondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(
                                color: AppColors.secondary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Lihat semua',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 16),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_activeLoans.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Anda tidak memiliki pinjaman',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    Listener(
                      onPointerDown: (_) => _allowRefresh = false,
                      onPointerUp: (_) => _allowRefresh = true,
                      onPointerCancel: (_) => _allowRefresh = true,
                      child: Column(
                        children: _activeLoans.take(3).map((loan) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                (() {
                                  final cachedAlat = Alat.cache[loan.alatId];
                                  final firstFoto = cachedAlat?.firstFoto;
                                  if (firstFoto != null &&
                                      firstFoto.isNotEmpty) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        firstFoto,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildPlaceholderImage(
                                                  width: 72,
                                                  height: 72,
                                                ),
                                      ),
                                    );
                                  }
                                  return _buildPlaceholderImage(
                                    width: 72,
                                    height: 72,
                                  );
                                })(),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kode: UNI-00${loan.alatId}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black,
                                        ),
                                      ),
                                      Text(
                                        'Dipinjam: ${loan.tanggalPinjam}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Jatuh tempo: ${loan.tanggalKembali}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Manajemen Denda Section
                  const Text(
                    'Manajemen Denda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Denda',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${_formatCurrency(_totalDendaUnpaid)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              'Status: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.black,
                              ),
                            ),
                            Text(
                              _totalDendaUnpaid > 0 ? 'Belum Lunas' : 'Lunas',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _totalDendaUnpaid > 0
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.grey200, height: 1),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _totalDendaUnpaid > 0
                                    ? 'Segera lunasi denda Anda untuk menghindari pembatasan peminjaman!'
                                    : 'Bayar denda tepat waktu untuk menghindari pembatasan peminjaman!',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
