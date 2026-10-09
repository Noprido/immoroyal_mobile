import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/gestion_provider.dart';
import '../../providers/locataire_provider.dart';
import 'gestion_onboarding_screen.dart';
import 'gerant/gerant_dashboard_screen.dart';
import 'locataire/locataire_dashboard_screen.dart';

/// Point d'entrée de l'onglet Gestion (branche /gestion du shell).
/// Charge les deux rôles en parallèle, puis décide quoi afficher :
///   aucun rôle           → onboarding
///   un rôle              → son dashboard
///   les deux rôles       → dashboard + pill switcher
class GestionShell extends StatefulWidget {
  const GestionShell({super.key});

  @override
  State<GestionShell> createState() => _GestionShellState();
}

class _GestionShellState extends State<GestionShell> {
  bool? _modeLocataire; // null = automatique
  bool _chargementLance = false;

  Future<void> _charger() async {
    _chargementLance = true;
    try {
      await Future.wait([
        context.read<GestionProvider>().load(),
        context.read<LocataireProvider>().load(),
      ]);
    } finally {
      _chargementLance = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GestionProvider>();
    final l = context.watch<LocataireProvider>();

    final enCours = g.loading || l.loading;
    final echec = (!g.loaded && g.error != null) || (!l.loaded && l.error != null);

    // Premier affichage (ou après une déconnexion/reconnexion) : on lance le chargement
    final doitCharger = !g.loaded && !l.loaded && !enCours && g.error == null && l.error == null;
    if (doitCharger && !_chargementLance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_chargementLance) _charger();
      });
    }

    if (echec && !enCours) {
      return _ErreurView(message: g.error ?? l.error ?? 'Erreur de chargement.', onRetry: _charger);
    }
    if (!(g.loaded && l.loaded)) {
      return const _ChargementView();
    }

    final gerant = g.estGerant || g.modeGerantChoisi;
    final locataire = l.estLocataire || l.attenteChoisie;

    if (!gerant && !locataire) return const GestionOnboardingScreen();

    // Le switcher Gérant/Locataire est toujours visible :
    // un gérant peut être locataire ailleurs.
    final modeLocataire = _modeLocataire ?? (locataire && !gerant);

    return modeLocataire
        ? LocataireDashboardScreen(
            onSwitchGerant: () => setState(() => _modeLocataire = false),
          )
        : GerantDashboardScreen(
            onSwitchLocataire: () => setState(() => _modeLocataire = true),
          );
  }
}

class _ChargementView extends StatelessWidget {
  const _ChargementView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Gestion immobilière')),
      body: const Center(child: CircularProgressIndicator(color: kGold, strokeWidth: 2)),
    );
  }
}

class _ErreurView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErreurView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Gestion immobilière')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 56, color: kGreyBorder),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center, style: AppText.bodySmall),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onRetry,
                child: Text('Réessayer', style: AppText.labelGold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
