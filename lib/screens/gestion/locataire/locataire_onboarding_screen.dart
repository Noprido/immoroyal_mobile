import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locataire_provider.dart';

/// Route hors shell : /gestion/locataire/onboarding (pas de navbar).
class LocataireOnboardingScreen extends StatefulWidget {
  const LocataireOnboardingScreen({super.key});

  @override
  State<LocataireOnboardingScreen> createState() => _LocataireOnboardingScreenState();
}

class _LocataireOnboardingScreenState extends State<LocataireOnboardingScreen> {
  @override
  void initState() {
    super.initState();
    // Si l'ID n'a pas pu être chargé par le shell, on retente une fois
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prov = context.read<LocataireProvider>();
      if (prov.monId == null && !prov.loading) prov.load();
    });
  }

  Future<void> _copier(String monId) async {
    await Clipboard.setData(ClipboardData(text: monId));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('ID copié dans le presse-papiers'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }

  Future<void> _partager(String monId, String? tel) async {
    final message = 'Mon ID ImmoRoyal : $monId'
        '${tel != null ? ' (ou mon numéro : $tel)' : ''}. '
        'Merci de me lier à mon logement dans l\'app ImmoRoyal.';
    await SharePlus.instance.share(ShareParams(text: message));
  }

  @override
  Widget build(BuildContext context) {
    final monId = context.watch<LocataireProvider>().monId;
    final tel = context.watch<AuthProvider>().user?.telephone;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _Header(onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 24 + MediaQuery.of(context).padding.bottom),
              children: [
                const _Etapes(),
                const SizedBox(height: 20),
                const _StepCard(
                  numero: 1,
                  titre: 'Partagez votre ID ou numéro',
                  texte: 'Donnez votre identifiant ImmoRoyal ou votre numéro de téléphone à votre gérant.',
                  actif: true,
                  opacite: 1,
                ),
                const SizedBox(height: 10),
                const _StepCard(
                  numero: 2,
                  titre: 'Votre gérant vous lie au bien',
                  texte: 'Il entre votre ID dans l\'app et vous associe à votre logement.',
                  opacite: 0.7,
                ),
                const SizedBox(height: 10),
                const _StepCard(
                  numero: 3,
                  titre: 'Accédez à votre espace',
                  texte: 'Vous recevez une notification et votre tableau de bord locataire s\'active.',
                  opacite: 0.5,
                ),
                const SizedBox(height: 24),
                Text(
                  'Votre identifiant ImmoRoyal',
                  style: AppText.label.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: kGrey),
                ),
                const SizedBox(height: 8),
                _IdCard(
                  monId: monId,
                  telephone: tel,
                  onCopier: monId == null ? null : () => _copier(monId),
                ),
                const SizedBox(height: 12),
                const _InfoAlert(texte: 'Votre gérant doit avoir un compte ImmoRoyal pour vous lier à un bien.'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: monId == null ? null : () => _partager(monId, tel),
                  child: const Text('Partager mon ID'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    context.read<LocataireProvider>().choisirAttente();
                    context.pop();
                  },
                  child: const Text('J\'attends que mon gérant me contacte'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: kNavBar,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back, size: 18, color: kWhite),
                const SizedBox(width: 6),
                Text('Retour', style: AppText.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: 'Comment ça ', style: AppText.logoImmo),
                TextSpan(text: 'marche ?', style: AppText.logoRoyal),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'En 3 étapes simples',
            style: AppText.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

/// Indicateur visuel : étape 1 active, 2 et 3 grisées.
class _Etapes extends StatelessWidget {
  const _Etapes();

  @override
  Widget build(BuildContext context) {
    Widget dot(int n, bool actif) => Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: actif ? kGold : kWhite,
            border: Border.all(color: actif ? kGold : kGreyBorder, width: 1.5),
          ),
          child: Text(
            '$n',
            style: AppText.badge.copyWith(fontSize: 12, fontWeight: FontWeight.w800, color: actif ? kBlack : kGrey),
          ),
        );
    Widget ligne() => Expanded(child: Container(height: 2, color: kGreyBorder));

    return Row(children: [dot(1, true), ligne(), dot(2, false), ligne(), dot(3, false)]);
  }
}

class _StepCard extends StatelessWidget {
  final int numero;
  final String titre;
  final String texte;
  final bool actif;
  final double opacite;

  const _StepCard({
    required this.numero,
    required this.titre,
    required this.texte,
    this.actif = false,
    required this.opacite,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacite,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kGreyBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: actif ? kGold : kGreyLight,
              ),
              child: Text(
                '$numero',
                style: AppText.bodyBold.copyWith(fontSize: 14, fontWeight: FontWeight.w800, color: actif ? kBlack : kGrey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: AppText.cardTitle.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(texte, style: AppText.bodySmall.copyWith(height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdCard extends StatelessWidget {
  final String? monId;
  final String? telephone;
  final VoidCallback? onCopier;

  const _IdCard({required this.monId, required this.telephone, required this.onCopier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: kNavBar, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID à partager avec votre gérant',
                  style: AppText.cardMeta.copyWith(color: Colors.white.withValues(alpha: 0.55)),
                ),
                const SizedBox(height: 4),
                Text(
                  monId ?? 'Chargement…',
                  style: AppText.price.copyWith(fontSize: 18, letterSpacing: 1),
                ),
                if (telephone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ou partagez votre numéro : $telephone',
                    style: AppText.cardMeta.copyWith(fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onCopier,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.content_copy_outlined,
                size: 18,
                color: onCopier == null ? Colors.white24 : kGold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoAlert extends StatelessWidget {
  final String texte;
  const _InfoAlert({required this.texte});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kGoldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: kGoldDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texte, style: AppText.bodySmall.copyWith(color: kGoldDark)),
          ),
        ],
      ),
    );
  }
}
