import 'package:flutter/material.dart';
import '../services/annonces_service.dart';

class CategoriesStatsProvider extends ChangeNotifier {
  final AnnoncesService _service = AnnoncesService();

  Map<String, int> _counts = {}; // ex: {'Maison': 24, 'Terrain': 8, ...}
  bool _loading = false;

  Map<String, int> get counts  => _counts;
  bool              get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _counts = await _service.getStatsCategories();
    } catch (_) {
      // échec silencieux
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}