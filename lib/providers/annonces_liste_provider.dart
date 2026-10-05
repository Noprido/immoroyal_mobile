import 'package:flutter/material.dart';
import '../models/annonce.dart';
import '../services/annonces_service.dart';

class AnnoncesListeProvider extends ChangeNotifier {
  final AnnoncesService _service = AnnoncesService();

  List<AnnonceModel> _annonces = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;

  String? filtreVille;
  String? filtreQuartier;
  String? filtreTypeBien;
  String? filtreTypeTransaction;
  String? filtreQ;
  int? filtreNbChambres;
  int? filtreNbSalons;
  String? filtreStanding;
  bool modePertinence = false;

  List<AnnonceModel> get annonces    => _annonces;
  bool               get loading     => _loading;
  bool               get loadingMore => _loadingMore;
  String?            get error       => _error;
  bool               get hasMore     => _page < _totalPages;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _page = 1;
      _totalPages = 1;

      final result = await _service.getAnnonces(
        ville:           filtreVille,
        quartier:        filtreQuartier,
        typeBien:        filtreTypeBien,
        typeTransaction: filtreTypeTransaction,
        q:               filtreQ,
        nbChambres:      filtreNbChambres,
        nbSalons:        filtreNbSalons,
        standing:        filtreStanding,
        mode:            modePertinence ? 'relevance' : null,
        page:            _page,
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
        quartier:        filtreQuartier,
        typeBien:        filtreTypeBien,
        typeTransaction: filtreTypeTransaction,
        q:               filtreQ,
        nbChambres:      filtreNbChambres,
        nbSalons:        filtreNbSalons,
        standing:        filtreStanding,
        mode:            modePertinence ? 'relevance' : null,
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

  void setFiltres({String? ville, String? quartier, String? typeBien, String? typeTransaction, String? q}) {
    filtreVille           = ville;
    filtreQuartier        = quartier;
    filtreTypeBien        = typeBien;
    filtreTypeTransaction = typeTransaction;
    filtreQ               = q;
    filtreNbChambres      = null;
    filtreNbSalons        = null;
    filtreStanding        = null;
    modePertinence         = false;
    load();
  }

  void rechercherTexte({
    String? ville,
    String? quartier,
    String? typeBien,
    String? q,
    int? nbChambres,
    int? nbSalons,
    String? standing,
  }) {
    filtreVille           = ville;
    filtreQuartier        = quartier;
    filtreTypeBien        = typeBien;
    filtreTypeTransaction = null;
    filtreQ               = q;
    filtreNbChambres      = nbChambres;
    filtreNbSalons        = nbSalons;
    filtreStanding        = standing;
    modePertinence         = true;
    load();
  }

  void clearFiltres() {
    modePertinence = false;
    setFiltres();
  }
}