import 'package:flutter/material.dart';
import '../models/annonce.dart';
import '../services/annonces_service.dart';
import '../core/constants/app_config.dart';
import '../core/cache/cache_service.dart';

class AnnoncesProvider extends ChangeNotifier {
  final AnnoncesService _service = AnnoncesService();

  List<AnnonceModel> _annonces = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;

  String? filtreVille;
  String? filtreTypeBien;
  String? filtreTypeTransaction;

  List<AnnonceModel> get annonces    => _annonces;
  bool               get loading     => _loading;
  bool               get loadingMore => _loadingMore;
  String?            get error       => _error;
  bool               get hasMore     => _page < _totalPages;

  Future<void> load({bool silent = false}) async {
    final estSansFiltres = filtreVille == null &&
        filtreTypeBien == null &&
        filtreTypeTransaction == null;

    // Stale-while-revalidate : afficher le cache immédiatement
    if (!silent && estSansFiltres && AppConfig.persistanceActive) {
      final cached = CacheService.read(
        AppConfig.hiveBoxAnnonces,
        AppConfig.keyAnnoncesHome,
      );
      if (cached != null) {
        _annonces = cached.map((j) => AnnonceModel.fromJson(j)).toList();
        _loading = false;
        notifyListeners();
        silent = true; // refresh silencieux en arrière-plan
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

      final result = await _service.getAnnonces(
        ville:           filtreVille,
        typeBien:        filtreTypeBien,
        typeTransaction: filtreTypeTransaction,
        page: 1,
      );

      _annonces   = result['data'] as List<AnnonceModel>;
      _totalPages = (result['meta']['pages'] as num).toInt();

    } catch (_) {
      if (_annonces.isEmpty) _error = 'Erreur de chargement.';
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
      final result = await _service.getAnnonces(
        ville:           filtreVille,
        typeBien:        filtreTypeBien,
        typeTransaction: filtreTypeTransaction,
        page:            _page,
      );
      _annonces.addAll(result['data'] as List<AnnonceModel>);
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

  void clearFiltres() => setFiltres();
}