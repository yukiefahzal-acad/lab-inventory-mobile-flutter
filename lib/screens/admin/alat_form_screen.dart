import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api_service.dart';
import '../../core/app_colors.dart';
import '../../models/models.dart';

class AlatFormScreen extends StatefulWidget {
  final Alat? alat;
  const AlatFormScreen({super.key, this.alat});

  @override
  State<AlatFormScreen> createState() => _AlatFormScreenState();
}

class _AlatFormScreenState extends State<AlatFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _deskripsiCtrl;
  late final TextEditingController _statusAwalCtrl;

  // New fields matching the mockup:
  late final TextEditingController _stokCtrl;
  late final TextEditingController _dendaPerHariCtrl;
  late final TextEditingController _dendaRusakCtrl;
  late final TextEditingController _dendaHilangCtrl;

  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final a = widget.alat;
    _namaCtrl = TextEditingController(text: a?.nama ?? '');
    _deskripsiCtrl = TextEditingController(text: a?.deskripsi ?? '');
    _statusAwalCtrl = TextEditingController(
      text: a?.statusAwal ?? 'Indikasi Aman Pengiriman',
    );

    // Fallbacks or actual values if loaded
    _stokCtrl = TextEditingController(text: a != null ? '20' : '20');
    _dendaPerHariCtrl = TextEditingController(
      text: a != null ? 'Rp 10.000' : 'Rp 10.000',
    );
    _dendaRusakCtrl = TextEditingController(
      text: a != null ? 'Rp 100.000' : 'Rp 100.000',
    );
    _dendaHilangCtrl = TextEditingController(
      text: a != null ? 'Rp 500.000' : 'Rp 500.000',
    );
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _deskripsiCtrl.dispose();
    _statusAwalCtrl.dispose();
    _stokCtrl.dispose();
    _dendaPerHariCtrl.dispose();
    _dendaRusakCtrl.dispose();
    _dendaHilangCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final payload = {
      'nama': _namaCtrl.text,
      'deskripsi': _deskripsiCtrl.text,
      'status_awal': _statusAwalCtrl.text,
      'foto_url': _imageFile != null
          ? 'uploaded_dummy_url'
          : widget.alat?.fotoUrl,
    };

    final ApiResponse<dynamic> res;
    if (widget.alat != null) {
      res = await ApiService.put('api/alat/${widget.alat!.id}', payload);
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

  Widget _buildImageUploadSlot({bool isActive = false}) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondaryLight,
            style: BorderStyle.solid, // Dash approximation
            width: 1.5,
          ),
        ),
        child: Center(
          child: CircleAvatar(
            radius: 20,
            backgroundColor: isActive
                ? AppColors.secondary
                : AppColors.secondaryLight,
            child: const Icon(Icons.add, color: AppColors.white, size: 20),
          ),
        ),
      ),
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
        padding: const EdgeInsets.all(16.0),
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
                children: [
                  _buildImageUploadSlot(isActive: true),
                  _buildImageUploadSlot(),
                  _buildImageUploadSlot(),
                  _buildImageUploadSlot(),
                  _buildImageUploadSlot(),
                  _buildImageUploadSlot(),
                ],
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

              _buildFieldLabel('Jenis Alat'),
              // Dropdown mock matching mockup category pills inside a dropdown container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondaryLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Kategori 1',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Kategori 2',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.black54,
                    ),
                  ],
                ),
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
                decoration: _buildInputDecoration(
                  hintText: 'Rp 10.000',
                  prefixIcon: Icons.credit_card_outlined,
                ),
              ),

              _buildFieldLabel('Denda Rusak'),
              TextFormField(
                controller: _dendaRusakCtrl,
                style: const TextStyle(color: AppColors.black),
                decoration: _buildInputDecoration(
                  hintText: 'Rp 100.000',
                  prefixIcon: Icons.credit_card_outlined,
                ),
              ),

              _buildFieldLabel('Denda Hilang'),
              TextFormField(
                controller: _dendaHilangCtrl,
                style: const TextStyle(color: AppColors.black),
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
