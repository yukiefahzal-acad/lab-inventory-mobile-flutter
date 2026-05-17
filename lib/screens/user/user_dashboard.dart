import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_service.dart';
import '../../models/models.dart';
import '../auth/login_screen.dart';
import 'peminjaman_form_screen.dart';
import 'qr_scanner_screen.dart';
import 'user_denda_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0;
  List<Peminjaman> _activeLoans = [];
  bool _isLoading = true;
  String _userName = 'Pinaya';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      final parts = savedEmail.split('@');
      if (parts.isNotEmpty) {
        _userName = parts[0];
      }
    }

    final res = await ApiService.get('api/user/peminjaman/active');
    if (res.status == 'success' && res.data != null) {
      final List<dynamic> data = res.data;
      setState(() {
        _activeLoans = data.map((e) => Peminjaman.fromJson(e)).toList();
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Widget _buildLogo({double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF6558A5).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Image.asset(
          '/images/logo_unibi.png',
          width: size * 0.7,
          height: size * 0.7,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/logo_unibi.png',
              width: size * 0.7,
              height: size * 0.7,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.handyman_outlined,
                  color: const Color(0xFF6558A5),
                  size: size * 0.5,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari alat',
              suffixIcon: const Icon(Icons.search, color: Color(0xFF6558A5)),
              filled: true,
              fillColor: Colors.white,
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
          const SizedBox(height: 24),
          Text(
            'Selamat datang, $_userName',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kelola peminjaman dan denda Anda di sini.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Pinjaman Aktif',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                },
                child: const Row(
                  children: [
                    Text(
                      'Lihat semua',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _activeLoans.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: Color(0xFF6558A5),
                        size: 40,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Tidak ada pinjaman aktif',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4C457A),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: _activeLoans.map((loan) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.handyman_outlined,
                                color: Color(0xFF6558A5),
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kode: UNI-00${loan.alatId}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4C457A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Nama Alat',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Dipinjam: ${loan.tanggalPinjam}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Jatuh tempo: ${loan.tanggalKembali}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
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
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Peminjaman',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                },
                child: const Row(
                  children: [
                    Text(
                      'Lihat semua',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildHistoryItem(
                  code: 'UNI-002',
                  name: 'Kabel HDMI 5m',
                  borrowDate: '08/05/2026',
                  dueDate: '09/05/2026',
                  status: 'Selesai',
                  isDenda: false,
                ),
                const Divider(),
                _buildHistoryItem(
                  code: 'UNI-003',
                  name: 'Mouse Logitech',
                  borrowDate: '01/05/2026',
                  dueDate: '03/05/2026',
                  status: 'Denda',
                  isDenda: true,
                ),
                const Divider(),
                _buildHistoryItem(
                  code: 'UNI-004',
                  name: 'Keyboard Mechanical',
                  borrowDate: '25/04/2026',
                  dueDate: '28/04/2026',
                  status: 'Denda',
                  isDenda: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Manajemen Denda',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Denda',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rp 250.000',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6558A5),
                      ),
                    ),
                    Text(
                      'Belum Lunas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline_outlined,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bayar denda tepat waktu untuk menghindari pembatasan peminjaman!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC53030),
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildHistoryItem({
    required String code,
    required String name,
    required String borrowDate,
    required String dueDate,
    required String status,
    required bool isDenda,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.handyman_outlined,
                color: Color(0xFF6558A5),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kode: $code',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4C457A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dipinjam: $borrowDate',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jatuh tempo: $dueDate',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDenda
                  ? const Color(0xFFFDE8E8)
                  : const Color(0xFFDEF7EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDenda ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanQRView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.qr_code_scanner_outlined,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Layanan QR Code',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pilih jenis layanan QR yang ingin Anda gunakan',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 36),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QRScannerScreen(action: 'booking'),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Scan QR Peminjaman Alat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6558A5),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QRScannerScreen(action: 'return'),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR Pengembalian Alat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6558A5),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Seluruh Riwayat Peminjaman',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildHistoryItem(
                      code: 'UNI-001',
                      name: 'Proyektor Epson',
                      borrowDate: '10/05/2026',
                      dueDate: '15/05/2026',
                      status: 'Aktif',
                      isDenda: false,
                    ),
                    const Divider(),
                    _buildHistoryItem(
                      code: 'UNI-002',
                      name: 'Kabel HDMI 5m',
                      borrowDate: '08/05/2026',
                      dueDate: '09/05/2026',
                      status: 'Selesai',
                      isDenda: false,
                    ),
                    const Divider(),
                    _buildHistoryItem(
                      code: 'UNI-003',
                      name: 'Mouse Logitech',
                      borrowDate: '01/05/2026',
                      dueDate: '03/05/2026',
                      status: 'Denda',
                      isDenda: true,
                    ),
                    const Divider(),
                    _buildHistoryItem(
                      code: 'UNI-004',
                      name: 'Keyboard Mechanical',
                      borrowDate: '25/04/2026',
                      dueDate: '28/04/2026',
                      status: 'Denda',
                      isDenda: true,
                    ),
                  ],
                ),
              ),
            ],
          );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _buildLogo(size: 80),
                const SizedBox(height: 16),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4C457A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mahasiswa UNIBI',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.badge_outlined,
                    color: Color(0xFF6558A5),
                  ),
                  title: const Text('NIM'),
                  subtitle: const Text('224111006'),
                  trailing: Icon(
                    Icons.copy,
                    color: Colors.grey.shade400,
                    size: 18,
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF6558A5),
                  ),
                  title: const Text('E-Mail'),
                  subtitle: Text('pinaya@gmail.com'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.payments_outlined,
                    color: Color(0xFF6558A5),
                  ),
                  title: const Text('Denda Belum Dibayar'),
                  subtitle: const Text('Rp 250.000'),
                  trailing: const Text(
                    'BAYAR',
                    style: TextStyle(
                      color: Color(0xFF6558A5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UserDendaScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Keluar dari Akun'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Color(0xFF6558A5),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Color(0xFF6558A5),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeView(),
                _buildScanQRView(),
                _buildHistoryView(),
                _buildProfileView(),
              ],
            ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PeminjamanFormScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF6558A5),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF6558A5),
        unselectedItemColor: Colors.grey,
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
            icon: Icon(Icons.qr_code_scanner_outlined),
            activeIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan QR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Riwayat',
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
