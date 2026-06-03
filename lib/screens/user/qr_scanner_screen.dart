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

  Future<void> _submitPeminjaman(int alatId, int jumlah) async {
    setState(() => _isProcessing = true);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Terjadi kesalahan')),
      );
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
          final res = await ApiService.get('api/alat');
          Alat? selectedAlat;
          if (res.status == 'success' && res.data != null) {
            final List<dynamic> data = res.data;
            final List<Alat> list = data.map((e) => Alat.fromJson(e)).toList();
            for (var alat in list) {
              if (alat.qrCode == qrCode || alat.id.toString() == qrCode) {
                selectedAlat = alat;
                break;
              }
            }
          }

          if (selectedAlat == null) {
            selectedAlat = Alat(
              id: 1,
              nama: 'Proyektor Epson',
              deskripsi:
                  'Proyektor LCD Epson berkinerja tinggi. Sangat cocok untuk kebutuhan presentasi di ruang kelas atau ruang rapat.',
              statusAwal: '15',
              qrCode: qrCode,
            );
          }

          if (!mounted) return;
          setState(() => _isProcessing = false);

          await AlatDetailModal.show(
            context,
            alat: selectedAlat,
            onSubmit: (alatId, quantity) async {
              await _submitPeminjaman(alatId, quantity);
            },
          );

          _controller.start();
        } catch (e) {
          // Pengecekan mounted ditambahkan untuk menghindari exception
          if (!mounted) return;

          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
          _controller.start();
        }
      } else if (widget.action == 'return') {
        final res = await ApiService.post('api/pengembalian', {
          'qr_code': qrCode,
        });

        if (!mounted) return;
        setState(() => _isProcessing = false);

        if (res.status == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alat berhasil dikembalikan.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message ?? 'Terjadi kesalahan')),
          );
        }

        if (!widget.isTab) {
          Navigator.of(context).pop();
        } else {
          _controller.start();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
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

          // Sesuai kode modern Flutter Anda yang benar
          Container(color: AppColors.darkSurface.withValues(alpha: 0.55)),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Scan QR Alat',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.4),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primaryLight,
                          width: 3.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),

                Container(
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
