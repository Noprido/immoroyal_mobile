import 'bail.dart';

class BienModel {
  final String id;
  final String groupeId;
  final String nom;              // ex : "Studio Meublé — Fidjrossè"
  final String adresse;
  final String ville;
  final String? quartier;
  final String typeBien;         // Studio, Appartement, Maison, Boutique...
  final String? proprietaireNom; // métadonnée libre, pas un rôle
  final String? locataireId;     // null si aucun locataire lié
  final String? locataireNom;
  final String? locataireTel;
  final BailModel? bail;
  final String statutLoyer;      // 'a_jour' | 'en_retard' | 'sans_locataire'
  final int? joursRetard;
  final DateTime createdAt;

  const BienModel({
    required this.id,
    required this.groupeId,
    required this.nom,
    required this.adresse,
    required this.ville,
    this.quartier,
    required this.typeBien,
    this.proprietaireNom,
    this.locataireId,
    this.locataireNom,
    this.locataireTel,
    this.bail,
    this.statutLoyer = 'sans_locataire',
    this.joursRetard,
    required this.createdAt,
  });

  factory BienModel.fromJson(Map<String, dynamic> json) => BienModel(
    id:              (json['id'] ?? '') as String,
    groupeId:        (json['groupeId'] ?? '') as String,
    nom:             (json['nom'] ?? '') as String,
    adresse:         (json['adresse'] ?? '') as String,
    ville:           (json['ville'] ?? '') as String,
    quartier:        json['quartier'] as String?,
    typeBien:        (json['typeBien'] ?? '') as String,
    proprietaireNom: json['proprietaireNom'] as String?,
    locataireId:     json['locataireId'] as String?,
    locataireNom:    json['locataireNom'] as String?,
    locataireTel:    json['locataireTel'] as String?,
    bail:            json['bail'] != null
        ? BailModel.fromJson(json['bail'] as Map<String, dynamic>)
        : null,
    statutLoyer:     (json['statutLoyer'] ?? 'sans_locataire') as String,
    joursRetard:     (json['joursRetard'] as num?)?.toInt(),
    createdAt:       DateTime.tryParse((json['createdAt'] ?? '') as String) ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'groupeId': groupeId,
    'nom': nom,
    'adresse': adresse,
    'ville': ville,
    'quartier': quartier,
    'typeBien': typeBien,
    'proprietaireNom': proprietaireNom,
    'locataireId': locataireId,
    'locataireNom': locataireNom,
    'locataireTel': locataireTel,
    'bail': bail?.toJson(),
    'statutLoyer': statutLoyer,
    'joursRetard': joursRetard,
    'createdAt': createdAt.toIso8601String(),
  };

  bool get aLocataire    => locataireId != null;
  bool get enRetard      => statutLoyer == 'en_retard';
  bool get aJour         => statutLoyer == 'a_jour';
  bool get sansLocataire => statutLoyer == 'sans_locataire';
  double get loyerMensuel => bail?.montantLoyer ?? 0;
}
