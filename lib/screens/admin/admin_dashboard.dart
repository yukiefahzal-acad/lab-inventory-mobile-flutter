import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import 'alat_list_screen.dart';
import 'denda_list_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Statistik Peminjaman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 20,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0: return const Text('Sen');
                              case 1: return const Text('Sel');
                              case 2: return const Text('Rab');
                              case 3: return const Text('Kam');
                              case 4: return const Text('Jum');
                              default: return const Text('');
                            }
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.blue)]),
                      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 10, color: Colors.blue)]),
                      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 14, color: Colors.blue)]),
                      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 15, color: Colors.blue)]),
                      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 13, color: Colors.blue)]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildMenuCard(context, 'Kelola Alat', Icons.build, const AlatListScreen()),
                  _buildMenuCard(context, 'Validasi Denda', Icons.money, const DendaListScreen()),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Widget destination) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
