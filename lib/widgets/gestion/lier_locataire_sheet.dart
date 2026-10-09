import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/api_error.dart';
import '../../providers/gestion_provider.dart';

/// Lier un locataire à un bien : saisie d'un ID ou d'un numéro → aperçu de la
/// personne trouvée → confirmation. Usage : LierLocataireSheet.show(context, ...)
class LierLocataireSheet extends StatefulWidget {
  final String bienId;
  final String bienNom;

  const LierLocataireSheet({super.key, required this.bienId, required this.bienNom});

  static Future<void> show(
    BuildContext context, {
    required String bienId,
    required String bienNom,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => LierLocataireSheet(bienId: bienId, bienNom: bienNom),
    );
  }

  @override
  State<LierLocataireSheet> createState() => _LierLocataireSheetState();
}

class _LierLocataireSheetState extends State<LierLocataireSheet> {
  final _ctrl = TextEditingController();
  bool _recherche = false;
  bool _envoi = false;
  Map<String, dynamic>? _resultat;
  String? _erreur;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _rechercher() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) {
      setState(() => _erreur = 'Saisissez un ID ImmoRoyal ou un numéro de téléphone.');
      return;
    }
    setState(() {
      _recherche = true;
      _erreur = null;
      _resultat = null;
    });
    try {
      final r = await context.read<GestionProvider>().rechercherUtilisateur(q);
      if (!mounted) return;
      setState(() {
        _resultat = r;
        _recherche = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = extractApiError(e);
        _recherche = false;
      });
    }
  }

  Future<void> _lier() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    final prov = context.read<GestionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nom = (_resultat?['nom'] ?? 'Le locataire').toString();

    final ok = await prov.lierLocataire(widget.bienId, _ctrl.text.trim());
    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('$nom est maintenant lié(e) à « ${widget.bienNom} »'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _envoi = false;
        _erreur = prov.error ?? 'Liaison impossible.';
      });
    }
  }

  String _initiales(String nom) {
    final mots = nom.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
    if (mots.isEmpty) return '?';
    if (mots.length == 1) return mots.first[0].toUpperCase();
    return (mots.first[0] + mots.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final r = _resultat;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('Lier un locataire', style: AppText.sectionTitle)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: kGrey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('à « ${widget.bienNom} »', style: AppText.bodySmall),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _rechercher(),
            onChanged: (_) {
              if (_resultat != null || _erreur != null) {
                setState(() {
                  _resultat = null;
                  _erreur = null;
                });
              }
            },
            decoration: const InputDecoration(
              labelText: 'ID ImmoRoyal ou numéro de téléphone',
              hintText: '#IR-59E2E1 ou 97 00 00 00',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Le locataire trouve son ID dans Gestion → Je suis locataire.',
            style: AppText.cardMeta,
          ),
          if (_erreur != null) ...[
            const SizedBox(height: 12),
            Text(_erreur!, style: AppText.bodySmall.copyWith(color: kRed)),
          ],
          if (r != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kGoldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kGold.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
                    child: Text(
                      _initiales((r['nom'] ?? '').toString()),
                      style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((r['nom'] ?? '').toString(), style: AppText.cardTitle.copyWith(fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                          '${r['monId'] ?? ''} · ${r['telephoneMasque'] ?? ''}',
                          style: AppText.cardMeta,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_recherche || _envoi) ? null : (r == null ? _rechercher : _lier),
            child: (_recherche || _envoi)
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kBlack),
                  )
                : Text(r == null ? 'Rechercher' : 'Lier ce locataire'),
          ),
        ],
      ),
    );
  }
}
