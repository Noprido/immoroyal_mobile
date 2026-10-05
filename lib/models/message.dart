class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String texte;
  final String? date;
  final bool lu;
  final String type; // 'texte' | 'audio' | 'image' | 'fichier'
  final String? fichierUrl;
  final String? fichierNom;
  final int? dureeAudio; // secondes

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.texte,
    this.date,
    this.lu = false,
    this.type = 'texte',
    this.fichierUrl,
    this.fichierNom,
    this.dureeAudio,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id:             json['id'] as String,
    conversationId: json['conversationId'] as String,
    senderId:       json['senderId'] as String,
    texte:          (json['texte'] ?? '') as String,
    date:           json['date'] as String?,
    lu:             (json['lu'] ?? false) as bool,
    type:           (json['type'] ?? 'texte') as String,
    fichierUrl:     json['fichierUrl'] as String?,
    fichierNom:     json['fichierNom'] as String?,
    dureeAudio:     json['dureeAudio'] as int?,
  );

  bool get isTexte => type == 'texte';
  bool get isAudio => type == 'audio';
  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
}

class ConversationModel {
  final String id;
  final String annonceId;
  final String userId1;
  final String userId2;
  final String? dernierMessageTexte;
  final String? dernierMessageDate;
  final String? dernierMessageSenderId;
  final String? dateCreation;
  final String? annoncetitre;
  final String? autreUserNom;
  final int nonLus;

  const ConversationModel({
    required this.id,
    required this.annonceId,
    required this.userId1,
    required this.userId2,
    this.dernierMessageTexte,
    this.dernierMessageDate,
    this.dernierMessageSenderId,
    this.dateCreation,
    this.annoncetitre,
    this.autreUserNom,
    this.nonLus = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final dm = json['dernierMessage'] as Map<String, dynamic>? ?? {};
    return ConversationModel(
      id:                     json['id'] as String,
      annonceId:              json['annonceId'] as String,
      userId1:                json['userId1'] as String,
      userId2:                json['userId2'] as String,
      dernierMessageTexte:    dm['texte'] as String?,
      dernierMessageDate:     dm['date'] as String?,
      dernierMessageSenderId: dm['senderId'] as String?,
      dateCreation:           json['dateCreation'] as String?,
      annoncetitre:           json['annonceTitre'] as String?,
      autreUserNom:           json['autreUserNom'] as String?,
      nonLus:                 (json['nonLus'] ?? 0) as int,
    );
  }
}