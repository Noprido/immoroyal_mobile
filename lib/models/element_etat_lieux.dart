class ElementEtatLieuxModel {
  final String id;
  final String bienId;
  final String nom;        // ex : "Climatiseur salon"
  final String categorie;  // 'equipement' | 'structure' | 'autre'
  final String statut;     // 'bon_etat' | 'defectueux' | 'absent'
  final String? note;
  final List<String> photos; // URLs

  const ElementEtatLieuxModel({
    required this.id,
    required this.bienId,
    required this.nom,
    this.categorie = 'autre',
    this.statut = 'bon_etat',
    this.note,
    this.photos = const [],
  });

  factory ElementEtatLieuxModel.fromJson(Map<String, dynamic> json) => ElementEtatLieuxModel(
    id:        (json['id'] ?? '') as String,
    bienId:    (json['bienId'] ?? '') as String,
    nom:       (json['nom'] ?? '') as String,
    categorie: (json['categorie'] ?? 'autre') as String,
    statut:    (json['statut'] ?? 'bon_etat') as String,
    note:      json['note'] as String?,
    photos:    List<String>.from(json['photos'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bienId': bienId,
    'nom': nom,
    'categorie': categorie,
    'statut': statut,
    'note': note,
    'photos': photos,
  };

  bool get estBonEtat    => statut == 'bon_etat';
  bool get estDefectueux => statut == 'defectueux';
  bool get estAbsent     => statut == 'absent';
}
