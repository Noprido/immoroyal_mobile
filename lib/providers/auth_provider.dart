import 'package:flutter/material.dart';
import 'package:immoroyal/providers/messages_provider.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/push_notifications_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  AuthStatus _status = AuthStatus.loading;
  UserModel? _user;
  String? _error;
  String? _token;

  MessagesProvider? _messagesProvider;

  String? get token => _token;
  AuthStatus get status => _status;
  UserModel?  get user   => _user;
  String?     get error  => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading       => _status == AuthStatus.loading;

  Future<void> checkAuth() async {
    try {
      final token = await _service.getStoredToken();
      if (token == null) {
        _status = AuthStatus.unauthenticated;
      } else {
        _user = await _service.getMe();
        _status = AuthStatus.authenticated;
        _messagesProvider?.connect(token);
        _token = token;
        PushNotificationsService.registerTokenWithBackend(); // ⬅️ AJOUT (pas de await, pas bloquant)
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String telephone, String password) async {
    _error = null;
    try {
      final data = await _service.login(telephone: telephone, password: password);
      final token = data['token'] as String;
      _token = token;
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _service.saveSession(token, _user!);
      _status = AuthStatus.authenticated;
      notifyListeners();
      PushNotificationsService.registerTokenWithBackend(); // ⬅️ AJOUT
      _messagesProvider?.connect(token);
      return true;
    } catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String nom,
    required String telephone,
    required String whatsapp,
    required String password
  }) async {
    _error = null;
    try {
      final data = await _service.register(
        nom: nom,
        telephone: telephone,
        whatsapp: whatsapp,
        password: password,
      );
      final token = data['token'] as String;
      _token = token;
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _service.saveSession(token, _user!);
      _status = AuthStatus.authenticated;
      notifyListeners();
      PushNotificationsService.registerTokenWithBackend(); // ⬅️ AJOUT
      _messagesProvider?.connect(token);
      return true;
    } catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _messagesProvider?.disconnect();
    await _service.clearSession();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _token = null;
    notifyListeners();
  }

  void updateUser(UserModel updated) {
    _user = updated;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setMessagesProvider(MessagesProvider p) {
    _messagesProvider = p;
  }

  String _extractError(dynamic e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map) return (data['error'] ?? data['message'] ?? 'Erreur inconnue').toString();
    } catch (_) {}
    return 'Erreur de connexion. Vérifiez votre réseau.';
  }
}
