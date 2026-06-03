import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';
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
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Monitor', 'Tools', 'Kabel', 'Tester'];

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

  Future<void> _fetchAlat() async {
    setState(() => _isLoading = true);
    final res = await ApiService.get('api/alat');
    if (res.status == 'success' && res.data != null) {
      final List<dynamic> data = res.data;
      setState(() {
        _allAlatList = data.map((e) => Alat.fromJson(e)).toList();
        _applyFilters();
      });
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
            alat.nama.toLowerCase().contains(query) ||
            alat.deskripsi.toLowerCase().contains(query);

        // Simulating category matching for filters:
        // 'Monitor', 'Tools', 'Kabel', 'Tester'
        if (_selectedFilterIndex == 0) {
          // Monitor: show all/any projector or screens
          return matchesSearch;
        } else if (_selectedFilterIndex == 1) {
          // Tools: e.g. tools
          return matchesSearch && !alat.nama.toLowerCase().contains('kabel');
        } else if (_selectedFilterIndex == 2) {
          // Kabel
          return matchesSearch && alat.nama.toLowerCase().contains('kabel');
        } else {
          // Tester
          return matchesSearch;
        }
      }).toList();
    });
  }

  Widget _buildCheckeredImageHeader({double height = 120}) {
    return Container(
      width: double.infinity,
      height: height,
      color: Colors.grey.shade100,
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
          return Container(color: isEven ? Colors.white : Colors.grey.shade200);
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                hintText: 'Cari alat',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                prefixIcon: SizedBox(width: 8),
                suffixIcon: Icon(Icons.search, color: Colors.black54),
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
                          ? const Color(0xFFD5CDF3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFD5CDF3)
                            : Colors.white54,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _filters[index],
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1E1548)
                            : Colors.white,
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
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
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
            itemBuilder: (context, index) {
              final alat = _filteredAlatList[index];
              final desc = alat.deskripsi.isNotEmpty
                  ? alat.deskripsi
                  : 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor';
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                      _buildCheckeredImageHeader(height: 120),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alat.nama,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  desc,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
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
                                            builder: (context) => AlertDialog(
                                              title: const Text('Hapus Alat'),
                                              content: Text(
                                                'Apakah Anda yakin ingin menghapus "${alat.nama}"?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(false),
                                                  child: const Text('Batal'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(true),
                                                  child: const Text(
                                                    'Hapus',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            setState(() => _isLoading = true);
                                            final res = await ApiService.delete(
                                              'api/alat/${alat.id}',
                                            );
                                            setState(() => _isLoading = false);
                                            if (res.status == 'success') {
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Alat berhasil dihapus',
                                                    ),
                                                  ),
                                                );
                                              }
                                              _fetchAlat();
                                            } else {
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(res.message),
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFFFDE8E8),
                                          ),
                                          backgroundColor: const Color(
                                            0xFFFDE8E8,
                                          ),
                                          foregroundColor: const Color(
                                            0xFFC53030,
                                          ),
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
                                                  AlatFormScreen(alat: alat),
                                            ),
                                          );
                                          _fetchAlat();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF1E1548,
                                          ),
                                          foregroundColor: Colors.white,
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
              );
            },
          );

    final fab = FloatingActionButton(
      onPressed: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AlatFormScreen()));
        _fetchAlat();
      },
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, size: 28),
    );

    if (widget.isTab) {
      return Scaffold(
        backgroundColor: AppColors.darkSurface,
        body: RefreshIndicator(
          onRefresh: _fetchAlat,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(children: [searchAndFilterHeader, gridContent]),
          ),
        ),
        floatingActionButton: fab,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        title: const Text('Katalog'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAlat,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(children: [searchAndFilterHeader, gridContent]),
        ),
      ),
      floatingActionButton: fab,
    );
  }
}
