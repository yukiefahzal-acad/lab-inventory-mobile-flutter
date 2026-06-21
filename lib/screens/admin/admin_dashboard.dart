import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';
import '../../models/models.dart';
import '../auth/login_screen.dart';
import '../user/qr_scanner_screen.dart';
import 'alat_list_screen.dart';
import 'peminjaman_list_screen.dart';
import 'denda_list_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  bool _isHomeLoading = true;
  int _totalAlat = 0;
  int _activeLoans = 0;
  int _returnedCount = 0;
  int _totalDenda = 0;
  bool _allowRefresh = true;
  String _adminName = 'Admin';
  String _adminEmail = 'admin@mail.com';
  List<Peminjaman> _allLoans = [];
  List<Peminjaman> _activeLoanList = [];
  List<Denda> _unpaidDendaList = [];

  @override
  void initState() {
    super.initState();
    _fetchStats(showLoading: true);
  }

  Future<void> _fetchStats({bool showLoading = true}) async {
    if (!mounted) return;
    if (showLoading) setState(() => _isHomeLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _adminName = prefs.getString('nama') ?? 'Admin';
        _adminEmail = prefs.getString('email') ?? 'admin@mail.com';
      });

      final resAlat = await ApiService.get('api/alat');
      final resRiwayat = await ApiService.get('api/peminjaman/riwayat');
      final resDenda = await ApiService.get('api/admin/denda');

      int countAlat = 0;
      int active = 0;
      int returned = 0;
      int unpaidDenda = 0;

      if (resAlat.status == 'success' && resAlat.data != null) {
        final List<dynamic> alatList = (resAlat.data is Map)
            ? (resAlat.data['data'] ?? [])
            : (resAlat.data is List ? resAlat.data : []);
        countAlat = alatList.length;
      }

      if (resRiwayat.status == 'success' && resRiwayat.data != null) {
        final List<dynamic> historyData = (resRiwayat.data is Map)
            ? (resRiwayat.data['data'] ?? [])
            : (resRiwayat.data is List ? resRiwayat.data : []);
        final List<Peminjaman> parsedLoans = [];
        for (var item in historyData) {
          final p = Peminjaman.fromJson(item);
          parsedLoans.add(p);
          final status = (item['status'] ?? '').toString().toLowerCase();
          if (status == 'disetujui') {
            active++;
          } else if (status == 'dikembalikan') {
            returned++;
          }
        }
        if (mounted) {
          setState(() {
            _allLoans = parsedLoans;
            _activeLoanList = parsedLoans
                .where((p) => p.status.toLowerCase() == 'disetujui')
                .toList();
          });
        }
      }

      if (resDenda.status == 'success' && resDenda.data != null) {
        final List<dynamic> dendaData = (resDenda.data is Map)
            ? (resDenda.data['data'] ?? [])
            : (resDenda.data is List ? resDenda.data : []);
        final List<Denda> parsedDenda = [];
        for (var item in dendaData) {
          final d = Denda.fromJson(item);
          parsedDenda.add(d);
          final statusBayar = (item['status_bayar'] ?? '')
              .toString()
              .toLowerCase();
          if (statusBayar == 'belum lunas') {
            final double amt =
                double.tryParse((item['jumlah_denda'] ?? '0').toString()) ??
                0.0;
            unpaidDenda += amt.toInt();
          }
        }
        if (mounted) {
          setState(() {
            _unpaidDendaList = parsedDenda
                .where(
                  (d) =>
                      (d.statusBayar?.toLowerCase() ?? '') == 'belum lunas' ||
                      (d.status.toLowerCase() == 'unpaid'),
                )
                .toList();
          });
        }
      }

      if (mounted) {
        setState(() {
          _totalAlat = countAlat;
          _activeLoans = active;
          _returnedCount = returned;
          _totalDenda = unpaidDenda;
        });
      }
    } catch (e) {
      debugPrint("Error fetching admin stats: $e");
    } finally {
      if (showLoading && mounted) {
        setState(() => _isHomeLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
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

  Widget _buildProfileIcon({double radius = 50}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
      child: Icon(Icons.person, size: radius * 1.2, color: AppColors.primary),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      width: 105,
      height: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withValues(alpha: 0.1),
            radius: 20,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor == AppColors.black
                  ? AppColors.black54
                  : textColor,
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
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

  Widget _buildHomeView() {
    return RefreshIndicator(
      onRefresh: () => _fetchStats(showLoading: false),
      color: AppColors.primary,
      notificationPredicate: (n) => n.depth == 0 && _allowRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            title: const Text(
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
          ),
          if (_isHomeLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Text
                    Text(
                      'Selamat datang, $_adminName',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kelola peminjaman alat dengan mudah.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Statistik Horizontal List
                    const Text(
                      'Statistik',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Listener(
                      onPointerDown: (_) => _allowRefresh = false,
                      onPointerUp: (_) => _allowRefresh = true,
                      onPointerCancel: (_) => _allowRefresh = true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatCard(
                              label: 'Total Alat',
                              value: '$_totalAlat',
                              icon: Icons.inventory_2_outlined,
                              iconColor: AppColors.primary,
                              textColor: AppColors.black,
                            ),
                            const SizedBox(width: 10),
                            _buildStatCard(
                              label: 'Pinjaman',
                              value: '$_activeLoans',
                              icon: Icons.outbox,
                              iconColor: AppColors.success,
                              textColor: AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            _buildStatCard(
                              label: 'Pengembalian',
                              value: '$_returnedCount',
                              icon: Icons.move_to_inbox,
                              iconColor: AppColors.warning,
                              textColor: AppColors.warning,
                            ),
                            const SizedBox(width: 10),
                            _buildStatCard(
                              label: 'Total Denda',
                              value: 'Rp ${_formatCurrency(_totalDenda)}',
                              icon: Icons.report_problem_outlined,
                              iconColor: AppColors.error,
                              textColor: AppColors.error,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Pinjaman Aktif Section ──
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
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _currentIndex = 2;
                            });
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.primaryDark,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(
                                color: AppColors.primaryDark,
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _activeLoanList.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ada peminjaman aktif',
                                style: TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : Column(
                              children: _activeLoanList.take(3).map((loan) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Builder(
                                        builder: (context) {
                                          final cachedAlat =
                                              Alat.cache[loan.alatId];
                                          final firstFoto =
                                              cachedAlat?.firstFoto;
                                          if (firstFoto != null &&
                                              firstFoto.isNotEmpty) {
                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                firstFoto,
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
                                                      width: 60,
                                                      height: 60,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            AppColors.grey200,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons
                                                              .inventory_2_outlined,
                                                          color: AppColors.grey,
                                                        ),
                                                      ),
                                                    ),
                                              ),
                                            );
                                          }
                                          return Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: AppColors.grey200,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.inventory_2_outlined,
                                                color: AppColors.grey,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              Alat
                                                      .cache[loan.alatId]
                                                      ?.namaAlat ??
                                                  loan.namaAlat ??
                                                  'Nama Alat',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.black,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Dipinjam: ${loan.tanggalPinjam}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Jatuh tempo: ${loan.tanggalKembali}',
                                              style: const TextStyle(
                                                fontSize: 12,
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
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              'Aktif',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // ── Denda Belum Bayar Section ──
                    const Text(
                      'Denda Belum Bayar',
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
                      child: _unpaidDendaList.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ditemukan denda',
                                style: TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : Column(
                              children: _unpaidDendaList.take(3).map((denda) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () {
                                      final p = _allLoans.firstWhere(
                                        (loan) => loan.id == denda.peminjamanId,
                                        orElse: () => Peminjaman(
                                          id: denda.peminjamanId,
                                          userId: denda.userId,
                                          alatId: 0,
                                          tanggalPinjam: '-',
                                          tanggalKembali: '-',
                                          status: 'unknown',
                                          jumlah: denda.jumlah.toInt(),
                                        ),
                                      );

                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: AppColors.white,
                                        showDragHandle: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(24),
                                          ),
                                        ),
                                        builder: (_) => DendaModal(
                                          item: PeminjamanItem(
                                            peminjaman: p,
                                            denda: denda,
                                          ),
                                          denda: denda,
                                          buildCheckered:
                                              ({
                                                double width = 80,
                                                double height = 80,
                                                double radius = 8,
                                              }) {
                                                return _buildPlaceholderImage(
                                                  width: width,
                                                  height: height,
                                                );
                                              },
                                          onLunas: () async {
                                            Navigator.of(context).pop();
                                            final res = await ApiService.put(
                                              'api/admin/denda/lunas',
                                              {'id': denda.id},
                                            );
                                            if (res.status == 'success') {
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Status denda diperbarui ke Lunas.',
                                                    ),
                                                  ),
                                                );
                                              }
                                              _fetchStats();
                                            } else {
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(res.message),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  denda.namaMahasiswa ?? 'User',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Alat: ${denda.namaAlat ?? '-'}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  denda.jenisDenda ?? 'Denda',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Rp ${_formatCurrency(denda.jumlah.toInt())}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.error,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
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

  Widget _buildProfileView() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverAppBar(
          title: Text(
            'Profil',
            style: TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: AppColors.white,
          elevation: 0,
          pinned: true,
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                // Box 1: Profile circular catur
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildProfileIcon(radius: 60),
                      const SizedBox(height: 20),
                      Text(
                        _adminName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Box 2: Info Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mail_outline,
                        color: AppColors.black,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _adminEmail,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Box 3: Red Logout Button
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scaleX: -1,
                        child: const Icon(
                          Icons.logout,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Keluar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: [
        _buildHomeView(),
        const AlatListScreen(isTab: true),
        const PeminjamanListScreen(isTab: true),
        _buildProfileView(),
      ][_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        // Map the 5-item nav bar to 4 real tabs:
        // 0=Beranda, 1=Katalog, 2=Scan-QR(push route), 3=Peminjaman, 4=Profil
        currentIndex: _currentIndex >= 2 ? _currentIndex + 1 : _currentIndex,
        onTap: (navIndex) {
          if (navIndex == 2) {
            // Scan-QR: push as full-screen route so camera is only on when scanning
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const QRScannerScreen(action: 'return'),
              ),
            );
            return;
          }
          setState(() {
            // Remap nav indices: 0→0, 1→1, skip 2, 3→2, 4→3
            _currentIndex = navIndex < 2 ? navIndex : navIndex - 1;
            if (_currentIndex == 0) {
              _fetchStats(showLoading: true);
            }
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.grey,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Katalog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_outlined),
            activeIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan-QR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Manajemen Peminjaman',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
