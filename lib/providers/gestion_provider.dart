import 'package:flutter/material.dart';
import '../core/utils/api_error.dart';
import '../models/groupe.dart';
import '../models/bien.dart';
import '../services/gestion_service.dart';

class GestionProvider extends ChangeNotifier {
  final GestionService _service = GestionService();

  List<GroupeModel> _groupes = [];
  List<BienModel> _biens = [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  /// Vrai quand l'utilisateur a tapé "Je suis gérant" mais n'a encore rien créé.
  /// Évite la boucle onboarding → dashboard vide → onboarding.
  bool _modeGerantChoisi = false;

  List<GroupeModel> get groupes => _groupes;
  List<BienModel>   get biens   => _biens;
  bool    get loading => _loading;
  bool    get loaded  => _loaded;
  String? get error   => _error;

  bool get hasGroupe         => _groupes.isNotEmpty;
  bool get estGerant         => _groupes.isNotEmpty || _biens.isNotEmpty;
  bool get modeGerantChoisi  => _modeGerantChoisi;

  // ─── Calculs dérivés ────────────────────────────────────────────
  List<BienModel> get biensEnRetard => _biens.where((b) => b.enRetard).toList();
  double get totalMensuel => _biens.fold<double>(0, (sum, b) => sum + b.loyerMensuel);
  List<BienModel> biensDuGroupe(String groupeId) =>
      _biens.where((b) => b.groupeId == groupeId).toList();

    BienModel? bienParId(String id) {
    for (final b in _biens) {
      if (b.id == id) return b;
    }
    return null;
  }

  GroupeModel? groupeParId(String id) {
    for (final g in _groupes) {
      if (g.id == id) return g;
    }
    return null;
  }

  // ─── Chargement ─────────────────────────────────────────────────
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _fetch();
      _loaded = true;
    } catch (e) {
      _error = extractApiError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _fetch() async {
    final results = await Future.wait([_service.getGroupes(), _service.getBiens()]);
    _groupes = results[0] as List<GroupeModel>;
    _biens   = results[1] as List<BienModel>;
  }

  /// Rechargement sans toucher à `loading` (après une mutation).
  Future<void> _refresh() async {
    try {
      await _fetch();
    } catch (_) {}
    notifyListeners();
  }

  // ─── Actions ────────────────────────────────────────────────────
  void choisirModeGerant() {
    _modeGerantChoisi = true;
    notifyListeners();
  }

    /// « Changer de rôle » : revient à l'onboarding si le compte n'a aucune donnée.
  void reinitialiserChoix() {
    _modeGerantChoisi = false;
    notifyListeners();
  }

  Future<bool> creerGroupe({required String nom, String? description}) async {
    _error = null;
    try {
      final g = await _service.creerGroupe(nom: nom, description: description);
      _groupes = [g, ..._groupes];
      notifyListeners();
      return true;
    } catch (e) {
      _error = extractApiError(e);
      notifyListeners();
      return false;
    }
  }

  /// [data] : champs du bien (+ 'bail' optionnel). Recharge ensuite groupes + biens
  /// pour que `biensIds` du groupe reste cohérent avec le serveur.
  Future<bool> ajouterBien(Map<String, dynamic> data) async {
    _error = null;
    try {
      await _service.creerBien(data);
      await _refresh();
      return true;
    } catch (e) {
      _error = extractApiError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> lierLocataire(String bienId, String idOuTel) async {
    _error = null;
    try {
      final b = await _service.lierLocataire(bienId, idOuTel);
      _remplacerBien(b);
      return true;
    } catch (e) {
      _error = extractApiError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> delierLocataire(String bienId) async {
    _error = null;
    try {
      final b = await _service.delierLocataire(bienId);
      _remplacerBien(b);
      return true;
    } catch (e) {
      _error = extractApiError(e);
      notifyListeners();
      return false;
    }
  }

    Future<bool> modifierGroupe(String id, {required String nom, String? description}) async {
    _error = null;
    try {
      final g = await _service.modifierGroupe(id, nom: nom, description: description);
      _groupes = _groupes.map((x) => x.id == g.id ? g : x).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = extractApiError(e);
      notifyListeners();
      return false;
    }
  }

  /// Supprime le groupe ET ses biens (cascade côté serveur).
  Future<bool> supprimerGroupe(String id) async {
    _error = null;
    try {
      await _service.supprimerGroupe(id);
      _groupes = _groupes.where((g) => g.id != id).toList();
      _biens = _biens.where((b) => b.groupeId != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = extractApiError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> modifierBien(String id, Map<String, dynamic> data) async {
    _error = null;
    try {
      await _service.modifierBien(id, data);
      await _refresh(); // le groupe peut avoir changé → biensIds cohérents
      return true;
    } catch (e) {
      _error = extractApiError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> supprimerBien(String id) async {
    _error = null;
    try {
      await _service.supprimerBien(id);
      await _refresh();
      return true;
    } catch (e) {
      _error = extractApiError(e);
      notifyListeners();
      return false;
    }
  }

  /// Lève l'exception Dio : l'écran affiche le message via extractApiError.
  Future<Map<String, dynamic>> rechercherUtilisateur(String q) => _service.rechercherUtilisateur(q);

  void _remplacerBien(BienModel b) {
    _biens = _biens.map((x) => x.id == b.id ? b : x).toList();
    notifyListeners();
  }

  // ─── Session ────────────────────────────────────────────────────
  /// Appelé par le ProxyProvider (app.dart) : vide les données à la déconnexion.
  void syncAuth(bool isAuthenticated) {
    if (!isAuthenticated &&
        (_loaded || _groupes.isNotEmpty || _biens.isNotEmpty || _modeGerantChoisi)) {
      _groupes = [];
      _biens = [];
      _loaded = false;
      _error = null;
      _modeGerantChoisi = false;
      // pas de notifyListeners : appelé pendant un build
    }
  }
}
