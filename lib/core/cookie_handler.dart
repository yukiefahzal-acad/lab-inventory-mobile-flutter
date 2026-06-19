import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CookieHandler {
  static Future<void> fetchInfinityCookie() async {
    final String url = dotenv.env['BASE_URL'] ?? 'http://unibilab.freehosting.dev/';

    // 1. Inisialisasi WebView tersembunyi dengan User-Agent yang sama persis seperti di ApiService
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36')
      ..loadRequest(Uri.parse(url));

    // 2. Tunggu beberapa detik agar JS dari InfinityFree selesai dieksekusi
    // dan halaman me-reload secara otomatis membawa cookie
    await Future.delayed(const Duration(seconds: 5));

    // 3. Ekstrak cookie dari WebView melalui Javascript (document.cookie)
    String testCookieValue = '';
    try {
      final Object result = await controller.runJavaScriptReturningResult('document.cookie');
      // result biasanya berupa String (bisa disertai kutip tambahan dari eval JS)
      final String cookiesStr = result.toString().replaceAll('"', ''); 
      
      final List<String> cookies = cookiesStr.split(';');
      for (var cookie in cookies) {
        cookie = cookie.trim();
        if (cookie.startsWith('__test=')) {
          testCookieValue = cookie.substring('__test='.length);
          break;
        }
      }
    } catch (e) {
      print('Gagal mengekstrak cookie via javascript: $e');
    }

    // 4. Simpan ke local storage agar bisa dibaca oleh ApiService
    if (testCookieValue.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('infinity_cookie', '__test=$testCookieValue');
      print('Cookie berhasil didapat otomatis: $testCookieValue');
    } else {
      print('Gagal mendapatkan cookie otomatis.');
    }
  }
}
