import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';
import '../../widgets/alat_detail_modal.dart';

class UserRiwayatScreen extends StatefulWidget {
  const UserRiwayatScreen({super.key});

  @override
  State<UserRiwayatScreen> createState() => _UserRiwayatScreenState();
}

class _UserRiwayatScreenState extends State<UserRiwayatScreen> {
  List<Peminjaman> _allLoansList = [];
  Map<int, Denda> _userDendaMap = {};
  bool _isLoading = true;
  bool _allowRefresh = true;
  final TextEditingController _historySearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _historySearchCtrl.addListener(() {
      setState(() {});
    });
    _fetchRiwayat();
    // Cache alat will be used if already fetched in Katalog, otherwise we could fetch here
    // but the original code relies on Alat.cache.
  }

  @override
  void dispose() {
    _historySearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRiwayat({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    final res = await ApiService.get('api/peminjaman/riwayat');
    final resDenda = await ApiService.get('api/user/denda');
    
    if (res.status == 'success' && res.data != null) {
      final data = res.data;
      final List<dynamic> listData = data is Map ? (data['data'] ?? []) : data;
      
      Map<int, Denda> dendaMap = {};
      if (resDenda.status == 'success' && resDenda.data != null) {
        final dataDenda = resDenda.data;
        final List<dynamic> listDenda = dataDenda is Map ? (dataDenda['data'] ?? []) : dataDenda;
        final dendas = listDenda.map((e) => Denda.fromJson(e)).toList();
        for (final d in dendas) {
          dendaMap[d.peminjamanId] = d;
        }
      }

      setState(() {
        _allLoansList = listData.map((e) => Peminjaman.fromJson(e)).toList();
        _userDendaMap = dendaMap;
      });
    } else {
      setState(() {
        _allLoansList = [];
        _userDendaMap = {};
      });
    }
    if (showLoading) setState(() => _isLoading = false);
  }

  Future<void> _submitPeminjaman(
    int alatId,
    int jumlah,
    String tanggalPinjam,
    String tanggalKembali,
  ) async {
    final res = await ApiService.post('api/booking', {
      'alat_id': alatId,
      'tanggal_pinjam': tanggalPinjam,
      'tanggal_kembali_rencana': tanggalKembali,
      'jumlah': jumlah,
    });

    if (!mounted) return;
    if (res.status == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peminjaman berhasil diajukan!')),
      );
      _fetchRiwayat(showLoading: false);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  void _showAlatDetailModal(BuildContext context, Alat alat) {
    AlatDetailModal.show(
      context,
      alat: alat,
      onSubmit: (alatId, quantity, tanggalPinjam, tanggalKembali) =>
          _submitPeminjaman(alatId, quantity, tanggalPinjam, tanggalKembali),
    );
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return AppColors.success;
      case 'ditolak':
      case 'denda':
      case 'belum lunas':
        return AppColors.error;
      case 'dikembalikan':
      case 'selesai':
      case 'lunas':
        return AppColors.success;
      case 'menunggu':
      case 'pending':
        return AppColors.warning;
      case 'dipinjam':
        return AppColors.primary;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _historySearchCtrl.text.toLowerCase();
    final filteredHistory = _allLoansList.where((loan) {
      final toolName = (loan.namaAlat ?? '').toLowerCase();
      final code = 'UNI-00${loan.alatId}'.toLowerCase();
      return toolName.contains(query) || code.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _fetchRiwayat(showLoading: false),
              color: AppColors.primary,
              notificationPredicate: (n) => (n.depth == 0 || n.depth == 1) && _allowRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    title: const Text(
                      'Riwayat Peminjaman',
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
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(84),
                      child: Container(
                        color: AppColors.darkSurface,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: TextField(
                          controller: _historySearchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Cari riwayat',
                            suffixIcon: const Icon(Icons.search, color: AppColors.black),
                            filled: true,
                            fillColor: AppColors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Listener(
                        onPointerDown: (_) => _allowRefresh = false,
                        onPointerUp: (_) => _allowRefresh = true,
                        onPointerCancel: (_) => _allowRefresh = true,
                        child: filteredHistory.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 40.0),
                                  child: Text(
                                    'Anda tidak memiliki pinjaman',
                                    style: TextStyle(color: AppColors.grey, fontSize: 16),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredHistory.length,
                                itemBuilder: (context, index) {
                                  final loan = filteredHistory[index];
                                  final name = loan.namaAlat ?? 'Nama Alat';
                                  final qty = 'x${loan.jumlah}';

                                  String statusDisplay = loan.status;
                                  final denda = _userDendaMap[loan.id];
                                  if (denda != null) {
                                    statusDisplay = denda.status == 'paid' ? 'Lunas' : 'Belum Lunas';
                                  } else {
                                    final s = statusDisplay.toLowerCase();
                                    if (s == 'dikembalikan') statusDisplay = 'Selesai';
                                    else if (s == 'disetujui') statusDisplay = 'Aktif';
                                    else if (s == 'denda') statusDisplay = 'Belum Lunas';
                                    else if (s.isNotEmpty) statusDisplay = s[0].toUpperCase() + s.substring(1);
                                  }

                                  final leftText = 'Status: $statusDisplay';
                                  final rightText = 'Pinjam: ${loan.tanggalPinjam}';

                                  return GestureDetector(
                                    onTap: () {
                                      final cachedAlat = Alat.cache[loan.alatId];
                                      if (cachedAlat != null) {
                                        _showAlatDetailModal(context, cachedAlat);
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          (() {
                                            final cachedAlat = Alat.cache[loan.alatId];
                                            final firstFoto = cachedAlat?.firstFoto;
                                            if (firstFoto != null && firstFoto.isNotEmpty) {
                                              return ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.network(
                                                  firstFoto,
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      _buildPlaceholderImage(
                                                        width: 80,
                                                        height: 80,
                                                      ),
                                                ),
                                              );
                                            }
                                            return _buildPlaceholderImage(
                                              width: 80,
                                              height: 80,
                                            );
                                          })(),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.black,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      qty,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: AppColors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      leftText,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: _getStatusColor(statusDisplay),
                                                      ),
                                                    ),
                                                    Text(
                                                      rightText,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
