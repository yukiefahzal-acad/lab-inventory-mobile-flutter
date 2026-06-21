class User {
  final int? id;
  final String email;
  final String? nama;
  final String? nimNip;
  final String role;

  User({this.id, required this.email, this.nama, this.nimNip, required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? '',
      nama: json['nama'],
      nimNip: json['nim_nip'],
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'nama': nama,
    'nim_nip': nimNip,
    'role': role,
  };
}

class Alat {
  static final Map<int, Alat> cache = {};

  final int? id;
  final String kodeAlat;
  final String namaAlat;
  final String spesifikasi;
  final String? foto;
  final int stokTotal;
  final int stokTersedia;
  final String? qrCode;
  final String kategori;
  final int dendaPerHari;
  final int dendaRusak;
  final int dendaHilang;

  List<String> get fotoList => (foto ?? '').split('|').where((s) => s.isNotEmpty).toList();
  String? get firstFoto => fotoList.isNotEmpty ? fotoList.first : null;
  List<String> get kategoriList => kategori.split('|').where((s) => s.isNotEmpty).toList();

  Alat({
    this.id,
    required this.kodeAlat,
    required this.namaAlat,
    required this.spesifikasi,
    this.foto,
    required this.stokTotal,
    this.stokTersedia = 0,
    this.qrCode,
    required this.kategori,
    required this.dendaPerHari,
    required this.dendaRusak,
    required this.dendaHilang,
  });

  factory Alat.fromJson(Map<String, dynamic> json) {
    final instance = Alat(
      id: json['id'],
      kodeAlat: json['kode_alat']?.toString() ?? '',
      namaAlat: json['nama_alat']?.toString() ?? '',
      spesifikasi: json['spesifikasi']?.toString() ?? '',
      foto: json['foto']?.toString(),
      stokTotal: int.tryParse(json['stok_total']?.toString() ?? '') ?? 0,
      stokTersedia: int.tryParse(json['stok_tersedia']?.toString() ?? '') ?? 0,
      qrCode: json['qr_code']?.toString(),
      kategori: json['kategori']?.toString() ?? '',
      dendaPerHari: int.tryParse(json['denda_per_hari']?.toString() ?? '') ?? 0,
      dendaRusak: int.tryParse(json['denda_rusak']?.toString() ?? '') ?? 0,
      dendaHilang: int.tryParse(json['denda_hilang']?.toString() ?? '') ?? 0,
    );
    if (instance.id != null) {
      cache[instance.id!] = instance;
    }
    return instance;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kode_alat': kodeAlat,
    'nama_alat': namaAlat,
    'spesifikasi': spesifikasi,
    'foto': foto,
    'stok_total': stokTotal,
    'stok_tersedia': stokTersedia,
    'qr_code': qrCode,
    'kategori': kategori,
    'denda_per_hari': dendaPerHari,
    'denda_rusak': dendaRusak,
    'denda_hilang': dendaHilang,
  };
}

class Peminjaman {
  final int? id;
  final int userId;
  final int alatId;
  final String tanggalPinjam;
  final String tanggalKembali;
  final String? tanggalKembaliAktual;
  final String status;
  final int jumlah;
  final int? jumlahKembali;
  final String? namaAlat;
  final String? namaMahasiswa;
  final String? catatanPinjaman;
  final String? catatanPengembalian;

  Peminjaman({
    this.id,
    required this.userId,
    required this.alatId,
    required this.tanggalPinjam,
    required this.tanggalKembali,
    this.tanggalKembaliAktual,
    required this.status,
    required this.jumlah,
    this.jumlahKembali,
    this.namaAlat,
    this.namaMahasiswa,
    this.catatanPinjaman,
    this.catatanPengembalian,
  });

  factory Peminjaman.fromJson(Map<String, dynamic> json) {
    return Peminjaman(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      alatId: json['alat_id'] ?? 0,
      tanggalPinjam: json['tanggal_pinjam'] ?? '',
      tanggalKembali: json['tanggal_kembali'] ?? json['tanggal_kembali_rencana'] ?? '',
      tanggalKembaliAktual: json['tanggal_kembali_aktual'],
      status: json['status'] ?? 'pending',
      jumlah: json['jumlah'] ?? 1,
      jumlahKembali: json['jumlah_kembali'],
      namaAlat: json['nama_alat'],
      namaMahasiswa: json['nama_mahasiswa'],
      catatanPinjaman: json['catatan_pinjaman'],
      catatanPengembalian: json['catatan_pengembalian'],
    );
  }
}

class Denda {
  final int? id;
  final int userId;
  final int peminjamanId;
  final double jumlah;
  final String status;
  final String? jenisDenda;
  final String? namaAlat;
  final String? statusBayar;
  final String? keterangan;
  final String? namaMahasiswa;

  Denda({
    this.id,
    required this.userId,
    required this.peminjamanId,
    required this.jumlah,
    required this.status,
    this.jenisDenda,
    this.namaAlat,
    this.statusBayar,
    this.keterangan,
    this.namaMahasiswa,
  });

  factory Denda.fromJson(Map<String, dynamic> json) {
    String statusVal = 'unpaid';
    final rawStatusBayar = json['status_bayar']?.toString();
    if (rawStatusBayar != null) {
      statusVal = rawStatusBayar.toLowerCase() == 'lunas' ? 'paid' : 'unpaid';
    } else if (json['status'] != null) {
      statusVal = json['status'].toString();
    }

    double jumlahVal = 0.0;
    if (json['jumlah_denda'] != null) {
      jumlahVal = double.tryParse(json['jumlah_denda'].toString()) ?? 0.0;
    } else if (json['jumlah'] != null) {
      jumlahVal = (json['jumlah'] ?? 0).toDouble();
    }

    return Denda(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      peminjamanId: int.tryParse((json['peminjaman_id'] ?? 0).toString()) ?? 0,
      jumlah: jumlahVal,
      status: statusVal,
      jenisDenda: json['jenis_denda']?.toString(),
      namaAlat: json['nama_alat']?.toString(),
      statusBayar: rawStatusBayar,
      keterangan: json['keterangan']?.toString(),
      namaMahasiswa: json['nama_mahasiswa']?.toString(),
    );
  }
}
