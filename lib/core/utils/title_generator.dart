import '../../models/category.dart';

String _pieceWord(int n, String singulier, String pluriel, {required bool feminin}) {
  if (n == 1) return feminin ? 'une $singulier' : 'un $singulier';
  return '$n $pluriel';
}

/// Aperçu du titre côté mobile (lecture seule dans le formulaire).
/// Le serveur reste la source de vérité au moment de l'enregistrement.
String genererTitrePreview({
  required CategoryModel? categorie,
  required String ville,
  int nbChambres = 0,
  int nbSalons = 0,
  int nbPieces = 0,
  String? standing,
  double dimension = 0,
}) {
  if (categorie == null || ville.trim().isEmpty) return '';

  final standingSuffix = (categorie.supporteStanding && standing != null && standing.isNotEmpty)
      ? ' $standing'
      : '';

  switch (categorie.titreFormat) {
    case 'chambresSalon':
      final chambres = _pieceWord(nbChambres, 'chambre', 'chambres', feminin: true);
      final salons = _pieceWord(nbSalons, 'salon', 'salons', feminin: false);
      return '$chambres $salons$standingSuffix à $ville';

    case 'pieces':
      final pieces = _pieceWord(nbPieces, 'pièce', 'pièces', feminin: true);
      return '${categorie.value} $pieces$standingSuffix à $ville';

    case 'terrain':
      return 'Terrain ${dimension.toStringAsFixed(0)}m² à $ville';

    case 'simple':
    default:
      return '${categorie.value} à $ville';
  }
}