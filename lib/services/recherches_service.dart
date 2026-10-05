import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_config.dart';
import '../core/cache/cache_service.dart';
import '../models/recherche.dart';

class RecherchesService {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> getRecherches({
    String? ville,
    String? typeBien,
    String? typeTransaction,
    int page = 1,
    int limit = 20,
  }) async {
    final estSansFiltres = ville == null && typeBien == null && typeTransaction == null;
    final cacheKey = page == 1 && estSansFiltres ? AppConfig.keyRecherches : null;

    try {
      final resp = await _dio.get(ApiConstants.recherches, queryParameters: {
        if (ville != null && ville.isNotEmpty) 'ville': ville,
        if (typeBien != null && typeBien.isNotEmpty) 'typeBien': typeBien,
        if (typeTransaction != null && typeTransaction.isNotEmpty) 'typeTransaction': typeTransaction,
        'page': page,
        'limit': limit,
      });

      final data = resp.data as Map<String, dynamic>;
      final list = data['data'] as List;

      if (cacheKey != null && AppConfig.persistanceActive) {
        await CacheService.save(
          AppConfig.hiveBoxRecherches,
          cacheKey,
          list.map((e) => e as Map<String, dynamic>).toList(),
        );
      }

      return {
        'data': list.map((j) => RechercheModel.fromJson(j as Map<String, dynamic>)).toList(),
        'meta': data['meta'],
        'fromCache': false,
      };
    } catch (e) {
      if (cacheKey != null) {
        final cached = CacheService.read(AppConfig.hiveBoxRecherches, cacheKey);
        if (cached != null) {
          return {
            'data': cached.map((j) => RechercheModel.fromJson(j)).toList(),
            'meta': {'total': cached.length, 'page': 1, 'limit': limit, 'pages': 1},
            'fromCache': true,
          };
        }
      }
      rethrow;
    }
  }

  Future<RechercheModel> getRecherche(String id) async {
    final resp = await _dio.get('${ApiConstants.recherches}/$id');
    return RechercheModel.fromJson(resp.data as Map<String, dynamic>);
  }
}