import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/gestion_provider.dart';

class GestionOnboardingScreen extends StatelessWidget {
  const GestionOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const _Header(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 32, 16, 110 + MediaQuery.of(context).padding.bottom),
              children: [
                const _Hero(),
                const SizedBox(height: 28),
                _RoleCard(
                  icon: Icons.home_work_outlined,
                  iconColor: kGoldDark,
                  iconBg: kGoldBg,
                  titre: 'Je gère des biens',
                  sousTitre: 'Créer des groupes, ajouter des biens, suivre les loyers',
                  borderColor: kGold,
                  chevronColor: kGold,
                  onTap: () => context.read<GestionProvider>().choisirModeGerant(),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  icon: Icons.person_outline,
                  iconColor: kGrey,
                  iconBg: kGreyLight,
                  titre: 'Je suis locataire',
                  sousTitre: 'Suivre mon loyer, payer, voir mes documents',
                  borderColor: kGreyBorder,
                  chevronColor: kGreyBorder,
                  onTap: () => context.push('/gestion/locataire/onboarding'),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Vous pouvez être gérant et locataire avec le même compte — chaque rôle s\'active selon votre usage.',
                    textAlign: TextAlign.center,
                    style: AppText.cardMeta.copyWith(height: 1.6),
                  ),
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
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: kNavBar,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: 'Gestion ', style: AppText.logoImmo.copyWith(fontSize: 22)),
                TextSpan(text: 'immobilière', style: AppText.logoRoyal.copyWith(fontSize: 22)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gérez vos biens et suivez votre loyer',
            style: AppText.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: kGoldBg,
            shape: BoxShape.circle,
            border: Border.all(color: kGold.withValues(alpha: 0.4), width: 3),
          ),
          child: const Icon(Icons.home_outlined, size: 60, color: kGoldDark),
        ),
        const SizedBox(height: 20),
        Text(
          'Bienvenue dans\nvotre espace gestion',
          textAlign: TextAlign.center,
          style: AppText.pageTitle.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Que vous soyez propriétaire, gérant ou locataire, tout est au même endroit.',
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(fontSize: 14, color: kGrey, height: 1.6),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String titre;
  final String sousTitre;
  final Color borderColor;
  final Color chevronColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.titre,
    required this.sousTitre,
    required this.borderColor,
    required this.chevronColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kWhite,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 26, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre, style: AppText.sectionTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(sousTitre, style: AppText.cardMeta),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 22, color: chevronColor),
            ],
          ),
        ),
      ),
    );
  }
}
