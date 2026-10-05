class AppConfig {
  AppConfig._();

  /// Switch global : true = persistance Hive active, false = skeleton seul
  static const bool persistanceActive = true;

  /// Clés Hive
  static const String hiveBoxAnnonces      = 'annonces_cache';
  static const String hiveBoxConversations = 'conversations_cache';
  static const String hiveBoxProfil        = 'profil_cache';
  static const String hiveBoxRecherches    = 'recherches_cache';

  //Catégories
  static const String hiveBoxCategories = 'categories_cache';
  static const String keyCategories     = 'categories';

  /// Clés dans les boxes
  static const String keyAnnoncesHome  = 'home';
  static const String keyAnnoncesList  = 'list';
  static const String keyConversations = 'conversations';
  static const String keyProfil        = 'profil';
  static const String keyRecherches    = 'recherches';

  /// Durée de validité du cache (après ça, on force un refresh)
  static const Duration cacheDuration = Duration(hours: 1);
  static const String keyCacheTimestamp = 'cache_timestamp';
}