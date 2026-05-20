import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../core/api_service.dart';
// import '../../models/models.dart';
// import '../auth/login_screen.dart';
import '../../core/api_client.dart';
import '../../models/peminjaman_model.dart';
import '../../services/auth_service.dart';
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
  List<Peminjaman> _activeLoans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActiveLoans();
  }

  Future<void> _fetchActiveLoans() async {
    setState(() => _isLoading = true);
    // final res = await ApiService.get('api/user/peminjaman/active');
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}api/user/peminjaman/riwayat'),
      headers: await ApiClient.getHeaders(),
    );
    final res = ApiClient.processResponse(response);
    if (res.status == 'success' && res.data != null) {
      final List<dynamic> data = res.data;
      setState(() {
        _activeLoans = data.map((e) => Peminjaman.fromJson(e)).toList();
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.clear();
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pinjaman Aktif Anda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _activeLoans.isEmpty
                      ? const Text('Tidak ada pinjaman aktif.')
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _activeLoans.length,
                            itemBuilder: (context, index) {
                              final loan = _activeLoans[index];
                              return Card(
                                color: Colors.blue.shade50,
                                child: ListTile(
                                  title: Text('ID Alat: ${loan.alatId}'),
                                  // subtitle: Text('Batas Kembali: ${loan.tanggalKembali}\nStatus: ${loan.status}'),
                                  subtitle: Text('Batas Kembali: ${loan.tanggalKembaliRencana}\nStatus: ${loan.status}'),
                                  trailing: const Icon(Icons.warning, color: Colors.orange),
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PeminjamanFormScreen())),
                        icon: const Icon(Icons.add),
                        label: const Text('Pinjam Alat'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QRScannerScreen(action: 'return'))),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Kembalikan (QR)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserDendaScreen())),
                    icon: const Icon(Icons.money_off),
                    label: const Text('Cek Tagihan Denda'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                  )
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QRScannerScreen(action: 'booking'))),
        tooltip: 'Quick Book QR',
        child: const Icon(Icons.qr_code),
      ),
    );
  }
}
