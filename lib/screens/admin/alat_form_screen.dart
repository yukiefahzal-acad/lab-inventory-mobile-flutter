import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api_service.dart';

class AlatFormScreen extends StatefulWidget {
  const AlatFormScreen({super.key});

  @override
  State<AlatFormScreen> createState() => _AlatFormScreenState();
}

class _AlatFormScreenState extends State<AlatFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _statusAwalCtrl = TextEditingController(text: 'Indikasi Aman Pengiriman');
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    // Note: Standard visual requirement is neutral 5500K lighting studio.
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

    // Using normal post since multipart is not fully specified in PRD,
    // assuming backend handles base64 or separate upload.
    final res = await ApiService.post('api/alat', {
      'nama': _namaCtrl.text,
      'deskripsi': _deskripsiCtrl.text,
      'status_awal': _statusAwalCtrl.text,
      'foto_url': _imageFile != null ? 'uploaded_dummy_url' : null, // Placeholder for photo
    });

    setState(() => _isLoading = false);

    if (!mounted) return;
    if (res.status == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alat berhasil ditambahkan')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Data Alat Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama Alat'),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiCtrl,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _statusAwalCtrl,
                decoration: const InputDecoration(labelText: 'Status Awal (Wajib)'),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(_imageFile == null 
                        ? 'Tidak ada foto (Gunakan studio 5500K)' 
                        : 'Foto siap diunggah'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Ambil Foto'),
                  )
                ],
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text('Simpan Data Alat'),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
