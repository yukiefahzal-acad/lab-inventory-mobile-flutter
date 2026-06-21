import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';
import '../../widgets/alat_detail_modal.dart';
import 'qr_scanner_screen.dart';

class UserKatalogScreen extends StatefulWidget {
  const UserKatalogScreen({super.key});

  @override
  State<UserKatalogScreen> createState() => _UserKatalogScreenState();
}

class _UserKatalogScreenState extends State<UserKatalogScreen> {
  List<Alat> _alatList = [];
  bool _isLoadingAlat = true;
  bool _allowRefresh = true;
  String _selectedCategory = 'Semua';
  List<String> _categories = ['Semua'];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {});
    });
    _fetchAlat();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  Future<void> _fetchAlat({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoadingAlat = true);
    final res = await ApiService.get('api/alat');
    if (res.status == 'success' && res.data != null) {
      final List<dynamic> data = res.data;
      final parsed = data.map((e) => Alat.fromJson(e)).toList();

      final Set<String> uniqueCats = {};
      for (final alat in parsed) {
        uniqueCats.addAll(
          alat.kategoriList
              .map((c) => _capitalizeFirstLetter(c.trim()))
              .where((c) => c.isNotEmpty),
        );
      }

      setState(() {
        _alatList = parsed;
        _categories = ['Semua', ...uniqueCats.toList()..sort()];
      });
    } else {
      setState(() {
        _alatList = [];
        _categories = ['Semua'];
      });
    }
    if (showLoading) setState(() => _isLoadingAlat = false);
  }

  Future<void> _submitPeminjaman(
    int alatId,
    int jumlah,
    String tanggalPinjam,
    String tanggalKembali,
  ) async {
    // Show loading overlay or handle it silently
    final res = await ApiService.post('api/booking', {
      'alat_id': alatId,
      'tanggal_pinjam': tanggalPinjam,
      'tanggal_kembali_rencana': tanggalKembali,
      'jumlah': jumlah,
    });

    if (!mounted) return;
    if (res.status == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peminjaman berhasil diajukan!')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  void _showAlatDetailModal(BuildContext context, Alat alat) {
    AlatDetailModal.show(
      context,
      alat: alat,
      onSubmit: (alatId, quantity, tanggalPinjam, tanggalKembali) =>
          _submitPeminjaman(alatId, quantity, tanggalPinjam, tanggalKembali),
    );
  }

  Widget _buildPlaceholderImage({double width = 80, double height = 80}) {
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

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.toLowerCase();
    final filteredAlat = _alatList.where((alat) {
      final matchesSearch =
          alat.namaAlat.toLowerCase().contains(query) ||
          alat.spesifikasi.toLowerCase().contains(query);
      if (_selectedCategory == 'Semua') {
        return matchesSearch;
      } else {
        final matchesCat = alat.kategoriList.any(
          (c) => c.trim().toLowerCase() == _selectedCategory.toLowerCase(),
        );
        return matchesSearch && matchesCat;
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: _isLoadingAlat
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _fetchAlat(showLoading: false),
              color: AppColors.primary,
              notificationPredicate: (n) =>
                  (n.depth == 0 || n.depth == 1) && _allowRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    title: const Text(
                      'Katalog',
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
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(132),
                      child: Container(
                        color: AppColors.darkSurface,
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: TextField(
                                controller: _searchCtrl,
                                style: const TextStyle(
                                  color: AppColors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Cari alat',
                                  suffixIcon: const Icon(
                                    Icons.search,
                                    color: AppColors.black,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 40,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount: _categories.length,
                                itemBuilder: (context, index) {
                                  final cat = _categories[index];
                                  final isActive = _selectedCategory == cat;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedCategory = cat;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? AppColors.primary
                                              : AppColors.transparent,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppColors.primary,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          cat,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      // vertical: 16.0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Listener(
                        onPointerDown: (_) => _allowRefresh = false,
                        onPointerUp: (_) => _allowRefresh = true,
                        onPointerCancel: (_) => _allowRefresh = true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (filteredAlat.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 80.0),
                                  child: Text(
                                    'Tidak ada alat ditemukan.',
                                    style: TextStyle(
                                      color: AppColors.primaryDark,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.6,
                                    ),
                                itemCount: filteredAlat.length,
                                itemBuilder: (context, index) {
                                  final alat = filteredAlat[index];
                                  final desc = alat.spesifikasi.isNotEmpty
                                      ? alat.spesifikasi
                                      : 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor';
                                  return GestureDetector(
                                    onTap: () =>
                                        _showAlatDetailModal(context, alat),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (alat.firstFoto != null)
                                              Image.network(
                                                alat.firstFoto!,
                                                height: 120,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => _buildPlaceholderImage(
                                                      width: double.infinity,
                                                      height: 120,
                                                    ),
                                              )
                                            else
                                              _buildPlaceholderImage(
                                                width: double.infinity,
                                                height: 120,
                                              ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          alat.namaAlat,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: AppColors
                                                                    .black87,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Wrap(
                                                          spacing: 4,
                                                          runSpacing: 4,
                                                          children: alat.kategoriList.map((c) {
                                                            return Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: AppColors.grey200,
                                                                borderRadius: BorderRadius.circular(10),
                                                                border: Border.all(color: AppColors.grey300),
                                                              ),
                                                              child: Text(
                                                                _capitalizeFirstLetter(c.trim()),
                                                                style: const TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: AppColors.grey600,
                                                                ),
                                                              ),
                                                            );
                                                          }).toList(),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          desc,
                                                          maxLines: 3,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                color: AppColors
                                                                    .grey600,
                                                                fontSize: 11,
                                                                height: 1.3,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          _showAlatDetailModal(
                                                            context,
                                                            alat,
                                                          ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            AppColors.authBgTop,
                                                        foregroundColor:
                                                            AppColors
                                                                .textPrimary,
                                                        minimumSize: const Size(
                                                          double.infinity,
                                                          34,
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                      ),
                                                      child: const Text(
                                                        'Detail Alat',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const QRScannerScreen(action: 'booking'),
            ),
          );
        },
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, size: 28),
      ),
    );
  }
}
