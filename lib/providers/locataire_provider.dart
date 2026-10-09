import 'package:flutter/material.dart';
import '../core/utils/api_error.dart';
import '../models/bien.dart';
import '../services/gestion_service.dart';

class LocataireProvider extends ChangeNotifier {
  final GestionService _service = GestionService();

  List<BienModel> _mesLogements = [];
  String? _monId; // ex : "#IR-4F2A"
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  /// Vrai quand l'utilisateur a tapé "J'attends mon gérant" (écran d'attente).
  bool _attenteChoisie = false;

  List<BienModel> get mesLogements => _mesLogements;
  String? get monId   => _monId;
  bool    get loading => _loading;
  bool    get loaded  => _loaded;
  String? get error   => _error;

  bool get estLocataire   => _mesLogements.isNotEmpty;
  bool get attenteChoisie => _attenteChoisie;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _mesLogements = await _service.getMesLogements();
      _loaded = true;
      // L'ID n'est pas bloquant : si l'appel échoue, on garde les logements.
      try {
        _monId = await _service.getMonId();
      } catch (_) {}
    } catch (e) {
      _error = extractApiError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void choisirAttente() {
    _attenteChoisie = true;
    notifyListeners();
  }

  void reinitialiserChoix() {
    _attenteChoisie = false;
    notifyListeners();
  }

  // payerLoyer(...) arrive à l'étape 8 (LocatairePayerScreen) avec le PaymentService.

  /// Appelé par le ProxyProvider (app.dart) : vide les données à la déconnexion.
  void syncAuth(bool isAuthenticated) {
    if (!isAuthenticated &&
        (_loaded || _mesLogements.isNotEmpty || _monId != null || _attenteChoisie)) {
      _mesLogements = [];
      _monId = null;
      _loaded = false;
      _error = null;
      _attenteChoisie = false;
      // pas de notifyListeners : appelé pendant un build
    }
  }
}
