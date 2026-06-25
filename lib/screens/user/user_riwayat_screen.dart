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
        final List<dynamic> listDenda = dataDenda is Map
            ? (dataDenda['data'] ?? [])
            : dataDenda;
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

  void _showPeminjamanDetailModal(BuildContext context, Peminjaman loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final cachedAlat = Alat.cache[loan.alatId];
        final firstFoto = cachedAlat?.firstFoto;

        Widget infoRow(String label, String value, {bool isMultiLine = false}) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isMultiLine
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.black87,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.black87,
                        ),
                      ),
                    ],
                  ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom:
                20 +
                MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (firstFoto != null && firstFoto.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          firstFoto,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(width: 80, height: 80),
                        ),
                      )
                    else
                      _buildPlaceholderImage(width: 80, height: 80),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cachedAlat?.namaAlat ??
                                loan.namaAlat ??
                                'Peminjaman #${loan.id ?? 0}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cachedAlat?.spesifikasi ?? '-',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.black54,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              infoRow(
                'Tanggal Pinjam',
                loan.tanggalPinjam.isEmpty ? '-' : loan.tanggalPinjam,
              ),
              const SizedBox(height: 12),
              infoRow(
                'Tanggal Kembali Rencana',
                loan.tanggalKembali.isEmpty ? '-' : loan.tanggalKembali,
              ),
              const SizedBox(height: 12),
              infoRow(
                'Tanggal Kembali Aktual',
                loan.tanggalKembaliAktual ?? '-',
              ),
              const SizedBox(height: 12),
              infoRow('Jumlah Dipinjam', '${loan.jumlah}'),
              const SizedBox(height: 12),
              infoRow('Jumlah Kembali', '${loan.jumlahKembali ?? '-'}'),
              const SizedBox(height: 12),
              if (loan.catatanPinjaman != null &&
                  loan.catatanPinjaman!.isNotEmpty) ...[
                infoRow(
                  'Catatan Pinjam',
                  loan.catatanPinjaman!,
                  isMultiLine: true,
                ),
                const SizedBox(height: 12),
              ],
              if (loan.catatanPengembalian != null &&
                  loan.catatanPengembalian!.isNotEmpty) ...[
                infoRow(
                  'Catatan Pengembalian',
                  loan.catatanPengembalian!,
                  isMultiLine: true,
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
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

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('belum lunas') || s == 'ditolak' || s == 'denda')
      return AppColors.error;
    if (s == 'disetujui' ||
        s == 'dikembalikan' ||
        s == 'selesai' ||
        s == 'lunas')
      return AppColors.success;
    if (s == 'menunggu' || s == 'pending') return AppColors.warning;
    if (s == 'dipinjam' || s == 'aktif') return AppColors.primaryDark;
    return AppColors.grey;
  }

  int _getCardDendaNominal(Peminjaman loan) {
    final denda = _userDendaMap[loan.id];
    if (denda != null && denda.status != 'paid') {
      return denda.jumlah.toInt();
    }
    final s = loan.status.toLowerCase();
    if (s == 'disetujui' || s == 'aktif' || s == 'dipinjam') {
      DateTime? tglKembali;
      try {
        tglKembali = DateTime.parse(loan.tanggalKembali);
      } catch (_) {}

      if (tglKembali != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final kembaliDate = DateTime(
          tglKembali.year,
          tglKembali.month,
          tglKembali.day,
        );

        if (today.isAfter(kembaliDate)) {
          int daysLate = today.difference(kembaliDate).inDays;
          if (daysLate > 0) {
            final cachedAlat = Alat.cache[loan.alatId];
            final dendaPerHari = cachedAlat?.dendaPerHari ?? 0;
            return daysLate * dendaPerHari;
          }
        }
      }
    }
    return 0;
  }

  String _getCardStatusDisplay(Peminjaman loan) {
    String statusDisplay = loan.status;
    final denda = _userDendaMap[loan.id];
    final s = statusDisplay.toLowerCase();
    bool isLateAndActive = false;

    if (s == 'disetujui' || s == 'aktif' || s == 'dipinjam') {
      DateTime? tglKembali;
      try {
        tglKembali = DateTime.parse(loan.tanggalKembali);
      } catch (_) {}

      if (tglKembali != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final kembaliDate = DateTime(
          tglKembali.year,
          tglKembali.month,
          tglKembali.day,
        );

        if (today.isAfter(kembaliDate)) {
          int daysLate = today.difference(kembaliDate).inDays;
          if (daysLate > 0) {
            isLateAndActive = true;
          }
        }
      }
    }

    if (denda != null) {
      if (denda.status == 'paid') {
        return 'Lunas';
      } else {
        return 'Belum Lunas';
      }
    } else {
      if (isLateAndActive) {
        return 'Belum Lunas';
      } else {
        if (s == 'dikembalikan') return 'Selesai';
        if (s == 'disetujui') return 'Aktif';
        if (s == 'denda') return 'Belum Lunas';
        if (s.isNotEmpty) return s[0].toUpperCase() + s.substring(1);
        return '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _historySearchCtrl.text.toLowerCase();
    final filteredHistory = _allLoansList.where((loan) {
      final toolName = (loan.namaAlat ?? '').toLowerCase();
      final code = 'UNI-00${loan.alatId}'.toLowerCase();
      final qty = 'x${loan.jumlah}'.toLowerCase();
      final tglPinjam = loan.tanggalPinjam.toLowerCase();
      final tglKembali = loan.tanggalKembali.toLowerCase();
      final statusStr = _getCardStatusDisplay(loan).toLowerCase();
      final nominal = _getCardDendaNominal(loan);
      final nominalStr = nominal > 0
          ? 'rp ${_formatCurrency(nominal)}'.toLowerCase()
          : '';

      return toolName.contains(query) ||
          code.contains(query) ||
          qty.contains(query) ||
          tglPinjam.contains(query) ||
          tglKembali.contains(query) ||
          statusStr.contains(query) ||
          nominalStr.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _fetchRiwayat(showLoading: false),
              color: AppColors.primary,
              notificationPredicate: (n) =>
                  (n.depth == 0 || n.depth == 1) && _allowRefresh,
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
                            suffixIcon: const Icon(
                              Icons.search,
                              color: AppColors.black,
                            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 4.0,
                    ),
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
                                    style: TextStyle(
                                      color: AppColors.grey,
                                      fontSize: 16,
                                    ),
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
                                  final statusDisplay = _getCardStatusDisplay(
                                    loan,
                                  );
                                  final dendaNominal = _getCardDendaNominal(
                                    loan,
                                  );

                                  return GestureDetector(
                                    onTap: () {
                                      _showPeminjamanDetailModal(context, loan);
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
                                            final cachedAlat =
                                                Alat.cache[loan.alatId];
                                            final firstFoto =
                                                cachedAlat?.firstFoto;
                                            if (firstFoto != null &&
                                                firstFoto.isNotEmpty) {
                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.network(
                                                  firstFoto,
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) =>
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              AppColors.black,
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
                                                  children: [
                                                    Text(
                                                      'Status: $statusDisplay',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: _getStatusColor(
                                                          statusDisplay,
                                                        ),
                                                      ),
                                                    ),
                                                    if (dendaNominal > 0) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              AppColors.errorBg,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'Rp ${_formatCurrency(dendaNominal)}',
                                                          style:
                                                              const TextStyle(
                                                                color: AppColors
                                                                    .error,
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Pinjam: ${loan.tanggalPinjam}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.grey,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Kembali: ${loan.tanggalKembali}',
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
