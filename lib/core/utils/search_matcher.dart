import 'text_normalize.dart';

List<String> _tokenize(String input) {
  final norm = normalize(input);
  return norm.split(RegExp(r'[^a-z0-9]+')).where((w) => w.isNotEmpty).toList();
}

class SearchMatchResult {
  final String? typeBien;
  final String? ville;
  final String? quartier;
  final String? q;

  const SearchMatchResult({this.typeBien, this.ville, this.quartier, this.q});

  bool get isEmpty =>
      typeBien == null && ville == null && quartier == null && (q == null || q!.isEmpty);
}

/// Détecte, dans un texte libre, les mots correspondant à une ville, un quartier
/// ou une catégorie connues, et renvoie le reste en texte libre.
/// Priorité en cas d'égalité de longueur de match : ville > quartier > catégorie.
class SearchMatcher {
  final Map<String, String> _villeIndex;
  final Map<String, String> _quartierIndex;
  final Map<String, String> _categorieIndex;
  final int _maxWords;

  SearchMatcher._(this._villeIndex, this._quartierIndex, this._categorieIndex, this._maxWords);

  factory SearchMatcher.build({
    required List<String> villes,
    required List<String> quartiers,
    required List<String> categories,
  }) {
    int maxWords = 1;

    Map<String, String> buildIndex(List<String> source) {
      final index = <String, String>{};
      for (final canonical in source) {
        final tokens = _tokenize(canonical);
        if (tokens.isEmpty) continue;
        if (tokens.length > maxWords) maxWords = tokens.length;
        index.putIfAbsent(tokens.join(' '), () => canonical);
      }
      return index;
    }

    return SearchMatcher._(
      buildIndex(villes),
      buildIndex(quartiers),
      buildIndex(categories),
      maxWords,
    );
  }

  SearchMatchResult match(String input) {
    final words = _tokenize(input);
    if (words.isEmpty) return const SearchMatchResult();

    String? foundVille;
    String? foundQuartier;
    String? foundTypeBien;
    final freeWords = <String>[];

    int i = 0;
    while (i < words.length) {
      final remaining = words.length - i;
      final maxLen = remaining < _maxWords ? remaining : _maxWords;
      int consumed = 1;
      bool matched = false;

      // Recherche la plus longue séquence de mots possible en priorité
      for (int len = maxLen; len >= 1; len--) {
        final key = words.sublist(i, i + len).join(' ');

        if (foundVille == null && _villeIndex.containsKey(key)) {
          foundVille = _villeIndex[key];
          consumed = len;
          matched = true;
          break;
        }
        if (foundQuartier == null && _quartierIndex.containsKey(key)) {
          foundQuartier = _quartierIndex[key];
          consumed = len;
          matched = true;
          break;
        }
        if (foundTypeBien == null && _categorieIndex.containsKey(key)) {
          foundTypeBien = _categorieIndex[key];
          consumed = len;
          matched = true;
          break;
        }
      }

      if (matched) {
        i += consumed;
      } else {
        freeWords.add(words[i]);
        i += 1;
      }
    }

    return SearchMatchResult(
      typeBien: foundTypeBien,
      ville: foundVille,
      quartier: foundQuartier,
      q: freeWords.isEmpty ? null : freeWords.join(' '),
    );
  }
}