class ApiConstants {
  ApiConstants._();

  // Changer selon l'environnement
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://immoroyal.onrender.com/api/v1',
    // defaultValue: 'http://10.148.39.161:3000/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout    = Duration(seconds: 60); 

  // Endpoints Auth
  static const String login    = '/auth/login';
  static const String register = '/auth/register';
  static const String me       = '/auth/me';

  // Endpoints Annonces
  static const String annonces = '/annonces';

  // Endpoints Catégories
  static const String categories = '/categories';

  // Endpoints Suggestions
  static const String suggestionsBenin = '/suggestions/benin';

  // Endpoints Recherches
  static const String recherches = '/recherches';

  // Endpoints Profil
  static const String profilePublic    = '/profile/public';
  static const String profileModifier  = '/profile/modifier';
  static const String profileAnnonces  = '/profile/annonces';
  static const String profileRecherches= '/profile/recherches';

  // Endpoints Messages
  static const String messages         = '/messages';
  static const String conversation     = '/messages/conversation';

  // Storage keys
  static const String jwtKey      = 'immoroyal_jwt';
  static const String userKey     = 'immoroyal_user';

  // Médias
  static const int maxMedias  = 10;
  static const int maxVideos  = 3;
  static const int maxVideoMb = 50;
}
