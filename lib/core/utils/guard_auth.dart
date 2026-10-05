import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// Retourne true si l'utilisateur est connecté.
/// Sinon, redirige vers /login et retourne false.
/// Utilisation : if (!guardAuth(context)) return;
bool guardAuth(BuildContext context) {
  final auth = context.read<AuthProvider>();
  if (auth.isAuthenticated) return true;
  context.push('/login');
  return false;
}
