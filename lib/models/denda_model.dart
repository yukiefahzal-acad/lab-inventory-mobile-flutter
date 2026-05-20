class Denda {
  final int? id;
  final int userId;
  final int peminjamanId;
  final double jumlah;
  final String status;

  Denda({
    this.id,
    required this.userId,
    required this.peminjamanId,
    required this.jumlah,
    required this.status,
  });

  factory Denda.fromJson(Map<String, dynamic> json) {
    return Denda(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      peminjamanId: json['peminjaman_id'] ?? 0,
      jumlah: (json['jumlah'] ?? 0).toDouble(),
      status: json['status'] ?? 'Belum Lunas',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'peminjaman_id': peminjamanId,
    'jumlah': jumlah,
    'status': status,
  };
}