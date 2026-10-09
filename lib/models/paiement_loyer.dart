class PaiementLoyerModel {
  final String id;
  final String bienId;
  final double montant;
  final String moisConcerne; // format "2026-08"
  final String statut;       // 'paye' | 'en_attente' | 'en_retard'
  final String? operateur;   // 'mtn' | 'moov' | 'celtiis'
  final String? transactionId;
  final DateTime? datePaiement;

  const PaiementLoyerModel({
    required this.id,
    required this.bienId,
    required this.montant,
    required this.moisConcerne,
    required this.statut,
    this.operateur,
    this.transactionId,
    this.datePaiement,
  });

  factory PaiementLoyerModel.fromJson(Map<String, dynamic> json) => PaiementLoyerModel(
    id:            (json['id'] ?? '') as String,
    bienId:        (json['bienId'] ?? '') as String,
    montant:       ((json['montant'] ?? 0) as num).toDouble(),
    moisConcerne:  (json['moisConcerne'] ?? '') as String,
    statut:        (json['statut'] ?? 'en_attente') as String,
    operateur:     json['operateur'] as String?,
    transactionId: json['transactionId'] as String?,
    datePaiement:  json['datePaiement'] != null
        ? DateTime.tryParse(json['datePaiement'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bienId': bienId,
    'montant': montant,
    'moisConcerne': moisConcerne,
    'statut': statut,
    'operateur': operateur,
    'transactionId': transactionId,
    'datePaiement': datePaiement?.toIso8601String(),
  };

  bool get estPaye      => statut == 'paye';
  bool get estEnAttente => statut == 'en_attente';
  bool get estEnRetard  => statut == 'en_retard';
}
