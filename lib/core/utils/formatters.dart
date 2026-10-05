import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final _fcfa = NumberFormat('#,###', 'fr_FR');

  /// "35 000 FCFA"
  static String fcfa(num? value) {
    if (value == null || value == 0) return '0 FCFA';
    return '${_fcfa.format(value).replaceAll('\u202f', '\u00a0')} FCFA';
  }

  /// Prix affiché (rétrocompat loyer → prix)
  static num getPrix(Map<String, dynamic> annonce) =>
      (annonce['prix'] ?? annonce['loyer'] ?? 0) as num;

  static String getPrixAffiche(Map<String, dynamic> annonce) =>
      fcfa(getPrix(annonce));

  /// Label durée location
  static String getLabelDuree(String? duree) {
    return switch (duree) {
      'heure' => 'par heure',
      '6h'    => 'par 6h',
      '12h'   => 'par 12h',
      '24h'   => 'par 24h',
      'semaine' => 'par semaine',
      'mois'  => 'par mois',
      _       => '',
    };
  }

  /// Date lisible "13 juillet 2026"
  static String dateLocale(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('d MMMM yyyy', 'fr_FR').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  /// Date courte "22/06/2026"
  static String dateCourte(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  /// Total à l'entrée
  static num totalEntree(Map<String, dynamic> a) {
    final loyer    = (a['loyer'] ?? 0) as num;
    final prix     = (a['prix'] ?? 0) as num;
    final montant  = loyer > 0 ? loyer : prix;
    final avance   = (a['moisAvance'] ?? 0) as num;
    final eau      = (a['cautionEau'] ?? 0) as num;
    final elec     = (a['cautionElec'] ?? 0) as num;
    final comm     = (a['commissionDemarcheur'] ?? 0) as num;
    return montant * avance + eau + elec + comm;
  }
}
