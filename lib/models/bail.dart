class BailModel {
  final String id;
  final String bienId;
  final double montantLoyer; // en FCFA
  final int jourEcheance;    // 1-31 : jour du mois
  final DateTime dateDebut;
  final DateTime? dateFin;   // null = bail indéterminé

  const BailModel({
    required this.id,
    required this.bienId,
    required this.montantLoyer,
    required this.jourEcheance,
    required this.dateDebut,
    this.dateFin,
  });

  factory BailModel.fromJson(Map<String, dynamic> json) => BailModel(
    id:           (json['id'] ?? '') as String,
    bienId:       (json['bienId'] ?? '') as String,
    montantLoyer: ((json['montantLoyer'] ?? 0) as num).toDouble(),
    jourEcheance: ((json['jourEcheance'] ?? 1) as num).toInt(),
    dateDebut:    DateTime.tryParse((json['dateDebut'] ?? '') as String) ?? DateTime.now(),
    dateFin:      json['dateFin'] != null ? DateTime.tryParse(json['dateFin'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bienId': bienId,
    'montantLoyer': montantLoyer,
    'jourEcheance': jourEcheance,
    'dateDebut': dateDebut.toIso8601String(),
    'dateFin': dateFin?.toIso8601String(),
  };

  bool get estIndetermine => dateFin == null;
}
