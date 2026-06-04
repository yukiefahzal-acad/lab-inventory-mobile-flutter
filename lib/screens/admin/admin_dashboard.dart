import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../auth/login_screen.dart';
import '../user/qr_scanner_screen.dart';
import 'alat_list_screen.dart';
import 'peminjaman_list_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

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

  Widget _buildCheckeredCircleAvatar({double radius = 50}) {
    return ClipOval(
      child: Container(
        width: radius * 2,
        height: radius * 2,
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

  Widget _buildActiveLoanItem({
    required String code,
    required String name,
    required String borrowDate,
    required String dueDate,
    required String status,
    required Color statusTextColor,
    required Color statusBgColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _buildPlaceholderImage(width: 68, height: 68),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  style: TextStyle(fontSize: 13, color: AppColors.grey600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dipinjam: $borrowDate',
                  style: TextStyle(fontSize: 11, color: AppColors.grey600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jatuh tempo: $dueDate',
                  style: TextStyle(fontSize: 11, color: AppColors.grey600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Text
          const Text(
            'Selamat datang, Admin',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kelola peminjaman alat dengan mudah.',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard(
                  label: 'Total Alat',
                  value: '43',
                  icon: Icons.inventory_2_outlined,
                  iconColor: AppColors.primary,
                  textColor: AppColors.black,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  label: 'Pinjaman',
                  value: '12',
                  icon: Icons.outbox,
                  iconColor: AppColors.success,
                  textColor: AppColors.success,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  label: 'Pengembalian',
                  value: '2',
                  icon: Icons.move_to_inbox,
                  iconColor: AppColors.warning,
                  textColor: AppColors.warning,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  label: 'Total Denda',
                  value: 'Rp 10.000',
                  icon: Icons.report_problem_outlined,
                  iconColor: AppColors.error,
                  textColor: AppColors.error,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Pinjaman Aktif
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pinjaman Aktif',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 2),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildActiveLoanItem(
                  code: 'Kode: UNI-000',
                  name: 'Nama Alat',
                  borrowDate: 'DD/MM/YYYY',
                  dueDate: 'DD/MM/YYYY',
                  status: 'Selesai',
                  statusTextColor: AppColors.successDark,
                  statusBgColor: AppColors.successBg,
                ),
                const Divider(height: 1),
                _buildActiveLoanItem(
                  code: 'Kode: UNI-000',
                  name: 'Nama Alat',
                  borrowDate: 'DD/MM/YYYY',
                  dueDate: 'DD/MM/YYYY',
                  status: 'Aktif',
                  statusTextColor: AppColors.textPrimary,
                  statusBgColor: AppColors.primary,
                ),
                const Divider(height: 1),
                _buildActiveLoanItem(
                  code: 'Kode: UNI-000',
                  name: 'Nama Alat',
                  borrowDate: 'DD/MM/YYYY',
                  dueDate: 'DD/MM/YYYY',
                  status: 'Denda',
                  statusTextColor: AppColors.errorDark,
                  statusBgColor: AppColors.errorBg,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Denda Belum Bayar
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildPlaceholderImage(width: 68, height: 68),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pinaya Agustin',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Kode: UNI-000',
                        style: TextStyle(fontSize: 11, color: AppColors.grey),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Terlambat: X Hari',
                        style: TextStyle(fontSize: 11, color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Rp 200.000',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Denda',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.errorDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Box 1: Profile circular catur
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildCheckeredCircleAvatar(radius: 60),
                const SizedBox(height: 20),
                const Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.authBgTop,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Box 2: Info Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
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
                const Text(
                  'admin@mail.com',
                  style: TextStyle(
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar? _buildAppBar() {
    String title = '';
    List<Widget>? actions;

    if (_currentIndex == 0) {
      title = 'Dashboard';
      actions = [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_outlined,
            color: AppColors.black,
          ),
          onPressed: () {},
        ),
      ];
    } else if (_currentIndex == 1) {
      title = 'Katalog';
    } else if (_currentIndex == 2) {
      title = 'Peminjaman';
    } else if (_currentIndex == 3) {
      title = 'Profil';
    }

    return AppBar(
      leading: _currentIndex != 0
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.black),
              onPressed: () => setState(() => _currentIndex = 0),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: AppColors.white,
      elevation: 0,
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeView(),
          const AlatListScreen(isTab: true),
          const PeminjamanListScreen(isTab: true),
          _buildProfileView(),
        ],
      ),
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
            label: 'Peminjaman',
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
