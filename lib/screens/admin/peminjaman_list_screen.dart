import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';
import '../../widgets/alat_detail_modal.dart';

// ─────────────────────────────────────────────────────────────────
// Data model yang menggabungkan peminjaman + denda (bila ada)
// ─────────────────────────────────────────────────────────────────
class PeminjamanItem {
  final Peminjaman peminjaman;
  final Denda? denda; // null jika tidak ada denda

  PeminjamanItem({required this.peminjaman, this.denda});

  int get dendaNominalCalculated {
    if (denda != null) {
      return denda!.jumlah.toInt();
    }
    final s = peminjaman.status.toLowerCase();
    if (s == 'disetujui' || s == 'active') {
      DateTime? tglKembali;
      try {
        tglKembali = DateTime.parse(peminjaman.tanggalKembali);
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
            final cachedAlat = Alat.cache[peminjaman.alatId];
            final dendaPerHari = cachedAlat?.dendaPerHari ?? 0;
            return daysLate * dendaPerHari;
          }
        }
      }
    }
    return 0;
  }

  /// Derive visual status:
  /// - 'denda'           → punya denda & belum lunas
  /// - 'denda_calculated'→ terlambat tapi belum dihitung formal
  /// - 'lunas'           → punya denda & sudah lunas
  /// - 'aktif'           → status peminjaman 'active'
  /// - 'belum_verifikasi'→ status peminjaman 'pending'
  /// - 'selesai'         → status peminjaman 'returned' / 'completed'
  String get visualStatus {
    if (denda != null) {
      return denda!.status == 'paid' ? 'lunas' : 'denda';
    }
    final s = peminjaman.status.toLowerCase();
    if (s == 'disetujui' || s == 'active') {
      if (dendaNominalCalculated > 0) {
        return 'denda_calculated';
      }
      return 'aktif';
    } else if (s == 'menunggu' || s == 'pending') {
      return 'belum_verifikasi';
    } else {
      return 'selesai';
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────
class PeminjamanListScreen extends StatefulWidget {
  final bool isTab;
  const PeminjamanListScreen({super.key, this.isTab = false});

  @override
  State<PeminjamanListScreen> createState() => _PeminjamanListScreenState();
}

class _PeminjamanListScreenState extends State<PeminjamanListScreen> {
  List<PeminjamanItem> _items = [];
  List<PeminjamanItem> _filtered = [];
  bool _isLoading = true;
  bool _allowRefresh = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applySearch);
    _fetchData();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applySearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applySearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _items.where((item) {
        final studentName = (item.peminjaman.namaMahasiswa ?? '').toLowerCase();
        final loanIdStr = 'uni-00${item.peminjaman.id ?? 0}';
        final cachedAlat = Alat.cache[item.peminjaman.alatId];
        final toolName =
            (cachedAlat?.namaAlat ?? item.peminjaman.namaAlat ?? '')
                .toLowerCase();
        final qty = 'x${item.peminjaman.jumlah}'.toLowerCase();
        final tglPinjam = item.peminjaman.tanggalPinjam.toLowerCase();
        final tglKembali = item.peminjaman.tanggalKembali.toLowerCase();
        
        String statusStr = '';
        switch (item.visualStatus) {
          case 'denda':
          case 'denda_calculated':
            statusStr = 'belum lunas';
            break;
          case 'lunas':
            statusStr = 'lunas';
            break;
          case 'aktif':
            statusStr = 'aktif';
            break;
          case 'belum_verifikasi':
            statusStr = 'belum verifikasi';
            break;
          default:
            statusStr = 'selesai';
        }

        int nominal = 0;
        if (item.denda != null) {
          nominal = item.denda!.jumlah.toInt();
        } else if (item.dendaNominalCalculated > 0) {
          nominal = item.dendaNominalCalculated;
        }
        final nominalStr = nominal > 0 ? 'rp ${_formatCurrency(nominal.toDouble())}'.toLowerCase() : '';

        return studentName.contains(q) ||
            loanIdStr.contains(q) ||
            toolName.contains(q) ||
            qty.contains(q) ||
            tglPinjam.contains(q) ||
            tglKembali.contains(q) ||
            statusStr.contains(q) ||
            nominalStr.contains(q);
      }).toList();
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    // Fetch peminjaman, denda, & alat secara paralel
    final peminjamanRes = await ApiService.get('api/peminjaman/riwayat');
    final dendaRes = await ApiService.get('api/admin/denda');
    final alatRes = await ApiService.get('api/alat');

    List<Peminjaman> peminjamanList = [];
    List<Denda> dendaList = [];

    if (alatRes.status == 'success' && alatRes.data != null) {
      final data = alatRes.data;
      final List<dynamic> listData = data is Map ? (data['data'] ?? []) : data;
      for (final e in listData) {
        Alat.fromJson(e); // This populates Alat.cache
      }
    }

    if (peminjamanRes.status == 'success' && peminjamanRes.data != null) {
      final data = peminjamanRes.data;
      final List<dynamic> listData = data is Map ? (data['data'] ?? []) : data;
      peminjamanList = listData.map((e) => Peminjaman.fromJson(e)).toList();
    }
    if (dendaRes.status == 'success' && dendaRes.data != null) {
      final data = dendaRes.data;
      final List<dynamic> listData = data is Map ? (data['data'] ?? []) : data;
      dendaList = listData.map((e) => Denda.fromJson(e)).toList();
    }

    // Gabungkan peminjaman + denda berdasarkan peminjamanId dengan tipe yang jelas
    final Map<int?, Denda> dendaMap = {
      for (final d in dendaList) d.peminjamanId: d,
    };
    final items = peminjamanList.map((p) {
      return PeminjamanItem(peminjaman: p, denda: dendaMap[p.id]);
    }).toList();

    setState(() {
      _items = items;
      _filtered = items;
      _isLoading = false;
    });
  }

  Future<void> _setLunas(int dendaId) async {
    final res = await ApiService.put('api/admin/denda/lunas', {'id': dendaId});
    if (res.status == 'success') {
      await _fetchData();
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

  // ─── Badge helper ──────────────────────────────────────────────
  Widget _buildBadge(PeminjamanItem item) {
    switch (item.visualStatus) {
      case 'denda':
      case 'denda_calculated':
        return _badge('Belum Lunas', AppColors.errorBg, AppColors.error);
      case 'lunas':
        return _badge('Lunas', AppColors.successBg, AppColors.successDark);
      case 'aktif':
        return _badge('Aktif', AppColors.primary, AppColors.white);
      case 'belum_verifikasi':
        return _badge(
          'Belum Verifikasi',
          AppColors.warningBg,
          AppColors.warning,
        );
      default:
        return _badge('Selesai', AppColors.successBg, AppColors.successDark);
    }
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  // ─── Checkered placeholder ─────────────────────────────────────
  Widget _buildCheckered({
    double width = 60,
    double height = 60,
    double radius = 8,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
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
          itemBuilder: (_, i) {
            final row = i ~/ 8;
            final col = i % 8;
            return Container(
              color: (row + col) % 2 == 0 ? AppColors.white : AppColors.grey200,
            );
          },
        ),
      ),
    );
  }

  // ─── Tap handler per item ──────────────────────────────────────
  void _onItemTap(PeminjamanItem item) {
    switch (item.visualStatus) {
      case 'denda':
        _showDendaModal(item);
        break;
      case 'denda_calculated':
      case 'aktif':
        _showQRModal(item, isKembali: true);
        break;
      case 'belum_verifikasi':
        _showQRModal(item, isKembali: false);
        break;
      case 'lunas':
      case 'selesai':
        _showPeminjamanDetailModal(item);
        break;
    }
  }

  // ─── Modal: Detail Peminjaman (Selesai / Lunas) ─────────────────
  void _showPeminjamanDetailModal(PeminjamanItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _PeminjamanDetailModal(item: item, buildCheckered: _buildCheckered),
    );
  }

  // ─── Modal: Denda (Riwayat-1) ──────────────────────────────────
  void _showDendaModal(PeminjamanItem item) {
    final denda = item.denda!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DendaModal(
        item: item,
        denda: denda,
        buildCheckered: _buildCheckered,
        onLunas: () async {
          Navigator.pop(context);
          if (denda.id != null) {
            await _setLunas(denda.id!);
          }
        },
      ),
    );
  }

  // ─── Modal: QR Detail (Scan QR Kembali / Scan QR Pinjam) ──────
  void _showQRModal(PeminjamanItem item, {required bool isKembali}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _QRDetailModal(
        item: item,
        isKembali: isKembali,
        buildCheckered: _buildCheckered,
        onVerifikasi: () async {
          Navigator.pop(context);
          await _fetchData();
        },
      ),
    );
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
    final searchBar = Container(
      color: AppColors.darkSurface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Cari peminjaman',
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
    );

    final listContent = _isLoading
        ? const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryDark),
            ),
          )
        : _filtered.isEmpty
        ? const SliverFillRemaining(
            child: Center(
              child: Text(
                'tidak ada data peminjaman',
                style: TextStyle(color: AppColors.primaryDark, fontSize: 16),
              ),
            ),
          )
        : SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            sliver: SliverToBoxAdapter(
              child: Listener(
                onPointerDown: (_) => _allowRefresh = false,
                onPointerUp: (_) => _allowRefresh = true,
                onPointerCancel: (_) => _allowRefresh = true,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: List.generate(_filtered.length, (index) {
                      final item = _filtered[index];
                      final isLast = index == _filtered.length - 1;
                      final cachedAlat = Alat.cache[item.peminjaman.alatId];
                      final firstFoto = cachedAlat?.firstFoto;

                      return Column(
                        children: [
                          InkWell(
                            onTap: () => _onItemTap(item),
                            borderRadius: BorderRadius.vertical(
                              top: index == 0
                                  ? const Radius.circular(20)
                                  : Radius.zero,
                              bottom: isLast
                                  ? const Radius.circular(20)
                                  : Radius.zero,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  if (firstFoto != null && firstFoto.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        firstFoto,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildCheckered(
                                                  width: 60,
                                                  height: 60,
                                                  radius: 8,
                                                ),
                                      ),
                                    )
                                  else
                                    _buildCheckered(
                                      width: 60,
                                      height: 60,
                                      radius: 8,
                                    ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cachedAlat?.namaAlat ??
                                              item.peminjaman.namaAlat ??
                                              'Peminjaman #${item.peminjaman.id ?? 0}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.black,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Peminjam: ${item.peminjaman.namaMahasiswa ?? 'Mahasiswa'}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (item.denda != null ||
                                          item.dendaNominalCalculated > 0) ...[
                                        Text(
                                          'Rp ${_formatCurrency(item.dendaNominalCalculated.toDouble())}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: item.visualStatus == 'lunas'
                                                ? AppColors.successDark
                                                : AppColors.error,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                      _buildBadge(item),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isLast)
                            const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: AppColors.grey200,
                            ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          );

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.primaryDark,
        notificationPredicate: (n) => n.depth == 0 && _allowRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              leading: !widget.isTab
                  ? IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
              title: const Text(
                'Manajemen Peminjaman',
                style: TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              backgroundColor: AppColors.white,
              elevation: 0,
              pinned: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(84),
                child: searchBar,
              ),
            ),
            listContent,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Modal: Denda Detail (Riwayat-1.png)
// ─────────────────────────────────────────────────────────────────
class DendaModal extends StatelessWidget {
  final PeminjamanItem item;
  final Denda denda;
  final Widget Function({double width, double height, double radius})
  buildCheckered;
  final VoidCallback onLunas;

  const DendaModal({
    required this.item,
    required this.denda,
    required this.buildCheckered,
    required this.onLunas,
  });

  String _formatCurrency(double amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  Widget _infoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
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
            style: const TextStyle(fontSize: 14, color: AppColors.black87),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              children: [
                (() {
                  final cachedAlat = Alat.cache[item.peminjaman.alatId];
                  final firstFoto = cachedAlat?.firstFoto;
                  if (firstFoto != null && firstFoto.isNotEmpty) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        firstFoto,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            buildCheckered(width: 60, height: 60, radius: 8),
                      ),
                    );
                  }
                  return buildCheckered(width: 60, height: 60, radius: 8);
                })(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      (() {
                        final cachedAlat = Alat.cache[item.peminjaman.alatId];
                        return Text(
                          cachedAlat?.namaAlat ??
                              item.peminjaman.namaAlat ??
                              'Peminjaman #${item.peminjaman.id ?? 0}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      })(),
                      Text(
                        'Peminjam: ${item.peminjaman.namaMahasiswa ?? 'Mahasiswa'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rp ${_formatCurrency(denda.jumlah.toDouble())}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Denda',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (() {
              final cachedAlat = Alat.cache[item.peminjaman.alatId];
              final firstFoto = cachedAlat?.firstFoto;
              if (firstFoto != null && firstFoto.isNotEmpty) {
                return Image.network(
                  firstFoto,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => buildCheckered(
                    width: double.infinity,
                    height: 200,
                    radius: 12,
                  ),
                );
              }
              return buildCheckered(
                width: double.infinity,
                height: 200,
                radius: 12,
              );
            })(),
          ),
          const SizedBox(height: 20),
          _infoRow(
            label: 'Tanggal Pinjam',
            value: item.peminjaman.tanggalPinjam.isEmpty
                ? 'DD / MM / YYYY'
                : item.peminjaman.tanggalPinjam,
          ),
          const SizedBox(height: 12),
          _infoRow(
            label: 'Tanggal Kembali',
            value: item.peminjaman.tanggalKembali.isEmpty
                ? 'DD / MM / YYYY'
                : item.peminjaman.tanggalKembali,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jumlah',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                Text(
                  '${item.peminjaman.jumlah}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onLunas,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Lunas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Modal: QR Detail (Scan QR Kembali / Scan QR Pinjam)
// ─────────────────────────────────────────────────────────────────
class _QRDetailModal extends StatefulWidget {
  final PeminjamanItem item;
  final bool isKembali;
  final Widget Function({double width, double height, double radius})
  buildCheckered;
  final VoidCallback onVerifikasi;

  const _QRDetailModal({
    required this.item,
    required this.isKembali,
    required this.buildCheckered,
    required this.onVerifikasi,
  });

  @override
  State<_QRDetailModal> createState() => _QRDetailModalState();
}

// ─────────────────────────────────────────────────────────────────
// Modal: Detail Peminjaman (Selesai / Lunas)
// ─────────────────────────────────────────────────────────────────
class _PeminjamanDetailModal extends StatelessWidget {
  final PeminjamanItem item;
  final Widget Function({double width, double height, double radius})
  buildCheckered;

  const _PeminjamanDetailModal({
    required this.item,
    required this.buildCheckered,
  });

  Widget _infoRow({
    required String label,
    required String value,
    bool isMultiLine = false,
  }) {
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

  @override
  Widget build(BuildContext context) {
    final cachedAlat = Alat.cache[item.peminjaman.alatId];
    final firstFoto = cachedAlat?.firstFoto;

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
                          buildCheckered(width: 80, height: 80, radius: 8),
                    ),
                  )
                else
                  buildCheckered(width: 80, height: 80, radius: 8),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cachedAlat?.namaAlat ??
                            item.peminjaman.namaAlat ??
                            'Peminjaman #${item.peminjaman.id ?? 0}',
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
          _infoRow(
            label: 'Tanggal Pinjam',
            value: item.peminjaman.tanggalPinjam.isEmpty
                ? '-'
                : item.peminjaman.tanggalPinjam,
          ),
          const SizedBox(height: 12),
          _infoRow(
            label: 'Tanggal Kembali Aktual',
            value: item.peminjaman.tanggalKembaliAktual ?? '-',
          ),
          const SizedBox(height: 12),
          _infoRow(
            label: 'Jumlah Dipinjam',
            value: '${item.peminjaman.jumlah}',
          ),
          const SizedBox(height: 12),
          _infoRow(
            label: 'Jumlah Kembali',
            value: '${item.peminjaman.jumlahKembali ?? '-'}',
          ),
          const SizedBox(height: 12),
          if (item.peminjaman.catatanPinjaman != null &&
              item.peminjaman.catatanPinjaman!.isNotEmpty) ...[
            _infoRow(
              label: 'Catatan Pinjam',
              value: item.peminjaman.catatanPinjaman!,
              isMultiLine: true,
            ),
            const SizedBox(height: 12),
          ],
          if (item.peminjaman.catatanPengembalian != null &&
              item.peminjaman.catatanPengembalian!.isNotEmpty) ...[
            _infoRow(
              label: 'Catatan Pengembalian',
              value: item.peminjaman.catatanPengembalian!,
              isMultiLine: true,
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _QRDetailModalState extends State<_QRDetailModal> {
  String _kondisiAlat = 'baik';
  final TextEditingController _catatanCtrl = TextEditingController();
  late final TextEditingController _jumlahKembaliCtrl;
  late final TextEditingController _catatanKembaliCtrl;

  @override
  void initState() {
    super.initState();
    _jumlahKembaliCtrl = TextEditingController(
      text: widget.item.peminjaman.jumlah.toString(),
    );
    _catatanKembaliCtrl = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    _jumlahKembaliCtrl.dispose();
    _catatanKembaliCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitVerifikasi() async {
    final isKembali = widget.isKembali;
    final peminjamanId = widget.item.peminjaman.id;

    if (isKembali) {
      final now = DateTime.now();

      final res = await ApiService.post('api/pengembalian', {
        'peminjaman_id': peminjamanId,
        'tanggal_kembali_aktual':
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
        'kondisi_alat': _kondisiAlat,
        'jumlah_kembali':
            int.tryParse(_jumlahKembaliCtrl.text) ??
            widget.item.peminjaman.jumlah,
        'catatan_pengembalian': _catatanKembaliCtrl.text,
      });

      if (res.status == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengembalian berhasil diverifikasi.'),
            ),
          );
        }
        widget.onVerifikasi();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message ?? 'Terjadi kesalahan')),
          );
        }
      }
    } else {
      final res = await ApiService.put('api/peminjaman/persetujuan', {
        'id': peminjamanId,
        'status': 'Disetujui',
        'catatan_pinjaman': _catatanCtrl.text,
      });

      if (res.status == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pinjaman berhasil disetujui.')),
          );
        }
        widget.onVerifikasi();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message ?? 'Terjadi kesalahan')),
          );
        }
      }
    }
  }

  Future<void> _submitTolak() async {
    final peminjamanId = widget.item.peminjaman.id;
    final res = await ApiService.put('api/peminjaman/persetujuan', {
      'id': peminjamanId,
      'status': 'Ditolak',
      'catatan_pinjaman': _catatanCtrl.text,
    });

    if (res.status == 'success') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pinjaman berhasil ditolak.')),
        );
      }
      widget.onVerifikasi();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'Terjadi kesalahan')),
        );
      }
    }
  }

  Widget _infoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
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
            style: const TextStyle(fontSize: 14, color: AppColors.black87),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKembali = widget.isKembali;
    final item = widget.item;
    final cachedAlat = Alat.cache[item.peminjaman.alatId];
    final firstFoto = cachedAlat?.firstFoto;

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
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (() {
              if (firstFoto != null && firstFoto.isNotEmpty) {
                return Image.network(
                  firstFoto,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      widget.buildCheckered(
                        width: double.infinity,
                        height: 200,
                        radius: 12,
                      ),
                );
              }
              return widget.buildCheckered(
                width: double.infinity,
                height: 200,
                radius: 12,
              );
            })(),
          ),
          const SizedBox(height: 20),
          Text(
            cachedAlat?.namaAlat ?? item.peminjaman.namaAlat ?? 'Nama Alat',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cachedAlat?.spesifikasi ?? 'Tidak ada deskripsi spesifikasi.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _infoRow(
            label: 'Peminjam',
            value: item.peminjaman.namaMahasiswa ?? '-',
          ),
          const SizedBox(height: 12),
          _infoRow(
            label: 'Tanggal Pinjam',
            value: item.peminjaman.tanggalPinjam.isEmpty
                ? 'DD / MM / YYYY'
                : item.peminjaman.tanggalPinjam,
          ),
          const SizedBox(height: 12),
          _infoRow(
            label: 'Tanggal Kembali',
            value: item.peminjaman.tanggalKembali.isEmpty
                ? 'DD / MM / YYYY'
                : item.peminjaman.tanggalKembali,
          ),
          const SizedBox(height: 20),
          if (isKembali) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                'Catatan alat:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                item.peminjaman.catatanPinjaman == null ||
                        item.peminjaman.catatanPinjaman!.isEmpty
                    ? '-'
                    : item.peminjaman.catatanPinjaman!,
                style: const TextStyle(fontSize: 14, color: AppColors.black54),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kondisi Alat (Denda)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Baik'),
                        selected: _kondisiAlat == 'baik',
                        selectedColor: AppColors.successBg,
                        labelStyle: TextStyle(
                          color: _kondisiAlat == 'baik'
                              ? AppColors.successDark
                              : AppColors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _kondisiAlat = 'baik');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Rusak'),
                        selected: _kondisiAlat == 'rusak',
                        selectedColor: AppColors.errorBg,
                        labelStyle: TextStyle(
                          color: _kondisiAlat == 'rusak'
                              ? AppColors.error
                              : AppColors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _kondisiAlat = 'rusak');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Hilang'),
                        selected: _kondisiAlat == 'hilang',
                        selectedColor: AppColors.errorBg,
                        labelStyle: TextStyle(
                          color: _kondisiAlat == 'hilang'
                              ? AppColors.error
                              : AppColors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _kondisiAlat = 'hilang');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Catatan Pengembalian',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.black26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _catatanKembaliCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Tambahkan catatan jika diperlukan...',
                    hintStyle: TextStyle(color: AppColors.black38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),
            ),
          ],
          if (!isKembali) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Catatan (opsional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.black26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _catatanCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Catatan (opsional)',
                    hintStyle: TextStyle(color: AppColors.black38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isKembali ? 'Jumlah Pinjam' : 'Jumlah',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                Text(
                  '${item.peminjaman.jumlah}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (isKembali) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jumlah Kembali',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: AppColors.primaryDark,
                        ),
                        onPressed: () {
                          final currentVal =
                              int.tryParse(_jumlahKembaliCtrl.text) ??
                              widget.item.peminjaman.jumlah;
                          if (currentVal > 0) {
                            setState(() {
                              _jumlahKembaliCtrl.text = (currentVal - 1)
                                  .toString();
                            });
                          }
                        },
                      ),
                      Container(
                        width: 60,
                        height: 40,
                        alignment: Alignment.center,
                        child: TextField(
                          controller: _jumlahKembaliCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.black26,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primaryDark,
                        ),
                        onPressed: () {
                          final currentVal =
                              int.tryParse(_jumlahKembaliCtrl.text) ??
                              widget.item.peminjaman.jumlah;
                          if (currentVal < widget.item.peminjaman.jumlah) {
                            setState(() {
                              _jumlahKembaliCtrl.text = (currentVal + 1)
                                  .toString();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isKembali
                ? SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitVerifikasi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Verifikasi Pengembalian',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _submitTolak,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Tolak',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _submitVerifikasi,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Verifikasi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
