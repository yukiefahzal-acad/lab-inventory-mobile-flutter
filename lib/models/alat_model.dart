class Alat {
  final int? id;
  final String kodeAlat;
  final String namaAlat;
  final int stokTotal;
  final String spesifikasi;
  final String? foto;

  Alat({
    this.id,
    required this.kodeAlat,
    required this.namaAlat,
    required this.stokTotal,
    required this.spesifikasi,
    this.foto,
  });

  factory Alat.fromJson(Map<String, dynamic> json) {
    return Alat(
      id: json['id'],
      kodeAlat: json['kode_alat'] ?? '',
      namaAlat: json['nama_alat'] ?? '',
      stokTotal: json['stok_total'] ?? 0,
      spesifikasi: json['spesifikasi'] ?? '',
      foto: json['foto'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kode_alat': kodeAlat,
    'nama_alat': namaAlat,
    'stok_total': stokTotal,
    'spesifikasi': spesifikasi,
    'foto': foto,
  };
}