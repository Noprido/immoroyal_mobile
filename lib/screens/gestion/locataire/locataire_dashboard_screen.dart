import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/bien.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/gestion_provider.dart';
import '../../../providers/locataire_provider.dart';
import '../../../widgets/gestion/gestion_badge.dart';
import '../../../widgets/gestion/gestion_header.dart';

/// Dashboard locataire : en-tête + switcher, logements liés ou état « aucun logement ».
class LocataireDashboardScreen extends StatelessWidget {
  final VoidCallback onSwitchGerant;
  const LocataireDashboardScreen({super.key, required this.onSwitchGerant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Consumer<LocataireProvider>(
        builder: (_, prov, __) {
          final enRetard = prov.mesLogements.where((b) => b.enRetard).length;
          return Column(
            children: [
              GestionHeader(
                titre: 'Locataire',
                gerantActif: false,
                onSwitch: (gerant) {
                  if (gerant) onSwitchGerant();
                },
                stats: prov.estLocataire
                    ? GestionStats(items: [
                        StatItem('${prov.mesLogements.length}', 'Logement${prov.mesLogements.length > 1 ? 's' : ''}'),
                        StatItem('$enRetard', 'En retard', couleur: enRetard == 0 ? kGold : kRed),
                      ])
                    : null,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: kGold,
                  onRefresh: () => prov.load(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 110 + MediaQuery.of(context).padding.bottom),
                    children: [
                      if (!prov.estLocataire)
                        _Attente(monId: prov.monId)
                      else ...[
                        Text('Mes logements', style: AppText.sectionTitle),
                        const SizedBox(height: 10),
                        for (final b in prov.mesLogements) ...[
                          _LogementCard(bien: b),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LogementCard extends StatelessWidget {
  final BienModel bien;
  const _LogementCard({required this.bien});

  @override
  Widget build(BuildContext context) {
    final GestionBadge badge = bien.enRetard
        ? GestionBadge(label: 'Retard · ${bien.joursRetard ?? 0} j', couleur: kRed)
        : const GestionBadge(label: 'À jour', couleur: kActiveGreen);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kGreyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(bien.nom, style: AppText.cardTitle.copyWith(fontSize: 15))),
              badge,
            ],
          ),
          const SizedBox(height: 2),
          Text('${bien.adresse}, ${bien.ville}', style: AppText.cardMeta),
          if (bien.bail != null) ...[
            const SizedBox(height: 10),
            Text(
              '${AppFormatters.fcfa(bien.loyerMensuel)} / mois',
              style: AppText.price.copyWith(fontSize: 16, letterSpacing: 0),
            ),
            const SizedBox(height: 2),
            Text('Échéance le ${bien.bail!.jourEcheance} de chaque mois', style: AppText.cardMeta),
          ],
        ],
      ),
    );
  }
}

class _Attente extends StatelessWidget {
  final String? monId;
  const _Attente({required this.monId});

  @override
  Widget build(BuildContext context) {
    final tel = context.watch<AuthProvider>().user?.telephone;
    final aucuneDonnee = !context.watch<GestionProvider>().estGerant;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kGreyBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: kGoldBg, shape: BoxShape.circle),
            child: const Icon(Icons.hourglass_empty_rounded, color: kGoldDark, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun logement lié pour l\'instant',
            textAlign: TextAlign.center,
            style: AppText.sectionTitle.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Donnez votre ID ou votre numéro à votre gérant : dès qu\'il vous aura lié à un logement, il apparaîtra ici.',
            textAlign: TextAlign.center,
            style: AppText.bodySmall.copyWith(height: 1.5),
          ),
          if (monId != null) ...[
            const SizedBox(height: 16),
            Text(monId!, style: AppText.price.copyWith(fontSize: 18, letterSpacing: 1, color: kGoldDark)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: monId!));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(
                          content: Text('ID copié'),
                          behavior: SnackBarBehavior.floating,
                        ));
                    },
                    child: const Text('Copier'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => SharePlus.instance.share(ShareParams(
                      text: 'Mon ID ImmoRoyal : $monId'
                          '${tel != null ? ' (ou mon numéro : $tel)' : ''}. '
                          'Merci de me lier à mon logement dans l\'app ImmoRoyal.',
                    )),
                    child: const Text('Partager'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.push('/gestion/locataire/onboarding'),
            child: Text('Comment ça marche ?', style: AppText.labelGold),
          ),
          if (aucuneDonnee) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                context.read<GestionProvider>().reinitialiserChoix();
                context.read<LocataireProvider>().reinitialiserChoix();
              },
              child: Text(
                'Changer de rôle',
                style: AppText.bodySmall.copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
