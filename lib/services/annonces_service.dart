import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_config.dart';
import '../core/cache/cache_service.dart';
import '../models/annonce.dart';

class AnnoncesService {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> getAnnonces({
    String? ville,
    String? quartier,
    String? typeBien,
    String? typeTransaction,
    int? prixMin,
    int? prixMax,
    String? q,
    int? nbChambres,
    int? nbSalons,
    String? standing,
    String? mode,
    int page = 1,
    int limit = 20,
  }) async {
    final estSansFiltres = ville == null && typeBien == null &&
        typeTransaction == null && prixMin == null &&
        prixMax == null && q == null;
    final cacheKey = page == 1 && estSansFiltres
        ? AppConfig.keyAnnoncesHome
        : null;

    try {
      final resp = await _dio.get(ApiConstants.annonces, queryParameters: {
        if (ville != null && ville.isNotEmpty) 'ville': ville,
        if (quartier != null && quartier.isNotEmpty) 'quartier': quartier,
        if (typeBien != null && typeBien.isNotEmpty) 'typeBien': typeBien,
        if (typeTransaction != null && typeTransaction.isNotEmpty) 'typeTransaction': typeTransaction,
        if (prixMin != null) 'prixMin': prixMin,
        if (prixMax != null) 'prixMax': prixMax,
        if (q != null && q.isNotEmpty) 'q': q,
        if (nbChambres != null) 'nbChambres': nbChambres,
        if (nbSalons != null) 'nbSalons': nbSalons,
        if (standing != null) 'standing': standing,
        if (mode != null) 'mode': mode,
        'page': page,
        'limit': limit,
      });

      final data = resp.data as Map<String, dynamic>;
      final list = data['data'] as List;

      // Sauvegarder en cache si éligible
      if (cacheKey != null && AppConfig.persistanceActive) {
        await CacheService.save(
          AppConfig.hiveBoxAnnonces,
          cacheKey,
          list.map((e) => e as Map<String, dynamic>).toList(),
        );
      }

      return {
        'data': list.map((j) => AnnonceModel.fromJson(j as Map<String, dynamic>)).toList(),
        'meta': data['meta'],
        'fromCache': false,
      };
    } catch (e) {
      // Pas de réseau → lire le cache
      if (cacheKey != null) {
        final cached = CacheService.read(AppConfig.hiveBoxAnnonces, cacheKey);
        if (cached != null) {
          return {
            'data': cached.map((j) => AnnonceModel.fromJson(j)).toList(),
            'meta': {'total': cached.length, 'page': 1, 'limit': limit, 'pages': 1},
            'fromCache': true,
          };
        }
      }
      rethrow;
    }
  }

  Future<AnnonceModel> getAnnonce(String id) async {
    final resp = await _dio.get('${ApiConstants.annonces}/$id');
    return AnnonceModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> toggleActif(String id) async {
    await _dio.post('${ApiConstants.annonces}/$id/toggle');
  }

  Future<void> deleteAnnonce(String id) async {
    await _dio.delete('${ApiConstants.annonces}/$id');
  }

  Future<Map<String, int>> getStatsCategories() async {
    final resp = await _dio.get('${ApiConstants.annonces}/stats-categories');
    final data = resp.data as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, (v as num).toInt()));
  }
}