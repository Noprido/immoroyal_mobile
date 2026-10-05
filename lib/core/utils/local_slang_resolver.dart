import 'text_normalize.dart';

const Map<String, int> _nombresLettres = {
  'un': 1, 'une': 1,
  'deux': 2, 'trois': 3, 'quatre': 4, 'cinq': 5,
  'six': 6, 'sept': 7, 'huit': 8, 'neuf': 9, 'dix': 10,
};

int? _parseNombre(String token) {
  final n = int.tryParse(token);
  if (n != null) return n;
  return _nombresLettres[token];
}

const _standings = ['sanitaire', 'semi-sanitaire', 'ordinaire'];

class SlangResult {
  final String? typeBien;
  final int? nbChambres;
  final int? nbSalons;
  final String? standing;
  final String texteRestant;

  const SlangResult({
    this.typeBien,
    this.nbChambres,
    this.nbSalons,
    this.standing,
    required this.texteRestant,
  });
}

/// Reconnaît les expressions argotiques locales ("chambre salon",
/// "2 chambres salon sanitaire"...) avant le passage au SearchMatcher.
class LocalSlangResolver {
  SlangResult resolve(String input) {
    final norm = normalize(input);
    final words = norm.split(RegExp(r'[^a-z0-9-]+')).where((w) => w.isNotEmpty).toList();

    int? nbChambres;
    int? nbSalons;
    String? standing;
    String? typeBien;
    final consumed = List<bool>.filled(words.length, false);

    for (int i = 0; i < words.length; i++) {
      if (consumed[i]) continue;
      final w = words[i];

      if (w == 'chambre' || w == 'chambres') {
        nbChambres = 1;
        consumed[i] = true;
        if (i > 0 && !consumed[i - 1]) {
          final n = _parseNombre(words[i - 1]);
          if (n != null) { nbChambres = n; consumed[i - 1] = true; }
        }
        continue;
      }

      if (w == 'salon' || w == 'salons') {
        nbSalons = 1;
        consumed[i] = true;
        if (i > 0 && !consumed[i - 1]) {
          final n = _parseNombre(words[i - 1]);
          if (n != null) { nbSalons = n; consumed[i - 1] = true; }
        }
        continue;
      }
    }

    // "chambre salon" ensemble => Appartement vide, même sans nombre explicite
    if (nbChambres != null || nbSalons != null) {
      typeBien = 'Appartement vide';
      nbChambres ??= 1;
      nbSalons ??= 1;
    }

    for (int i = 0; i < words.length; i++) {
      if (consumed[i]) continue;
      if (_standings.contains(words[i])) {
        standing = words[i];
        consumed[i] = true;
      }
    }

    final restant = <String>[];
    for (int i = 0; i < words.length; i++) {
      if (!consumed[i]) restant.add(words[i]);
    }

    return SlangResult(
      typeBien: typeBien,
      nbChambres: nbChambres,
      nbSalons: nbSalons,
      standing: standing,
      texteRestant: restant.join(' '),
    );
  }
}