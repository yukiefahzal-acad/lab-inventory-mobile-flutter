import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';

// ─────────────────────────────────────────────────────────────────
// Data model yang menggabungkan peminjaman + denda (bila ada)
// ─────────────────────────────────────────────────────────────────
class PeminjamanItem {
  final Peminjaman peminjaman;
  final Denda? denda; // null jika tidak ada denda

  PeminjamanItem({required this.peminjaman, this.denda});

  /// Derive visual status:
  /// - 'denda'           → punya denda & belum lunas
  /// - 'lunas'           → punya denda & sudah lunas
  /// - 'aktif'           → status peminjaman 'active'
  /// - 'belum_verifikasi'→ status peminjaman 'pending'
  /// - 'selesai'         → status peminjaman 'returned' / 'completed'
  String get visualStatus {
    if (denda != null) {
      return denda!.status == 'paid' ? 'lunas' : 'denda';
    }
    switch (peminjaman.status) {
      case 'active':
        return 'aktif';
      case 'pending':
        return 'belum_verifikasi';
      default:
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
        const name =
            'pinaya agustin'; // placeholder — ganti dengan nama nyata dari API
        final code = 'UNI-00${item.peminjaman.id ?? 0}';
        return name.contains(q) || code.contains(q);
      }).toList();
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    // Fetch peminjaman & denda secara paralel
    final peminjamanRes = await ApiService.get('api/admin/peminjaman');
    final dendaRes = await ApiService.get('api/admin/denda');

    List<Peminjaman> peminjamanList = [];
    List<Denda> dendaList = [];

    if (peminjamanRes.status == 'success' && peminjamanRes.data != null) {
      final List<dynamic> data = peminjamanRes.data;
      peminjamanList = data.map((e) => Peminjaman.fromJson(e)).toList();
    }
    if (dendaRes.status == 'success' && dendaRes.data != null) {
      final List<dynamic> data = dendaRes.data;
      dendaList = data.map((e) => Denda.fromJson(e)).toList();
    }

