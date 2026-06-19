import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api_service.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';

class ImageSlot {
  final String? imageUrl;
  final XFile? pickedFile;
  final Uint8List? pickedBytes;

  ImageSlot({this.imageUrl, this.pickedFile, this.pickedBytes});
}

class AlatFormScreen extends StatefulWidget {
  final Alat? alat;
  final List<String> availableCategories;
  const AlatFormScreen({super.key, this.alat, this.availableCategories = const []});

  @override
  State<AlatFormScreen> createState() => _AlatFormScreenState();
}

class _AlatFormScreenState extends State<AlatFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kodeAlatCtrl;
  late final TextEditingController _namaCtrl;
  late final TextEditingController _deskripsiCtrl;
  late final TextEditingController _newKategoriCtrl;

  List<String> _availableCategories = [];
  List<String> _selectedCategories = [];

  late final TextEditingController _stokCtrl;
  late final TextEditingController _dendaPerHariCtrl;
  late final TextEditingController _dendaRusakCtrl;
  late final TextEditingController _dendaHilangCtrl;

  bool _isLoading = false;
  final List<ImageSlot> _imageSlots = List.generate(6, (_) => ImageSlot());
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final a = widget.alat;
    _kodeAlatCtrl = TextEditingController(text: a?.kodeAlat ?? '');
    _namaCtrl = TextEditingController(text: a?.namaAlat ?? '');
    _deskripsiCtrl = TextEditingController(text: a?.spesifikasi ?? '');
    _newKategoriCtrl = TextEditingController();
    _selectedCategories = (a?.kategoriList ?? []).map(_capitalizeFirstLetter).toList();
    _availableCategories = widget.availableCategories.map(_capitalizeFirstLetter).toList();

    final fotoList = a?.fotoList ?? [];
    for (int i = 0; i < 6; i++) {
      if (i < fotoList.length) {
        _imageSlots[i] = ImageSlot(imageUrl: fotoList[i]);
      } else {
        _imageSlots[i] = ImageSlot();
      }
    }

    _stokCtrl = TextEditingController(text: a != null ? a.stokTotal.toString() : '20');
    _dendaPerHariCtrl = TextEditingController(
      text: a != null ? _formatCurrency(a.dendaPerHari) : '10.000',
    );
    _dendaRusakCtrl = TextEditingController(
      text: a != null ? _formatCurrency(a.dendaRusak) : '100.000',
    );
    _dendaHilangCtrl = TextEditingController(
      text: a != null ? _formatCurrency(a.dendaHilang) : '500.000',
    );
  }

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }



  @override
  void dispose() {
    _kodeAlatCtrl.dispose();
    _namaCtrl.dispose();
    _deskripsiCtrl.dispose();
    _newKategoriCtrl.dispose();
    _stokCtrl.dispose();
    _dendaPerHariCtrl.dispose();
    _dendaRusakCtrl.dispose();
    _dendaHilangCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImageForSlot(int index) async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageSlots[index] = ImageSlot(
          pickedFile: pickedFile,
          pickedBytes: bytes,
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategories.isEmpty) return;
    setState(() => _isLoading = true);

    // Upload newly picked images and collect all URLs in order
    List<String> finalUrls = [];
    for (int i = 0; i < 6; i++) {
      final slot = _imageSlots[i];
      if (slot.imageUrl != null && slot.imageUrl!.isNotEmpty) {
        finalUrls.add(slot.imageUrl!);
      } else if (slot.pickedFile != null && slot.pickedBytes != null) {
        final uploadRes = await ApiService.uploadFile(
          'api/upload',
          slot.pickedBytes!,
          slot.pickedFile!.name,
        );
        if (uploadRes.data != null && uploadRes.data is Map) {
          final fileUrl = uploadRes.data['file_url'] as String?;
          if (fileUrl != null) {
            finalUrls.add(fileUrl);
          }
        } else {
          setState(() => _isLoading = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal upload gambar ke-${i + 1}: ${uploadRes.message}')),
          );
          return;
        }
      }
    }
    final String fotoValue = finalUrls.join('|');

    final Map<String, dynamic> payload = {
      'kode_alat': _kodeAlatCtrl.text,
      'nama_alat': _namaCtrl.text,
      'spesifikasi': _deskripsiCtrl.text,
      'foto': fotoValue,
      'stok_total': int.tryParse(_stokCtrl.text) ?? 0,
      'kategori': _selectedCategories.map((c) => c.toLowerCase()).join('|'),
      'denda_per_hari': int.tryParse(_dendaPerHariCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      'denda_rusak': int.tryParse(_dendaRusakCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      'denda_hilang': int.tryParse(_dendaHilangCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
    };

    final ApiResponse<dynamic> res;
    if (widget.alat != null) {
      payload['id'] = widget.alat!.id;
      res = await ApiService.put('api/alat', payload);
    } else {
      res = await ApiService.post('api/alat', payload);
    }

    setState(() => _isLoading = false);

    if (!mounted) return;
    if (res.status == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.alat != null
                ? 'Alat berhasil diperbarui'
                : 'Alat berhasil ditambahkan',
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  Widget _buildImageUploadSlot({required int index, required ImageSlot slot}) {
    Widget content;
    bool hasImage = false;

    if (slot.pickedBytes != null) {
      hasImage = true;
      content = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(slot.pickedBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      );
    } else if (slot.imageUrl != null && slot.imageUrl!.isNotEmpty) {
      hasImage = true;
      content = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          slot.imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: AppColors.grey),
        ),
      );
    } else {
      // Find if this is the first empty slot to highlight it
      final firstEmptyIndex = _imageSlots.indexWhere((s) => s.imageUrl == null && s.pickedFile == null);
      final isNextToFill = index == firstEmptyIndex;
      content = Center(
        child: CircleAvatar(
          radius: 20,
          backgroundColor: isNextToFill
              ? AppColors.secondary
              : AppColors.secondaryLight,
          child: const Icon(Icons.add, color: AppColors.white, size: 20),
        ),
      );
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _pickImageForSlot(index),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.secondaryLight,
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: content,
          ),
        ),
        if (hasImage)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _imageSlots[index] = ImageSlot();
                });
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.black87,
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.authBgTop)
          : null,
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.black54, fontSize: 14),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.secondaryLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.secondaryLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.secondary, width: 2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.alat != null;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(isEditing ? 'Ubah Data Alat' : 'Input Data Alat'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 16.0 + MediaQuery.of(context).padding.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grid of 6 image upload slots (approximating mockup grid)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: List.generate(6, (index) {
                  return _buildImageUploadSlot(
                    index: index,
                    slot: _imageSlots[index],
                  );
                }),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Upload Gambar Alat (Hingga 6 gambar, maksimum 5MB per gambar)',
                  style: TextStyle(color: AppColors.grey, fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.black12, thickness: 1),
              const SizedBox(height: 8),

              // Identifikasi Alat
              const Text(
                'Identifikasi Alat',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 4),

              _buildFieldLabel('Kode Alat'),
              TextFormField(
                controller: _kodeAlatCtrl,
                style: const TextStyle(color: AppColors.black),
                decoration: _buildInputDecoration(
                  hintText: 'Kode Alat',
                  prefixIcon: Icons.qr_code_outlined,
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),

              _buildFieldLabel('Judul Alat'),
              TextFormField(
                controller: _namaCtrl,
                style: const TextStyle(color: AppColors.black),
                decoration: _buildInputDecoration(
                  hintText: 'Judul Alat',
                  prefixIcon: Icons.inventory_2_outlined,
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),

              _buildFieldLabel('Kategori Alat'),
              if (_availableCategories.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableCategories.map((cat) {
                    final isSelected = _selectedCategories.contains(cat);
                    return FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppColors.secondaryLight,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            if (!_selectedCategories.contains(cat)) _selectedCategories.add(cat);
                          } else {
                            _selectedCategories.remove(cat);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              if (_availableCategories.isNotEmpty) const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _newKategoriCtrl,
                      style: const TextStyle(color: AppColors.black),
                      decoration: _buildInputDecoration(
                        hintText: 'Tambah Kategori Baru',
                        prefixIcon: Icons.add,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final newCat = _newKategoriCtrl.text.trim();
                      if (newCat.isNotEmpty) {
                        final formattedCat = _capitalizeFirstLetter(newCat);
                        setState(() {
                          if (!_availableCategories.contains(formattedCat)) {
                            _availableCategories.add(formattedCat);
                          }
                          if (!_selectedCategories.contains(formattedCat)) {
                            _selectedCategories.add(formattedCat);
                          }
                          _newKategoriCtrl.clear();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (_selectedCategories.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('Wajib memilih minimal satu kategori', style: TextStyle(color: AppColors.error, fontSize: 12)),
                ),

              _buildFieldLabel('Stok'),
              TextFormField(
                controller: _stokCtrl,
                style: const TextStyle(color: AppColors.black),
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration(hintText: '20'),
              ),

              _buildFieldLabel('Denda Per Hari'),
              TextFormField(
                controller: _dendaPerHariCtrl,
                style: const TextStyle(color: AppColors.black),
                keyboardType: TextInputType.number,
                inputFormatters: [_CurrencyInputFormatter()],
                decoration: _buildInputDecoration(
                  hintText: 'Rp 10.000',
                  prefixIcon: Icons.credit_card_outlined,
                ),
              ),

              _buildFieldLabel('Denda Rusak'),
              TextFormField(
                controller: _dendaRusakCtrl,
                style: const TextStyle(color: AppColors.black),
                keyboardType: TextInputType.number,
                inputFormatters: [_CurrencyInputFormatter()],
                decoration: _buildInputDecoration(
                  hintText: 'Rp 100.000',
                  prefixIcon: Icons.credit_card_outlined,
                ),
              ),

              _buildFieldLabel('Denda Hilang'),
              TextFormField(
                controller: _dendaHilangCtrl,
                style: const TextStyle(color: AppColors.black),
                keyboardType: TextInputType.number,
                inputFormatters: [_CurrencyInputFormatter()],
                decoration: _buildInputDecoration(
                  hintText: 'Rp 500.000',
                  prefixIcon: Icons.credit_card_outlined,
                ),
              ),

              _buildFieldLabel('Deskripsi'),
              TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 4,
                style: const TextStyle(color: AppColors.black),
                decoration: _buildInputDecoration(
                  hintText: 'Deskripsi singkat alat',
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),

              const SizedBox(height: 24),

              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryDark,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isEditing ? Icons.save : Icons.add_box,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEditing ? 'Simpan Perubahan' : 'Tambah',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final intValue = int.tryParse(newValue.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final str = intValue.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    final newText = buffer.toString();
    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}
