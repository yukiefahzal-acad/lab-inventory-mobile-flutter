import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_service.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';
import '../../widgets/alat_detail_modal.dart';
import '../auth/login_screen.dart';
import 'qr_scanner_screen.dart';

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
  String _selectedCategory = 'Monitor';
  List<Alat> _alatList = [];
  bool _isLoadingAlat = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchAlat();
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

  Future<void> _fetchAlat() async {
    setState(() => _isLoadingAlat = true);
    final res = await ApiService.get('api/alat');
    if (res.status == 'success' && res.data != null) {
      final List<dynamic> data = res.data;
      setState(() {
        _alatList = data.map((e) => Alat.fromJson(e)).toList();
      });
    } else {
      setState(() {
        _alatList = [
          Alat(
            id: 1,
            nama: 'Title',
            deskripsi:
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor',
            statusAwal: '50',
            qrCode: '1',
          ),
          Alat(
            id: 2,
            nama: 'Title',
            deskripsi:
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor',
            statusAwal: '12',
            qrCode: '2',
          ),
          Alat(
            id: 3,
            nama: 'Title',
            deskripsi:
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor',
            statusAwal: '8',
            qrCode: '3',
          ),
          Alat(
            id: 4,
            nama: 'Title',
            deskripsi:
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor',
            statusAwal: '15',
            qrCode: '4',
          ),
        ];
      });
    }
    setState(() => _isLoadingAlat = false);
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
        color: Colors.grey.shade100,
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
              color: isEven ? Colors.white : Colors.grey.shade300,
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
              suffixIcon: const Icon(Icons.search, color: AppColors.primary),
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
          const SizedBox(height: 24),
          Text(
            'Selamat datang, $_userName',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kelola peminjaman dan denda Anda di sini.',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
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
                  color: AppColors.white,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                },
                child: Row(
                  children: [
                    Text(
                      'Lihat semua',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.white.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _activeLoans.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _buildPlaceholderImage(width: 72, height: 72),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kode: UNI-000',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Nama Alat',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.grey,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Dipinjam: DD/MM/YYYY',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.grey,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Jatuh tempo: DD/MM/YYYY',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
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
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          _buildPlaceholderImage(width: 72, height: 72),
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
                                    color: AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Nama Alat',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
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
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Peminjaman',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                },
                child: Row(
                  children: [
                    Text(
                      'Lihat semua',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.white.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildHistoryItem(
                  code: 'UNI-000',
                  name: 'Nama Alat',
                  borrowDate: 'DD/MM/YYYY',
                  dueDate: 'DD/MM/YYYY',
                  status: 'Selesai',
                  isDenda: false,
                ),
                const Divider(),
                _buildHistoryItem(
                  code: 'UNI-000',
                  name: 'Nama Alat',
                  borrowDate: 'DD/MM/YYYY',
                  dueDate: 'DD/MM/YYYY',
                  status: 'Denda',
                  isDenda: true,
                ),
                const Divider(),
                _buildHistoryItem(
                  code: 'UNI-000',
                  name: 'Nama Alat',
                  borrowDate: 'DD/MM/YYYY',
                  dueDate: 'DD/MM/YYYY',
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
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Denda',
                  style: TextStyle(fontSize: 13, color: AppColors.grey),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Rp 250.000',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 14, fontFamily: 'Manrope'),
                    children: [
                      TextSpan(
                        text: 'Status: ',
                        style: TextStyle(color: AppColors.grey),
                      ),
                      TextSpan(
                        text: 'Belum Lunas',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.dangerous_outlined,
                      color: AppColors.black,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Bayar denda tepat waktu untuk menghindari pembatasan peminjaman!',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.grey,
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
          _buildPlaceholderImage(width: 60, height: 60),
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
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dipinjam: $borrowDate',
                  style: const TextStyle(fontSize: 11, color: AppColors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jatuh tempo: $dueDate',
                  style: const TextStyle(fontSize: 11, color: AppColors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDenda ? AppColors.errorBg : AppColors.successBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDenda ? AppColors.error : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPeminjaman(int alatId, int jumlah) async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final formattedPinjam =
        "${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}";
    final returnDate = now.add(const Duration(days: 3));
    final formattedKembali =
        "${returnDate.month.toString().padLeft(2, '0')}/${returnDate.day.toString().padLeft(2, '0')}/${returnDate.year}";

    final res = await ApiService.post('api/peminjaman', {
      'alat_id': alatId,
      'tanggal_pinjam': formattedPinjam,
      'tanggal_kembali': formattedKembali,
      'jumlah': jumlah,
    });

    setState(() => _isLoading = false);

    if (!mounted) return;
    if (res.status == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peminjaman berhasil diajukan!')),
      );
      _fetchDashboardData();
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
      onSubmit: (alatId, quantity) => _submitPeminjaman(alatId, quantity),
    );
  }

  Widget _buildKatalogView() {
    return _isLoadingAlat
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: 'Cari alat',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                      prefixIcon: SizedBox(width: 8),
                      suffixIcon: Icon(Icons.search, color: Colors.black54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    children: ['Monitor', 'Tools', 'Kabel', 'Tester'].map((
                      cat,
                    ) {
                      final isActive = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFD5CDF3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFFD5CDF3)
                                    : Colors.white54,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFF1E1548)
                                    : AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: _alatList.length,
                  itemBuilder: (context, index) {
                    final alat = _alatList[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPlaceholderImage(
                            width: double.infinity,
                            height: 120,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alat.nama.isEmpty ? 'Title' : alat.nama,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        alat.deskripsi.isEmpty
                                            ? 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor'
                                            : alat.deskripsi,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _showAlatDetailModal(context, alat),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E1548),
                                      foregroundColor: AppColors.white,
                                      minimumSize: const Size(
                                        double.infinity,
                                        36,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      'Detail Alat',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
  }

  Widget _buildHistoryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari alat',
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
          const SizedBox(height: 20),
          _buildMockupHistoryCard(
            name: 'Nama Alat',
            quantity: 'x1',
            leftText: 'Status',
            rightText: 'Menunggu Diambil',
            isBoldRight: true,
          ),
          _buildMockupHistoryCard(
            name: 'Nama Alat',
            quantity: 'x1',
            leftText: '31/12/1999',
            rightText: 'Denda: Rp 0',
          ),
          _buildMockupHistoryCard(
            name: 'Nama Alat',
            quantity: 'x1',
            leftText: '31/12/1999',
            rightText: 'Denda: Rp 0',
          ),
          _buildMockupHistoryCard(
            name: 'Nama Alat',
            quantity: 'x1',
            leftText: '31/12/1999',
            rightText: 'Denda: Rp 0',
          ),
          _buildMockupHistoryCard(
            name: 'Nama Alat',
            quantity: 'x1',
            leftText: '31/12/1999',
            rightText: 'Denda: Rp 0',
          ),
          _buildMockupHistoryCard(
            name: 'Nama Alat',
            quantity: 'x1',
            leftText: '31/12/1999',
            rightText: 'Denda: Rp 0',
          ),
        ],
      ),
    );
  }

  Widget _buildMockupHistoryCard({
    required String name,
    required String quantity,
    required String leftText,
    required String rightText,
    bool isBoldRight = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildPlaceholderImage(width: 80, height: 80),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      quantity,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      leftText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                    Text(
                      rightText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isBoldRight
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Box 1: Profile Circular Avatar & Name
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
                  'Pinaya Agustin',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '224111006',
                  style: TextStyle(fontSize: 15, color: AppColors.black),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Box 2: Email & Denda
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.mail_outline,
                      color: AppColors.black,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'pinaya@gmail.com',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      color: AppColors.black,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Denda Belum Dibayar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Rp 250.000',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Box 3: Red Logout Button
          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC53030),
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

  Widget _buildCheckeredCircleAvatar({double radius = 50}) {
    return ClipOval(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        color: Colors.grey.shade100,
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
              color: isEven ? Colors.white : Colors.grey.shade300,
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    if (_currentIndex != 0) {
      String title = '';
      if (_currentIndex == 1) title = 'Katalog';
      if (_currentIndex == 2) title = 'Riwayat Peminjaman';
      if (_currentIndex == 3) title = 'Profil';

      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () {
            setState(() {
              _currentIndex = 0;
            });
          },
        ),
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
      );
    }

    return AppBar(
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
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_outlined,
            color: AppColors.black,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeView(),
                _buildKatalogView(),
                _buildHistoryView(),
                _buildProfileView(),
              ],
            ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const QRScannerScreen(action: 'booking'),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.qr_code_scanner, size: 28),
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
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
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
