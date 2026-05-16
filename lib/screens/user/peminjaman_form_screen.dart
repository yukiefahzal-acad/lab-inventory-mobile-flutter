import 'package:flutter/material.dart';
import '../../core/api_service.dart';

class PeminjamanFormScreen extends StatefulWidget {
  final String? initialAlatId; // If navigated from QR
  const PeminjamanFormScreen({super.key, this.initialAlatId});

  @override
  State<PeminjamanFormScreen> createState() => _PeminjamanFormScreenState();
}

class _PeminjamanFormScreenState extends State<PeminjamanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _alatIdCtrl;
  final _tanggalPinjamCtrl = TextEditingController();
  final _tanggalKembaliCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _alatIdCtrl = TextEditingController(text: widget.initialAlatId ?? '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final res = await ApiService.post('api/peminjaman', {
      'alat_id': int.tryParse(_alatIdCtrl.text),
      'tanggal_pinjam': _tanggalPinjamCtrl.text,
      'tanggal_kembali': _tanggalKembaliCtrl.text,
    });

    setState(() => _isLoading = false);

    if (!mounted) return;
    if (res.status == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Peminjaman berhasil diajukan')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Peminjaman')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _alatIdCtrl,
                decoration: const InputDecoration(labelText: 'ID Alat (atau Scan QR)'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tanggalPinjamCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Pinjam',
                  hintText: 'MM/DD/YYYY',
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Wajib diisi';
                  if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(val)) return 'Format harus MM/DD/YYYY';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tanggalKembaliCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Kembali',
                  hintText: 'MM/DD/YYYY',
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Wajib diisi';
                  if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(val)) return 'Format harus MM/DD/YYYY';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text('Ajukan Peminjaman'),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
