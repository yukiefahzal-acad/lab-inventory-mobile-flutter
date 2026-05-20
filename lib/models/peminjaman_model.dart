class Peminjaman {
  final int? id;
  final int userId;
  final int alatId;
  final String tanggalPinjam;
  final String tanggalKembaliRencana;
  final String status;

  Peminjaman({
    this.id,
    required this.userId,
    required this.alatId,
    required this.tanggalPinjam,
    required this.tanggalKembaliRencana,
    required this.status,
  });

  factory Peminjaman.fromJson(Map<String, dynamic> json) {
    return Peminjaman(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      alatId: json['alat_id'] ?? 0,
      tanggalPinjam: json['tanggal_pinjam'] ?? '',
      tanggalKembaliRencana: json['tanggal_kembali_rencana'] ?? '',
      status: json['status'] ?? 'Menunggu',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'alat_id': alatId,
    'tanggal_pinjam': tanggalPinjam,
    'tanggal_kembali_rencana': tanggalKembaliRencana,
    'status': status,
  };
}