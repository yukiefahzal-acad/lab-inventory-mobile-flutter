import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/models.dart';
import 'alat_form_screen.dart';

class AlatListScreen extends StatefulWidget {
  const AlatListScreen({super.key});

  @override
  State<AlatListScreen> createState() => _AlatListScreenState();
}

class _AlatListScreenState extends State<AlatListScreen> {
  List<Alat> _alatList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlat();
  }

  Future<void> _fetchAlat() async {
    setState(() => _isLoading = true);
    final res = await ApiService.get('api/alat');
    if (res.status == 'success' && res.data != null) {
      final List<dynamic> data = res.data;
      setState(() {
        _alatList = data.map((e) => Alat.fromJson(e)).toList();
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Katalog Alat')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _alatList.length,
              itemBuilder: (context, index) {
                final alat = _alatList[index];
                return ListTile(
                  leading: const Icon(Icons.handyman),
                  title: Text(alat.nama),
                  subtitle: Text(alat.statusAwal),
                  trailing: const Icon(Icons.chevron_right),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlatFormScreen()));
          _fetchAlat(); // Refresh after returning
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
