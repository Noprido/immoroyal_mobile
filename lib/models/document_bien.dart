class DocumentBienModel {
  final String id;
  final String bienId;
  final String nom;   // ex : "Contrat de bail"
  final String type;  // 'contrat' | 'etat_lieux' | 'autre'
  final String url;
  final DateTime uploadedAt;

  const DocumentBienModel({
    required this.id,
    required this.bienId,
    required this.nom,
    this.type = 'autre',
    required this.url,
    required this.uploadedAt,
  });

  factory DocumentBienModel.fromJson(Map<String, dynamic> json) => DocumentBienModel(
    id:         (json['id'] ?? '') as String,
    bienId:     (json['bienId'] ?? '') as String,
    nom:        (json['nom'] ?? '') as String,
    type:       (json['type'] ?? 'autre') as String,
    url:        (json['url'] ?? '') as String,
    uploadedAt: DateTime.tryParse((json['uploadedAt'] ?? '') as String) ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bienId': bienId,
    'nom': nom,
    'type': type,
    'url': url,
    'uploadedAt': uploadedAt.toIso8601String(),
  };
}
