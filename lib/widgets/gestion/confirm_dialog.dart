import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

/// Boîte de confirmation commune (suppression, déliaison...).
/// Retourne true si l'utilisateur confirme.
Future<bool> confirmerAction(
  BuildContext context, {
  required String titre,
  required String message,
  String confirmer = 'Supprimer',
  bool danger = true,
}) async {
  final resultat = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: kWhite,
      title: Text(titre, style: AppText.sectionTitle),
      content: Text(message, style: AppText.body.copyWith(fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: danger ? kRed : kGold),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmer),
        ),
      ],
    ),
  );
  return resultat == true;
}
