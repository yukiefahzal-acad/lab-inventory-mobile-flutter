class User {
  final int? id;
  final String nimNip;
  final String nama;
  final String role;

  User({
    this.id,
    required this.nimNip,
    required this.nama,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nimNip: json['nim_nip'] ?? '',
      nama: json['nama'] ?? '',
      role: json['role'] ?? 'Mahasiswa',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nim_nip': nimNip,
    'nama': nama,
    'role': role,
  };
}