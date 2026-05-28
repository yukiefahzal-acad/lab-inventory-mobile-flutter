import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/models.dart';

class AlatDetailModal {
  static Future<void> show(
    BuildContext context, {
    required Alat alat,
    required Future<void> Function(int alatId, int quantity) onSubmit,
  }) {
    int quantity = 1;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dismiss handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Gallery Carousel Placeholder
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildPlaceholderImage(width: double.infinity, height: 160),
                      Positioned(
                        left: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.8),
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left, color: AppColors.black, size: 18),
                            padding: EdgeInsets.zero,
                            onPressed: () {},
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.8),
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right, color: AppColors.black, size: 18),
                            padding: EdgeInsets.zero,
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Tool Name & Available Stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          alat.nama.isEmpty ? 'Nama Alat' : alat.nama,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Stok: ${alat.statusAwal.isNotEmpty ? alat.statusAwal : "X"}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Tool Description
                  Text(
                    alat.deskripsi.isEmpty
                        ? 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor.'
                        : alat.deskripsi,
                    style: const TextStyle(fontSize: 14, color: AppColors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tool Notes
                  const Text(
                    'Catatan alat:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bolong pada bagian bawah kiri',
                    style: TextStyle(fontSize: 14, color: AppColors.black),
                  ),
                  const SizedBox(height: 16),
                  
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
                  _buildDendaRow('Denda per hari', 'Rp 10.000'),
                  const SizedBox(height: 4),
                  _buildDendaRow('Denda rusak', 'Rp 100.000'),
                  const SizedBox(height: 4),
                  _buildDendaRow('Denda hilang', 'Rp 500.000'),
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
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 32),
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
                          border: Border.all(color: AppColors.grey.withOpacity(0.5)),
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
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 32),
                        onPressed: () {
                          setModalState(() {
                            quantity++;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onSubmit(alat.id ?? 1, quantity);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Pinjam Alat'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildPlaceholderImage({double width = 80, double height = 80}) {
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

  static Widget _buildDendaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black)),
      ],
    );
  }
}
