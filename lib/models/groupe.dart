class GroupeModel {
  final String id;
  final String nom;
  final String? description;
  final String gerantId;
  final List<String> biensIds;
  final DateTime createdAt;

  const GroupeModel({
    required this.id,
    required this.nom,
    this.description,
    required this.gerantId,
    this.biensIds = const [],
    required this.createdAt,
  });

  factory GroupeModel.fromJson(Map<String, dynamic> json) => GroupeModel(
    id:          (json['id'] ?? '') as String,
    nom:         (json['nom'] ?? '') as String,
    description: json['description'] as String?,
    gerantId:    (json['gerantId'] ?? '') as String,
    biensIds:    List<String>.from(json['biensIds'] ?? []),
    createdAt:   DateTime.tryParse((json['createdAt'] ?? '') as String) ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'description': description,
    'gerantId': gerantId,
    'biensIds': biensIds,
    'createdAt': createdAt.toIso8601String(),
  };

  int get nbBiens => biensIds.length;
}
