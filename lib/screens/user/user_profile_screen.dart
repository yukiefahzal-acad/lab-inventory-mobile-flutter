import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_service.dart';
import '../../core/app_colors.dart';
import '../auth/login_screen.dart';
import 'user_denda_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = true;
  bool _allowRefresh = true;
  String _userName = 'User';
  String _userNimNip = '';
  String _userEmail = '';
  int _totalDendaUnpaid = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('nama') ?? 'User';
        _userNimNip = prefs.getString('nim_nip') ?? '';
        _userEmail = prefs.getString('email') ?? '';
      });

      final resDenda = await ApiService.get('api/user/denda');
      if (resDenda.status == 'success' && resDenda.data != null) {
        final List<dynamic> dendaData = (resDenda.data is Map)
            ? (resDenda.data['data'] ?? [])
            : (resDenda.data is List ? resDenda.data : []);
        int unpaidSum = 0;
        for (var item in dendaData) {
          final statusBayar = (item['status_bayar'] ?? '').toString().toLowerCase();
          if (statusBayar == 'belum lunas') {
            final double amt = double.tryParse((item['jumlah_denda'] ?? '0').toString()) ?? 0.0;
            unpaidSum += amt.toInt();
          }
        }
        setState(() {
          _totalDendaUnpaid = unpaidSum;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile data: $e");
    } finally {
      if (showLoading) setState(() => _isLoading = false);
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

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  Widget _buildProfileIcon({double radius = 50}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
      child: Icon(
        Icons.person,
        size: radius * 1.2,
        color: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _fetchProfileData(showLoading: false),
              color: AppColors.primary,
              notificationPredicate: (n) => (n.depth == 0 || n.depth == 1) && _allowRefresh,
              child: CustomScrollView(
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
                    automaticallyImplyLeading: false,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    sliver: SliverToBoxAdapter(
                      child: Listener(
                        onPointerDown: (_) => _allowRefresh = false,
                        onPointerUp: (_) => _allowRefresh = true,
                        onPointerCancel: (_) => _allowRefresh = true,
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
                                  _buildProfileIcon(radius: 60),
                                  const SizedBox(height: 20),
                                  Text(
                                    _userName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _userNimNip,
                                    style: const TextStyle(fontSize: 15, color: AppColors.black),
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
                                        _userEmail,
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
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context)
                                          .push(
                                            MaterialPageRoute(
                                              builder: (_) => const UserDendaScreen(),
                                            ),
                                          )
                                          .then((_) {
                                            _fetchProfileData(showLoading: false);
                                          });
                                    },
                                    child: Row(
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
                                              Text(
                                                'Rp ${_formatCurrency(_totalDendaUnpaid)}',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: AppColors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right, color: AppColors.grey),
                                      ],
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
