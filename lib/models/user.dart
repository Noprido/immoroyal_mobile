class UserModel {
  final String id;
  final String nom;
  final String? email;
  final String telephone;
  final String whatsapp;
  final String role;
  final bool banni;
  final bool suspendu;
  final String? bio;
  final String? typeVendeur;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.nom,
    this.email,
    required this.telephone,
    required this.whatsapp,
    this.role = 'user',
    this.banni = false,
    this.suspendu = false,
    this.bio,
    this.typeVendeur,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:          json['id'] as String,
    nom:         json['nom'] as String,
    email:       json['email'] as String?,
    telephone:   json['telephone'] as String,
    whatsapp:    (json['whatsapp'] as String?) ?? (json['telephone'] as String),
    role:        (json['role'] as String?) ?? 'user',
    banni:       (json['banni'] as bool?) ?? false,
    suspendu:    (json['suspendu'] as bool?) ?? false,
    bio:         json['bio'] as String?,
    typeVendeur: json['typeVendeur'] as String?,
    createdAt:   json['createdAt'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'email': email,
    'telephone': telephone,
    'whatsapp': whatsapp,
    'role': role,
    'banni': banni,
    'suspendu': suspendu,
    'bio': bio,
    'typeVendeur': typeVendeur,
    'createdAt': createdAt,
  };

  // Initiales pour avatar
  String get initiales {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return nom.isNotEmpty ? nom[0].toUpperCase() : '?';
  }

  bool get isAdmin => role == 'admin';
}
