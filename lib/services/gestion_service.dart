import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../models/groupe.dart';
import '../models/bien.dart';

/// Appels API du module Gestion.
/// Contrat : les listes sont renvoyées en tableau JSON brut
/// (comme /profile/annonces), les créations/modifications renvoient l'objet.
class GestionService {
  final Dio _dio = DioClient.instance;
  static const _base = ApiConstants.gestion;

  // ─── Groupes ────────────────────────────────────────────────────
  Future<List<GroupeModel>> getGroupes() async {
    final resp = await _dio.get('$_base/groupes');
    return (resp.data as List)
        .map((j) => GroupeModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<GroupeModel> creerGroupe({required String nom, String? description}) async {
    final resp = await _dio.post('$_base/groupes', data: {
      'nom': nom,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return GroupeModel.fromJson(resp.data as Map<String, dynamic>);
  }

  // ─── Biens ──────────────────────────────────────────────────────
  Future<List<BienModel>> getBiens() async {
    final resp = await _dio.get('$_base/biens');
    return (resp.data as List)
        .map((j) => BienModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<BienModel> getBien(String id) async {
    final resp = await _dio.get('$_base/biens/$id');
    return BienModel.fromJson(resp.data as Map<String, dynamic>);
  }

  /// [data] = champs du bien (+ clé 'bail' optionnelle), construit par bien_form_screen.
  Future<BienModel> creerBien(Map<String, dynamic> data) async {
    final resp = await _dio.post('$_base/biens', data: data);
    return BienModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<BienModel> lierLocataire(String bienId, String idOuTel) async {
    final resp = await _dio.post(
      '$_base/biens/$bienId/lier-locataire',
      data: {'idOuTel': idOuTel},
    );
    return BienModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<BienModel> delierLocataire(String bienId) async {
    final resp = await _dio.delete('$_base/biens/$bienId/lier-locataire');
    return BienModel.fromJson(resp.data as Map<String, dynamic>);
  }

  // ─── Côté locataire ─────────────────────────────────────────────
  Future<List<BienModel>> getMesLogements() async {
    final resp = await _dio.get('$_base/locataire/mes-logements');
    return (resp.data as List)
        .map((j) => BienModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Retourne l'ID ImmoRoyal formaté (#IR-XXXX).
  Future<String?> getMonId() async {
    final resp = await _dio.get('$_base/mon-id');
    final data = resp.data as Map<String, dynamic>;
    return data['monId'] as String?;
  }

    // ─── Modification / suppression ─────────────────────────────────
  Future<GroupeModel> modifierGroupe(String id, {required String nom, String? description}) async {
    final resp = await _dio.put('$_base/groupes/$id', data: {
      'nom': nom,
      'description': description ?? '',
    });
    return GroupeModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> supprimerGroupe(String id) async {
    await _dio.delete('$_base/groupes/$id');
  }

  Future<BienModel> modifierBien(String id, Map<String, dynamic> data) async {
    final resp = await _dio.put('$_base/biens/$id', data: data);
    return BienModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> supprimerBien(String id) async {
    await _dio.delete('$_base/biens/$id');
  }

  /// Aperçu d'un utilisateur par ID ou téléphone (correspondance exacte).
  Future<Map<String, dynamic>> rechercherUtilisateur(String q) async {
    final resp = await _dio.get('$_base/recherche-utilisateur', queryParameters: {'q': q});
    return resp.data as Map<String, dynamic>;
  }
}
