import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/groupe.dart';
import '../../providers/gestion_provider.dart';

/// Création (groupe == null) ou modification d'un groupe.
/// Usage : GroupeDialog.show(context)  /  GroupeDialog.show(context, groupe: g)
class GroupeDialog extends StatefulWidget {
  final GroupeModel? groupe;
  const GroupeDialog({super.key, this.groupe});

  static Future<bool?> show(BuildContext context, {GroupeModel? groupe}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => GroupeDialog(groupe: groupe),
    );
  }

  @override
  State<GroupeDialog> createState() => _GroupeDialogState();
}

class _GroupeDialogState extends State<GroupeDialog> {
  late final TextEditingController _nomCtrl =
      TextEditingController(text: widget.groupe?.nom ?? '');
  late final TextEditingController _descCtrl =
      TextEditingController(text: widget.groupe?.description ?? '');

  bool _envoi = false;
  String? _erreur;

  bool get _edition => widget.groupe != null;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final nom = _nomCtrl.text.trim();
    final description = _descCtrl.text.trim();
    if (nom.isEmpty) {
      setState(() => _erreur = 'Saisissez un nom.');
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });

    final prov = context.read<GestionProvider>();
    final ok = _edition
        ? await prov.modifierGroupe(widget.groupe!.id, nom: nom, description: description)
        : await prov.creerGroupe(nom: nom, description: description);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _envoi = false;
        _erreur = prov.error ?? 'Une erreur est survenue.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kWhite,
      scrollable: true,
      title: Text(_edition ? 'Modifier le groupe' : 'Nouveau groupe', style: AppText.sectionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nomCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nom du groupe',
              hintText: 'Ex : Résidence Les Palmiers',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Description (optionnel)',
              errorText: _erreur,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _envoi ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        // Le thème impose une largeur minimale infinie aux ElevatedButton : on la neutralise ici
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(110, 44)),
          onPressed: _envoi ? null : _valider,
          child: _envoi
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kBlack),
                )
              : Text(_edition ? 'Enregistrer' : 'Créer'),
        ),
      ],
    );
  }
}
