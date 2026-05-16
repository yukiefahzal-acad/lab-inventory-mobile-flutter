import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/api_service.dart';
import 'peminjaman_form_screen.dart';

class QRScannerScreen extends StatefulWidget {
  final String action; // 'booking' or 'return'
  const QRScannerScreen({super.key, required this.action});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isProcessing = false;
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleScan(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? qrCode = barcodes.first.rawValue;
      if (qrCode == null) return;

      setState(() => _isProcessing = true);
      _controller.stop();

      if (widget.action == 'booking') {
        // Quick book via QR
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => PeminjamanFormScreen(initialAlatId: qrCode)),
        );
      } else if (widget.action == 'return') {
        // Return verification matching physical QR with active database records
        final res = await ApiService.post('api/pengembalian', {'qr_code': qrCode});
        if (!mounted) return;
        if (res.status == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alat berhasil dikembalikan.')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
        }
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.action == 'booking' ? 'Scan Alat untuk Pinjam' : 'Scan Alat untuk Kembali')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleScan,
          ),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator()),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Arahkan kamera ke QR Code pada alat',
                style: TextStyle(color: Colors.white, backgroundColor: Colors.black54, fontSize: 16),
              ),
            ),
          )
        ],
      ),
    );
  }
}
