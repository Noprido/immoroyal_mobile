/// Extrait un message lisible d'une erreur Dio (même logique que AuthProvider).
String extractApiError(dynamic e) {
  try {
    final data = (e as dynamic).response?.data;
    if (data is Map) {
      return (data['error'] ?? data['message'] ?? 'Erreur inconnue').toString();
    }
  } catch (_) {}
  return 'Erreur de connexion. Vérifiez votre réseau.';
}
