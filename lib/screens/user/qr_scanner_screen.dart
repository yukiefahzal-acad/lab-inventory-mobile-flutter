import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/api_service.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';
import '../../widgets/alat_detail_modal.dart';

class QRScannerScreen extends StatefulWidget {
  final String action;
  final bool isTab;
  const QRScannerScreen({super.key, required this.action, this.isTab = false});

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

  Future<void> _submitPeminjaman(
    int alatId,
    int jumlah,
    String tanggalPinjam,
    String tanggalKembali,
  ) async {
    setState(() => _isProcessing = true);

    final res = await ApiService.post('api/booking', {
      'alat_id': alatId,
      'tanggal_pinjam': tanggalPinjam,
      'tanggal_kembali_rencana': tanggalKembali,
      'jumlah': jumlah,
    });

    // Pengecekan mounted ditambahkan sebelum merubah State/Context
    if (!mounted) return;

    setState(() => _isProcessing = false);

    if (res.status == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peminjaman berhasil diajukan!')),
      );
      if (!widget.isTab) {
        Navigator.of(context).pop();
      } else {
        _controller.start();
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.message)));
      _controller.start();
    }
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
        try {
          final res = await ApiService.post('api/scan', {'qr_code': qrCode});
          Alat? selectedAlat;
          if (res.status == 'success' && res.data != null) {
            final data = res.data is Map && res.data.containsKey('data')
                ? res.data['data']
                : res.data;
            if (data is Map<String, dynamic>) {
              selectedAlat = Alat.fromJson(data);
            }
          }

          if (selectedAlat == null) {
            if (!mounted) return;
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(res.message)));
            _controller.start();
            return;
          }

          if (!mounted) return;
          setState(() => _isProcessing = false);

          await AlatDetailModal.show(
            context,
            alat: selectedAlat,
            onSubmit: (alatId, quantity, tanggalPinjam, tanggalKembali) async {
              await _submitPeminjaman(
                alatId,
                quantity,
                tanggalPinjam,
                tanggalKembali,
              );
            },
          );

          _controller.start();
        } catch (e) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
          _controller.start();
        }
      } else if (widget.action == 'return') {
        try {
          // First scan to identify the alat
          final scanRes = await ApiService.post('api/scan', {
            'qr_code': qrCode,
          });
          Alat? scannedAlat;
          if (scanRes.status == 'success' && scanRes.data != null) {
            final data = scanRes.data is Map && scanRes.data.containsKey('data')
                ? scanRes.data['data']
                : scanRes.data;
            if (data is Map<String, dynamic>) {
              scannedAlat = Alat.fromJson(data);
            }
          }

          if (!mounted) return;

          if (scannedAlat == null) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(scanRes.message)));
            _controller.start();
            return;
          }

          // Show detail modal for verification (admin return)
          setState(() => _isProcessing = false);
          await AlatDetailModal.show(context, alat: scannedAlat);
          _controller.start();
        } catch (e) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
          _controller.start();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: const Text(
          'Scan-QR',
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleScan),

          // Transparent cutout overlay with white border
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  width: 5.0,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.transparent, spreadRadius: 9999),
                ],
              ),
            ),
          ),

          // Text Elements
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    'Scan QR Alat',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Pastikan kode QR berada di tengah',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),

          if (_isProcessing)
            Container(
              color: AppColors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primaryLight),
              ),
            ),
        ],
      ),
    );
  }
}
