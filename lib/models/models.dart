// class User {
//   final int? id;
//   final String username;
//   final String role;
//
//   User({this.id, required this.username, required this.role});
//
//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       id: json['id'],
//       username: json['username'] ?? '',
//       role: json['role'] ?? 'user',
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'username': username,
//     'role': role,
//   };
// }
//
// class Alat {
//   final int? id;
//   final String nama;
//   final String deskripsi;
//   final String statusAwal;
//   final String? qrCode;
//   final String? fotoUrl;
//
//   Alat({
//     this.id,
//     required this.nama,
//     required this.deskripsi,
//     required this.statusAwal,
//     this.qrCode,
//     this.fotoUrl,
//   });
//
//   factory Alat.fromJson(Map<String, dynamic> json) {
//     return Alat(
//       id: json['id'],
//       nama: json['nama'] ?? '',
//       deskripsi: json['deskripsi'] ?? '',
//       statusAwal: json['status_awal'] ?? '',
//       qrCode: json['qr_code'],
//       fotoUrl: json['foto_url'],
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'nama': nama,
//     'deskripsi': deskripsi,
//     'status_awal': statusAwal,
//     'qr_code': qrCode,
//     'foto_url': fotoUrl,
//   };
// }
//
// class Peminjaman {
//   final int? id;
//   final int userId;
//   final int alatId;
//   final String tanggalPinjam;
//   final String tanggalKembali;
//   final String status;
//
//   Peminjaman({
//     this.id,
//     required this.userId,
//     required this.alatId,
//     required this.tanggalPinjam,
//     required this.tanggalKembali,
//     required this.status,
//   });
//
//   factory Peminjaman.fromJson(Map<String, dynamic> json) {
//     return Peminjaman(
//       id: json['id'],
//       userId: json['user_id'] ?? 0,
//       alatId: json['alat_id'] ?? 0,
//       tanggalPinjam: json['tanggal_pinjam'] ?? '',
//       tanggalKembali: json['tanggal_kembali'] ?? '',
//       status: json['status'] ?? 'pending',
//     );
//   }
// }
//
// class Denda {
//   final int? id;
//   final int userId;
//   final int peminjamanId;
//   final double jumlah;
//   final String status;
//
//   Denda({
//     this.id,
//     required this.userId,
//     required this.peminjamanId,
//     required this.jumlah,
//     required this.status,
//   });
//
//   factory Denda.fromJson(Map<String, dynamic> json) {
//     return Denda(
//       id: json['id'],
//       userId: json['user_id'] ?? 0,
//       peminjamanId: json['peminjaman_id'] ?? 0,
//       jumlah: (json['jumlah'] ?? 0).toDouble(),
//       status: json['status'] ?? 'unpaid',
//     );
//   }
// }
