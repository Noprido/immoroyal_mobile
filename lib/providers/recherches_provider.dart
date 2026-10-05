import 'package:flutter/material.dart';
import '../models/recherche.dart';
import '../services/recherches_service.dart';
import '../core/constants/app_config.dart';
import '../core/cache/cache_service.dart';

class RecherchesProvider extends ChangeNotifier {
  final RecherchesService _service = RecherchesService();

  List<RechercheModel> _recherches = [];
  bool    _loading     = false;
  bool    _loadingMore = false;
  String? _error;
  int _page       = 1;
  int _totalPages = 1;

  String? filtreVille;
  String? filtreTypeBien;
  String? filtreTypeTransaction;

  List<RechercheModel> get recherches   => _recherches;
  bool                 get loading      => _loading;
  bool                 get loadingMore  => _loadingMore;
  String?              get error        => _error;
  bool                 get hasMore      => _page < _totalPages;

  Future<void> load({bool silent = false}) async {
    final estSansFiltres = filtreVille == null &&
        filtreTypeBien == null &&
        filtreTypeTransaction == null;

    // Stale-while-revalidate
    if (!silent && estSansFiltres && AppConfig.persistanceActive) {
      final cached = CacheService.read(
        AppConfig.hiveBoxRecherches,
        AppConfig.keyRecherches,
      );
      if (cached != null) {
        _recherches = cached.map((j) => RechercheModel.fromJson(j)).toList();
        _loading = false;
        notifyListeners();
        silent = true;
      }
    }

    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _page = 1;
      _totalPages = 1;
      final result = await _service.getRecherches(
        ville:           filtreVille,
        typeBien:        filtreTypeBien,
        typeTransaction: filtreTypeTransaction,
      );
      _recherches = result['data'] as List<RechercheModel>;
      _totalPages = (result['meta']['pages'] as num).toInt();
    } catch (_) {
      if (_recherches.isEmpty) _error = 'Erreur de chargement.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      _page++;
      final result = await _service.getRecherches(
        ville:           filtreVille,
        typeBien:        filtreTypeBien,
        typeTransaction: filtreTypeTransaction,
        page:            _page,
      );
      _recherches.addAll(result['data'] as List<RechercheModel>);
      _totalPages = (result['meta']['pages'] as num).toInt();
    } catch (_) {
      _page--;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  void setFiltres({String? ville, String? typeBien, String? typeTransaction}) {
    filtreVille           = ville;
    filtreTypeBien        = typeBien;
    filtreTypeTransaction = typeTransaction;
    load();
  }
}