class RechercheModel {
  final String id;
  final String titre;
  final String? description;
  final String typeBien;
  final String? autreTypeBien;
  final String typeTransaction;
  final bool localisationImporte;
  final String? ville;
  final String? quartier;
  final num budgetMax;
  final String? dureeLocation;
  final int nbChambres;
  final int nbSalons;
  final int nbDouches;
  final int nbCuisines;
  final bool fondsDisponibles;
  final String auteurId;
  final String auteurNom;
  final String auteurTelephone;
  final String auteurWhatsapp;
  final bool actif;
  final String? createdAt;
  final String? updatedAt;

  const RechercheModel({
    required this.id,
    required this.titre,
    this.description,
    required this.typeBien,
    this.autreTypeBien,
    required this.typeTransaction,
    this.localisationImporte = false,
    this.ville,
    this.quartier,
    this.budgetMax = 0,
    this.dureeLocation,
    this.nbChambres = 0,
    this.nbSalons = 0,
    this.nbDouches = 0,
    this.nbCuisines = 0,
    this.fondsDisponibles = false,
    required this.auteurId,
    required this.auteurNom,
    required this.auteurTelephone,
    required this.auteurWhatsapp,
    this.actif = true,
    this.createdAt,
    this.updatedAt,
  });

  factory RechercheModel.fromJson(Map<String, dynamic> json) {
    final loc = json['localisation'] as Map<String, dynamic>? ?? {};
    return RechercheModel(
      id:                  json['id'] as String,
      titre:               json['titre'] as String,
      description:         json['description'] as String?,
      typeBien:            json['typeBien'] as String,
      autreTypeBien:       json['autreTypeBien'] as String?,
      typeTransaction:     json['typeTransaction'] as String,
      localisationImporte: (loc['importe'] ?? false) as bool,
      ville:               loc['ville'] as String?,
      quartier:            loc['quartier'] as String?,
      budgetMax:           (json['budgetMax'] ?? 0) as num,
      dureeLocation:       json['dureeLocation'] as String?,
      nbChambres:          (json['nbChambres'] ?? 0) as int,
      nbSalons:            (json['nbSalons'] ?? 0) as int,
      nbDouches:           (json['nbDouches'] ?? 0) as int,
      nbCuisines:          (json['nbCuisines'] ?? 0) as int,
      fondsDisponibles:    (json['fondsDisponibles'] ?? false) as bool,
      auteurId:            json['auteurId'] as String,
      auteurNom:           json['auteurNom'] as String,
      auteurTelephone:     json['auteurTelephone'] as String,
      auteurWhatsapp:      (json['auteurWhatsapp'] as String?) ?? (json['auteurTelephone'] as String),
      actif:               (json['actif'] ?? true) as bool,
      createdAt:           json['createdAt'] as String?,
      updatedAt:           json['updatedAt'] as String?,
    );
  }

  String get typeBienAffiche =>
      typeBien == 'Autre' && autreTypeBien != null ? autreTypeBien! : typeBien;
}
