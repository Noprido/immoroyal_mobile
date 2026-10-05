import 'dart:convert';
import 'package:hive/hive.dart';
import '../constants/app_config.dart';

class CacheService {
  CacheService._();

  /// Sauvegarde une liste JSON dans une box Hive
  static Future<void> save(String boxName, String key, List<Map<String, dynamic>> data) async {
    if (!AppConfig.persistanceActive) return;
    final box = Hive.box(boxName);
    await box.put(key, jsonEncode(data));
    await box.put('${key}_${AppConfig.keyCacheTimestamp}', DateTime.now().toIso8601String());
  }

  /// Lit une liste JSON depuis une box Hive
  static List<Map<String, dynamic>>? read(String boxName, String key) {
    if (!AppConfig.persistanceActive) return null;
    final box = Hive.box(boxName);
    final raw = box.get(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw as String) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Vérifie si le cache est encore valide
  static bool isValid(String boxName, String key) {
    if (!AppConfig.persistanceActive) return false;
    final box = Hive.box(boxName);
    final ts = box.get('${key}_${AppConfig.keyCacheTimestamp}');
    if (ts == null) return false;
    final saved = DateTime.tryParse(ts as String);
    if (saved == null) return false;
    return DateTime.now().difference(saved) < AppConfig.cacheDuration;
  }

  /// Vide un cache spécifique
  static Future<void> clear(String boxName, String key) async {
    if (!AppConfig.persistanceActive) return;
    final box = Hive.box(boxName);
    await box.delete(key);
    await box.delete('${key}_${AppConfig.keyCacheTimestamp}');
  }

  /// Sauvegarde un objet unique (profil, user...)
  static Future<void> saveMap(String boxName, String key, Map<String, dynamic> data) async {
    if (!AppConfig.persistanceActive) return;
    final box = Hive.box(boxName);
    await box.put(key, jsonEncode(data));
  }

  /// Lit un objet unique
  static Map<String, dynamic>? readMap(String boxName, String key) {
    if (!AppConfig.persistanceActive) return null;
    final box = Hive.box(boxName);
    final raw = box.get(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}