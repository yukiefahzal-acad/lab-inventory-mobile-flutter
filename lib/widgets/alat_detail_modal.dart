import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/app_colors.dart';
import '../models/models.dart';

class AlatDetailModal {
  static Future<void> show(
    BuildContext context, {
    required Alat alat,
    Future<void> Function(
      int alatId,
      int quantity,
      String tanggalPinjam,
      String tanggalKembali,
    )?
    onSubmit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        int currentImageIndex = 0;
        final PageController pageController = PageController();
        int quantity = 1;
        final DateTime today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
        DateTime tanggalPinjam = today;
        DateTime tanggalKembali = today.add(const Duration(days: 3));

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom:
                    20 +
                    MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gallery Carousel
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (alat.fotoList.isNotEmpty)
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: PageView.builder(
                              controller: pageController,
                              onPageChanged: (index) {
                                setModalState(() {
                                  currentImageIndex = index;
                                });
                              },
                              itemCount: alat.fotoList.length,
                              itemBuilder: (context, index) {
                                return Image.network(
                                  alat.fotoList[index],
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildPlaceholderImage(
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                );
                              },
                            ),
                          ),
                        )
                      else
                        AspectRatio(
                          aspectRatio: 1,
                          child: _buildPlaceholderImage(
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      if (alat.fotoList.length > 1) ...[
                        Positioned(
                          left: 10,
                          child: CircleAvatar(
                            backgroundColor: AppColors.white.withValues(
                              alpha: 0.8,
                            ),
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(
                                Icons.chevron_left,
                                color: AppColors.black,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                if (currentImageIndex > 0) {
                                  pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          child: CircleAvatar(
                            backgroundColor: AppColors.white.withValues(
                              alpha: 0.8,
                            ),
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(
                                Icons.chevron_right,
                                color: AppColors.black,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                if (currentImageIndex <
                                    alat.fotoList.length - 1) {
                                  pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tool Name & Available Stock
                  if (alat.namaAlat.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            alat.namaAlat,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Stok: ${alat.stokTersedia}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Tool Description
                  if (alat.spesifikasi.isNotEmpty) ...[
                    Text(
                      alat.spesifikasi,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Denda Rules Table
                  const Text(
                    'Ketentuan denda:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDendaRow(
                    'Denda per hari (Rp)',
                    'Rp ${_formatCurrency(alat.dendaPerHari)}',
                  ),
                  const SizedBox(height: 4),
                  _buildDendaRow(
                    'Denda rusak (Rp)',
                    'Rp ${_formatCurrency(alat.dendaRusak)}',
                  ),
                  const SizedBox(height: 4),
                  _buildDendaRow(
                    'Denda hilang (Rp)',
                    'Rp ${_formatCurrency(alat.dendaHilang)}',
                  ),
                  const SizedBox(height: 20),

                  if (onSubmit == null &&
                      alat.qrCode != null &&
                      alat.qrCode!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'QR Code Alat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: QrImageView(
                        data: alat.qrCode!,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (onSubmit != null) ...[
                    // Date pickers for borrowing
                    const Text(
                      'Tanggal Peminjaman',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tanggal Pinjam',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: tanggalPinjam,
                                    firstDate: today,
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      tanggalPinjam = picked;
                                      if (tanggalKembali.isBefore(
                                        tanggalPinjam,
                                      )) {
                                        tanggalKembali = tanggalPinjam.add(
                                          const Duration(days: 1),
                                        );
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.grey.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${tanggalPinjam.year}-${tanggalPinjam.month.toString().padLeft(2, '0')}-${tanggalPinjam.day.toString().padLeft(2, '0')}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.black,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                        color: AppColors.primaryDark,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tanggal Kembali',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: tanggalKembali,
                                    firstDate: tanggalPinjam,
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      tanggalKembali = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.grey.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${tanggalKembali.year}-${tanggalKembali.month.toString().padLeft(2, '0')}-${tanggalKembali.day.toString().padLeft(2, '0')}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.black,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                        color: AppColors.primaryDark,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Borrow Quantity Selector
                    const Text(
                      'Jumlah',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: AppColors.primaryDark,
                            size: 32,
                          ),
                          onPressed: () {
                            if (quantity > 1) {
                              setModalState(() {
                                quantity--;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 60,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.grey.withValues(alpha: 0.5),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$quantity',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: AppColors.primaryDark,
                            size: 32,
                          ),
                          onPressed: () {
                            if (quantity < alat.stokTersedia) {
                              setModalState(() {
                                quantity++;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        final fmtPinjam =
                            "${tanggalPinjam.year}-${tanggalPinjam.month.toString().padLeft(2, '0')}-${tanggalPinjam.day.toString().padLeft(2, '0')}";
                        final fmtKembali =
                            "${tanggalKembali.year}-${tanggalKembali.month.toString().padLeft(2, '0')}-${tanggalKembali.day.toString().padLeft(2, '0')}";
                        onSubmit(alat.id ?? 1, quantity, fmtPinjam, fmtKembali);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Pinjam Alat'),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildPlaceholderImage({
    double width = 80,
    double height = 80,
  }) {
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

  static String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  static Widget _buildDendaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}