    // Fallback simulation data
    if (peminjamanList.isEmpty) {
      peminjamanList = [
        Peminjaman(
          id: 1,
          userId: 1,
          alatId: 1,
          tanggalPinjam: '01/05/2026',
          tanggalKembali: '05/05/2026',
          status: 'denda',
        ),
        Peminjaman(
          id: 2,
          userId: 2,
          alatId: 2,
          tanggalPinjam: '10/05/2026',
          tanggalKembali: '15/05/2026',
          status: 'lunas',
        ),
        Peminjaman(
          id: 3,
          userId: 3,
          alatId: 1,
          tanggalPinjam: '20/05/2026',
          tanggalKembali: '25/05/2026',
          status: 'active',
        ),
        Peminjaman(
          id: 4,
          userId: 4,
          alatId: 2,
          tanggalPinjam: '28/05/2026',
          tanggalKembali: '02/06/2026',
          status: 'pending',
        ),
        Peminjaman(
          id: 5,
          userId: 5,
          alatId: 1,
          tanggalPinjam: '01/04/2026',
          tanggalKembali: '05/04/2026',
          status: 'returned',
        ),
      ];
    }
    if (dendaList.isEmpty) {
      dendaList = [
        Denda(
          id: 1,
          userId: 1,
          peminjamanId: 1,
          jumlah: 200000,
          status: 'unpaid',
        ),
        Denda(
          id: 2,
          userId: 2,
          peminjamanId: 2,
          jumlah: 200000,
          status: 'paid',
        ),
      ];
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
    final res = await ApiService.put('api/admin/denda/$dendaId/lunas', {});
    if (res.status == 'success') {
      await _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status denda diperbarui ke Lunas.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'Terjadi kesalahan')),
        );
      }
    }
  }

  // ─── Badge helper ──────────────────────────────────────────────
  Widget _buildBadge(String visualStatus) {
    switch (visualStatus) {
      case 'denda':
        return _badge('Denda', AppColors.errorBg, AppColors.error);
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
      case 'aktif':
        _showQRModal(item, isKembali: true);
        break;
      case 'belum_verifikasi':
        _showQRModal(item, isKembali: false);
        break;
      default:
        break;
    }
  }

  // ─── Modal: Denda (Riwayat-1) ──────────────────────────────────
  void _showDendaModal(PeminjamanItem item) {
    final denda = item.denda!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => _DendaModal(
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
      backgroundColor: AppColors.transparent,
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
    final listBody = Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.black87),
              decoration: const InputDecoration(
                hintText: 'Cari...',
                hintStyle: TextStyle(color: AppColors.grey, fontSize: 16),
                prefixIcon: SizedBox(width: 8),
                suffixIcon: Icon(Icons.search, color: AppColors.black54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // Card list container
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryLight,
                  ),
                )
              : _filtered.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada data peminjaman.',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 16,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: AppColors.primaryDark,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: List.generate(_filtered.length, (index) {
                          final item = _filtered[index];
                          final isLast = index == _filtered.length - 1;
                          final isClickable =
                              item.visualStatus == 'denda' ||
                              item.visualStatus == 'aktif' ||
                              item.visualStatus == 'belum_verifikasi';

                          return Column(
                            children: [
                              InkWell(
                                onTap: isClickable
                                    ? () => _onItemTap(item)
                                    : null,
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
                                            const Text(
                                              'Pinaya Agustin',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Kode: UNI-00${item.peminjaman.id ?? 0}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Terlambat: X Hari',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppColors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          if (item.denda != null) ...[
                                            Text(
                                              'Rp ${_formatCurrency(item.denda!.jumlah.toDouble())}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    item.visualStatus == 'lunas'
                                                    ? AppColors.successDark
                                                    : AppColors.error,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                          ],
                                          _buildBadge(item.visualStatus),
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
        ),
      ],
    );

    if (widget.isTab) {
      return Scaffold(backgroundColor: AppColors.darkSurface, body: listBody);
    }

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'List Peminjaman',
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: listBody,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Modal: Denda Detail (Riwayat-1.png)
// ─────────────────────────────────────────────────────────────────
class _DendaModal extends StatelessWidget {
  final PeminjamanItem item;
  final Denda denda;
  final Widget Function({double width, double height, double radius})
  buildCheckered;
  final VoidCallback onLunas;

  const _DendaModal({
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.black26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: AppColors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
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
                            buildCheckered(width: 60, height: 60, radius: 8),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pinaya Agustin',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  Text(
                                    'Kode: UNI-00${item.peminjaman.id ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.black54,
                                    ),
                                  ),
                                  const Text(
                                    'Terlambat: X Hari',
                                    style: TextStyle(
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: buildCheckered(
                            width: double.infinity,
                            height: 200,
                            radius: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Nama Alat',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
                        child: Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.black54,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.black26),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '50',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

class _QRDetailModalState extends State<_QRDetailModal> {
  bool _dendaRusak = false;
  bool _dendaTelat = false;
  final TextEditingController _catatanCtrl = TextEditingController();

  @override
  void dispose() {
    _catatanCtrl.dispose();
    super.dispose();
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.black26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: AppColors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKembali = widget.isKembali;
    final item = widget.item;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                // child: Row(
                //   children: [
                //     IconButton(
                //       icon: const Icon(Icons.arrow_back, color: AppColors.black),
                //       onPressed: () => Navigator.pop(context),
                //     ),
                //     const Text(
                //       'Scan QR',
                //       style: TextStyle(
                //         fontSize: 18,
                //         fontWeight: FontWeight.bold,
                //         color: AppColors.black,
                //       ),
                //     ),
                //   ],
                // ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: widget.buildCheckered(
                            width: double.infinity,
                            height: 200,
                            radius: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Nama Alat',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
                        child: Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.black54,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Bolong pada bagian bawah kiri',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Text(
                                'Denda',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _dendaRusak = !_dendaRusak),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _dendaRusak
                                        ? AppColors.errorBg
                                        : AppColors.errorBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Rusak',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _dendaTelat = !_dendaTelat),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _dendaTelat
                                        ? AppColors.errorBg
                                        : AppColors.errorBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Telat',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: AppColors.black45,
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!isKembali) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            'Catatan Alat',
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
                                hintText: 'Isi catatan alat disini...',
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
                            const Text(
                              'Jumlah',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.black26),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '50',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: widget.onVerifikasi,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isKembali
                                  ? AppColors.warning
                                  : AppColors.warningDark,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              isKembali
                                  ? 'Verifikasi Pengembalian'
                                  : 'Verifikasi Pinjaman',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
