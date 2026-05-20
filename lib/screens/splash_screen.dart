import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';
import 'admin/admin_dashboard.dart';
import 'user/user_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      if (role?.toLowerCase() == 'admin') {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboard()));
      } else {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const UserDashboard()));
      }
    } else {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'auth/login_screen.dart';
// import 'admin/admin_dashboard.dart';
// import 'user/user_dashboard.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _checkSession();
//   }
//
//   Future<void> _checkSession() async {
//     await Future.delayed(const Duration(seconds: 2));
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');
//     final role = prefs.getString('role');
//
//     if (!mounted) return;
//
//     if (token != null && token.isNotEmpty) {
//       if (role == 'admin') {
//         Navigator.of(context).pushReplacement(
//             MaterialPageRoute(builder: (_) => const AdminDashboard()));
//       } else {
//         Navigator.of(context).pushReplacement(
//             MaterialPageRoute(builder: (_) => const UserDashboard()));
//       }
//     } else {
//       Navigator.of(context).pushReplacement(
//           MaterialPageRoute(builder: (_) => const LoginScreen()));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
//   }
// }
