class AnnonceModel {
  final String id;
  final String titre;
  final String? description;
  final String typeBien;
  final String? typeTransaction;
  final String ville;
  final String quartier;
  final num prix;
  final num loyer;
  final String? dureeLocation;
  final num moisAvance;
  final num cautionEau;
  final num cautionElec;
  final num commissionDemarcheur;
  final String? standing;   // 'sanitaire' | 'semi-sanitaire' | 'ordinaire' | null
  final double? dimension;  // en m², pour les terrains uniquement
  final int nbPieces;
  final int nbChambres;
  final int nbSalons;
  final int nbDouches;
  final int nbCuisines;
  final String? electriciteType;
  final String? electriciteCompteur;
  final String? eauType;
  final List<String> photos;
  final List<String> videos;
  final String auteurId;
  final String auteurNom;
  final String auteurTelephone;
  final bool enAvant;
  final bool actif;
  final bool suspendu;
  final DateTime? suspenduLe;
  final String? createdAt;
  final String? updatedAt;

  const AnnonceModel({
    required this.id,
    required this.titre,
    this.description,
    required this.typeBien,
    this.typeTransaction,
    required this.ville,
    required this.quartier,
    this.prix = 0,
    this.loyer = 0,
    this.dureeLocation,
    this.moisAvance = 0,
    this.cautionEau = 0,
    this.cautionElec = 0,
    this.commissionDemarcheur = 0,
    this.standing ,
    this.dimension,
    this.nbPieces = 0,
    this.nbChambres = 0,
    this.nbSalons = 0,
    this.nbDouches = 0,
    this.nbCuisines = 0,
    this.electriciteType,
    this.electriciteCompteur,
    this.eauType,
    this.photos = const [],
    this.videos = const [],
    required this.auteurId,
    required this.auteurNom,
    required this.auteurTelephone,
    this.enAvant = false,
    this.actif = true,
    this.suspendu = false,
    this.suspenduLe,
    this.createdAt,
    this.updatedAt,
  });


  factory AnnonceModel.fromJson(Map<String, dynamic> json) {

    return AnnonceModel(
      id: json['id'] ?? '',
      titre: json['titre'] ?? '',
      description: json['description'],

      typeBien: json['typeBien'] ?? '',
      typeTransaction: json['typeTransaction'],

      ville: json['ville'] ?? '',
      quartier: json['quartier'] ?? '',

      prix: json['prix'] ?? 0,
      loyer: json['loyer'] ?? 0,

      dureeLocation: json['dureeLocation'],

      moisAvance: json['moisAvance'] ?? 0,
      cautionEau: json['cautionEau'] ?? 0,
      cautionElec: json['cautionElec'] ?? 0,
      commissionDemarcheur: json['commissionDemarcheur'] ?? 0,

      standing: json['standing'],
      dimension: json['dimension'] != null ? (json['dimension'] as num).toDouble() : null,
      nbPieces: json['nbPieces'] ?? 0,
      nbChambres: json['nbChambres'] ?? 0,
      nbSalons: json['nbSalons'] ?? 0,
      nbDouches: json['nbDouches'] ?? 0,
      nbCuisines: json['nbCuisines'] ?? 0,

      electriciteType: json['electriciteType'],
      electriciteCompteur: json['electriciteCompteur'],
      eauType: json['eauType'],

      photos: List<String>.from(json['photos'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),

      auteurId: json['auteurId'] ?? '',
      auteurNom: json['auteurNom'] ?? '',
      auteurTelephone: json['auteurTelephone'] ?? '',

      enAvant: json['enAvant'] ?? false,
      actif: json['actif'] ?? true,
      suspendu: json['suspendu'] ?? false,

      suspenduLe: json['suspenduLe'] != null
          ? DateTime.tryParse(json['suspenduLe'])
          : null,

      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }


  num get prixAffiche => prix > 0 ? prix : loyer;


String? get thumbnail {
  if (videos.isNotEmpty) {
    // Cherche la miniature générée par ffmpeg
    final thumb = photos.firstWhere(
      (p) => p.contains('thumb_'),
      orElse: () => photos.isNotEmpty ? photos.first : '',
    );
    return thumb.isEmpty ? videos.first : thumb;
  }
  if (photos.isNotEmpty) return photos.first;
  return null;
}


  bool get hasVideo => videos.isNotEmpty;


List<Map<String, String>> get mediasUnifies {
  final list = <Map<String, String>>[];

  for (final v in videos) {
    // Cherche le thumb correspondant
    final videoFilename = v.split('/').last.replaceAll(RegExp(r'\.[^.]+$'), '');
    final thumb = photos.firstWhere(
      (p) => p.contains('thumb_$videoFilename'),
      orElse: () => '',
    );
    list.add({
      'url': thumb.isNotEmpty ? thumb : v, // affiche le thumb si disponible
      'videoUrl': v,                        // garde l'URL de la vidéo pour la lecture
      'type': 'video',
    });
  }

  for (final p in photos) {
    if (p.contains('thumb_')) continue; // ignore les thumbs déjà utilisés
    list.add({'url': p, 'type': 'photo'});
  }

  return list;
}


  bool get isLocation => typeTransaction == 'location';

  bool get isTerrain => typeBien == 'Terrain';


  Map<String, dynamic> toJson() => {
    'id': id,
    'titre': titre,
    'description': description,

    'typeBien': typeBien,
    'typeTransaction': typeTransaction,

    'ville': ville,
    'quartier': quartier,

    'prix': prix,
    'loyer': loyer,

    'dureeLocation': dureeLocation,

    'moisAvance': moisAvance,
    'cautionEau': cautionEau,
    'cautionElec': cautionElec,
    'commissionDemarcheur': commissionDemarcheur,

    'standing': standing,           // ← ajouté
    'dimension': dimension, 
    'nbPieces': nbPieces,
    'nbChambres': nbChambres,
    'nbSalons': nbSalons,
    'nbDouches': nbDouches,
    'nbCuisines': nbCuisines,

    'electriciteType': electriciteType,
    'electriciteCompteur': electriciteCompteur,
    'eauType': eauType,

    'photos': photos,
    'videos': videos,

    'auteurId': auteurId,
    'auteurNom': auteurNom,
    'auteurTelephone': auteurTelephone,

    'enAvant': enAvant,
    'actif': actif,
    'suspendu': suspendu,

    'suspenduLe': suspenduLe?.toIso8601String(),

    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}