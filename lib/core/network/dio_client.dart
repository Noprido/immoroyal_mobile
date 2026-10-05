import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class DioClient {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static GlobalKey<NavigatorState> get _navigatorKey => navigatorKey;
  static Dio? _instance;
  static const _storage = FlutterSecureStorage();

  static Dio get instance {
    _instance ??= _create();
    return _instance!;
  }

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Intercepteur : injecte le JWT sur chaque requête
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: ApiConstants.jwtKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        // APRÈS
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: ApiConstants.jwtKey);
            await _storage.delete(key: ApiConstants.userKey);
            final ctx = _navigatorKey.currentContext;
            if (ctx != null && ctx.mounted) {
              GoRouter.of(ctx).go('/login');
            }
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }

  // Réinitialise l'instance (ex: après logout)
  static void reset() => _instance = null;
}
