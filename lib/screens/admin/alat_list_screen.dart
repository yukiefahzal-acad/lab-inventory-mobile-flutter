import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';
import '../../widgets/alat_detail_modal.dart';
import 'alat_form_screen.dart';

class AlatListScreen extends StatefulWidget {
  final bool isTab;
  const AlatListScreen({super.key, this.isTab = false});

  @override
  State<AlatListScreen> createState() => _AlatListScreenState();
}

class _AlatListScreenState extends State<AlatListScreen> {
  List<Alat> _allAlatList = [];
  List<Alat> _filteredAlatList = [];
  bool _isLoading = true;
  bool _allowRefresh = true;
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedFilterIndex = 0;
  List<String> _filters = ['Semua'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _fetchAlat();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _fetchAlat() async {
    setState(() => _isLoading = true);
    final res = await ApiService.get('api/alat');
    if (res.status == 'success' && res.data != null) {
      final List<dynamic> data = res.data;
      final parsed = data.map((e) => Alat.fromJson(e)).toList();
      
      final Set<String> uniqueCats = {};
      for (final alat in parsed) {
        uniqueCats.addAll(alat.kategoriList.map((c) => _capitalizeFirstLetter(c.trim())).where((c) => c.isNotEmpty));
      }
      
      if (mounted) {
        setState(() {
          _allAlatList = parsed;
          _filters = ['Semua', ...uniqueCats.toList()..sort()];
          _applyFilters();
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res.message)));
      }
    }
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredAlatList = _allAlatList.where((alat) {
        final matchesSearch =
            alat.namaAlat.toLowerCase().contains(query) ||
            alat.spesifikasi.toLowerCase().contains(query);

        if (_selectedFilterIndex == 0 || _filters.isEmpty) {
          return matchesSearch;
        } else {
          if (_selectedFilterIndex < _filters.length) {
            final selectedCategory = _filters[_selectedFilterIndex].toLowerCase();
            final hasCategory = alat.kategoriList.any((c) => c.trim().toLowerCase() == selectedCategory);
            return matchesSearch && hasCategory;
          }
          return matchesSearch;
        }
      }).toList();
    });
  }

  Widget _buildCheckeredImageHeader({double height = 120}) {
    return Container(
      width: double.infinity,
      height: height,
      color: AppColors.grey100,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 12,
        ),
        itemCount: 12 * 8,
        itemBuilder: (context, index) {
          final row = index ~/ 12;
          final col = index % 12;
          final isEven = (row + col) % 2 == 0;
          return Container(color: isEven ? AppColors.white : AppColors.grey200);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchAndFilterHeader = Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.black87),
              decoration: const InputDecoration(
                hintText: 'Cari alat',
                hintStyle: TextStyle(color: AppColors.grey, fontSize: 16),
                prefixIcon: SizedBox(width: 8),
                suffixIcon: Icon(Icons.search, color: AppColors.black54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // Filter chips horizontal list
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedFilterIndex == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilterIndex = index;
                      _applyFilters();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondary
                          : AppColors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.grey,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _filters[index],
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.textPrimary,
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
        const SizedBox(height: 12),
      ],
    );

    final gridContent = _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primaryLight),
          )
        : _filteredAlatList.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 80.0),
              child: Text(
                'Tidak ada alat ditemukan.',
                style: TextStyle(color: AppColors.primaryDark, fontSize: 16),
              ),
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.6,
            ),
            itemCount: _filteredAlatList.length,
            itemBuilder: (itemContext, index) {
              final alat = _filteredAlatList[index];
              final desc = alat.spesifikasi.isNotEmpty
                  ? alat.spesifikasi
                  : 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor';
              return GestureDetector(
                onTap: () {
                  AlatDetailModal.show(context, alat: alat);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (alat.firstFoto != null)
                          Image.network(
                            alat.firstFoto!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildCheckeredImageHeader(height: 120),
                          )
                        else
                          _buildCheckeredImageHeader(height: 120),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alat.namaAlat,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  desc,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.grey600,
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 34,
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (dialogContext) => AlertDialog(
                                              title: const Text('Hapus Alat'),
                                              content: Text(
                                                'Apakah Anda yakin ingin menghapus "${alat.namaAlat}"?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    dialogContext,
                                                  ).pop(false),
                                                  child: const Text('Batal'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    dialogContext,
                                                  ).pop(true),
                                                  child: const Text(
                                                    'Hapus',
                                                    style: TextStyle(
                                                      color: AppColors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            setState(() => _isLoading = true);
                                            final res = await ApiService.delete(
                                              'api/alat',
                                              {'id': alat.id},
                                            );
                                            if (!mounted) return;
                                            if (res.status == 'success') {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Alat berhasil dihapus',
                                                  ),
                                                ),
                                              );
                                              await _fetchAlat();
                                            } else {
                                              setState(() => _isLoading = false);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(res.message),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: AppColors.errorBg,
                                          ),
                                          backgroundColor: AppColors.errorBg,
                                          foregroundColor: AppColors.error,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: const Text(
                                          'Hapus',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: 34,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AlatFormScreen(
                                                    alat: alat,
                                                    availableCategories: _filters.where((f) => f != 'Semua').toList(),
                                                  ),
                                            ),
                                          );
                                          _fetchAlat();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.secondary,
                                          foregroundColor: AppColors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: EdgeInsets.zero,
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          'Ubah',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ));
            },
          );

    final fab = FloatingActionButton(
      onPressed: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => AlatFormScreen(
          availableCategories: _filters.where((f) => f != 'Semua').toList(),
        )));
        _fetchAlat();
      },
      backgroundColor: AppColors.secondary,
      foregroundColor: AppColors.white,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, size: 28),
    );

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: RefreshIndicator(
        onRefresh: _fetchAlat,
        color: AppColors.primaryDark,
        notificationPredicate: (n) => n.depth == 0 && _allowRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              leading: !widget.isTab
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : null,
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(124),
                child: Container(
                  color: AppColors.darkSurface,
                  child: searchAndFilterHeader,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Listener(
                onPointerDown: (_) => _allowRefresh = false,
                onPointerUp: (_) => _allowRefresh = true,
                onPointerCancel: (_) => _allowRefresh = true,
                child: Column(children: [gridContent]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: fab,
    );
  }
}
