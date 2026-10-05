import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../models/user.dart';

class AuthService {
  final Dio _dio = DioClient.instance;
  static const _storage = FlutterSecureStorage();

  /// Connexion → retourne (token, user)
  Future<Map<String, dynamic>> login({
    required String telephone,
    required String password,
  }) async {
    final resp = await _dio.post(
      ApiConstants.login,
      data: {'telephone': telephone, 'password': password},
    );
    return resp.data as Map<String, dynamic>;
  }

  /// Inscription
  Future<Map<String, dynamic>> register({
    required String nom,
    required String telephone,
    required String whatsapp,
    required String password,
  }) async {
    final resp = await _dio.post(
      ApiConstants.register,
      data: {
        'nom': nom,
        'telephone': telephone,
        'whatsapp': whatsapp,
        'password': password,
      },
    );
    return resp.data as Map<String, dynamic>;
  }

  /// Récupère l'utilisateur courant (JWT requis)
  Future<UserModel> getMe() async {
    final resp = await _dio.get(ApiConstants.me);
    return UserModel.fromJson(resp.data as Map<String, dynamic>);
  }

  /// Sauvegarde token + user en stockage sécurisé
  Future<void> saveSession(String token, UserModel user) async {
    await _storage.write(key: ApiConstants.jwtKey, value: token);
    await _storage.write(key: ApiConstants.userKey, value: token); // stocke aussi userId
  }

  /// Lit le token stocké
  Future<String?> getStoredToken() =>
      _storage.read(key: ApiConstants.jwtKey);

  /// Supprime la session (logout)
  Future<void> clearSession() async {
    await _storage.delete(key: ApiConstants.jwtKey);
    await _storage.delete(key: ApiConstants.userKey);
    DioClient.reset();
  }
}
