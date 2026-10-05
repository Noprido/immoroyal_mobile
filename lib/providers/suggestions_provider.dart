// providers/suggestions_provider.dart
import 'package:flutter/material.dart';
import '../services/suggestions_service.dart';
import '../core/constants/app_config.dart';
import '../core/cache/cache_service.dart';

class SuggestionsProvider extends ChangeNotifier {
  final SuggestionsService _service = SuggestionsService();

  List<String> _villes = [];
  List<String> _quartiers = [];
  bool _loading = false;

  List<String> get villes => _villes;
  List<String> get quartiers => _quartiers;
  List<String> get villesEtQuartiers => [..._villes, ..._quartiers]; // pour champs combinés
  bool get loading => _loading;

  Future<void> load({bool silent = false}) async {
    if (!silent && AppConfig.persistanceActive) {
      final cached = CacheService.readMap(AppConfig.hiveBoxCategories, 'suggestions');
      if (cached != null) {
        _villes = List<String>.from(cached['villes'] ?? []);
        _quartiers = List<String>.from(cached['quartiers'] ?? []);
        notifyListeners();
        silent = true;
      }
    }

    if (!silent) { _loading = true; notifyListeners(); }

    try {
      final result = await _service.getSuggestions();
      _villes = result['villes']!;
      _quartiers = result['quartiers']!;

      if (AppConfig.persistanceActive) {
        await CacheService.saveMap(AppConfig.hiveBoxCategories, 'suggestions', {
          'villes': _villes,
          'quartiers': _quartiers,
        });
      }
    } catch (_) {
      // échec silencieux — le champ fonctionne juste sans suggestions
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}