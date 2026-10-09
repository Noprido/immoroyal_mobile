import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/bien.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/gestion_provider.dart';
import '../../../providers/suggestions_provider.dart';
import '../../../widgets/common/autocomplete_field.dart';
import '../../../widgets/gestion/groupe_dialog.dart';

/// Route hors shell :
///   /gestion/biens/creer?groupeId=...   → création
///   /gestion/biens/:id/modifier         → modification
class BienFormScreen extends StatefulWidget {
  final String? bienId;
  final String? groupeId;

  const BienFormScreen({super.key, this.bienId, this.groupeId});

  @override
  State<BienFormScreen> createState() => _BienFormScreenState();
}

class _BienFormScreenState extends State<BienFormScreen> {
  final _nomCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _quartierCtrl = TextEditingController();
  final _proprioCtrl = TextEditingController();
  final _loyerCtrl = TextEditingController();
  final _jourCtrl = TextEditingController(text: '5');

  BienModel? _bien;
  String? _groupeId;
  String? _typeBien;
  bool _avecBail = false;
  bool _bailExistant = false;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _envoi = false;
  String? _erreur;

  bool get _edition => widget.bienId != null;

  @override
  void initState() {
    super.initState();
    final prov = context.read<GestionProvider>();

    if (_edition) {
      final b = prov.bienParId(widget.bienId!);
      _bien = b;
      if (b != null) {
        _nomCtrl.text = b.nom;
        _adresseCtrl.text = b.adresse;
        _villeCtrl.text = b.ville;
        _quartierCtrl.text = b.quartier ?? '';
        _proprioCtrl.text = b.proprietaireNom ?? '';
        _groupeId = b.groupeId;
        _typeBien = b.typeBien;
        if (b.bail != null) {
          _avecBail = true;
          _bailExistant = true;
          _loyerCtrl.text = b.bail!.montantLoyer.round().toString();
          _jourCtrl.text = b.bail!.jourEcheance.toString();
          _dateDebut = b.bail!.dateDebut;
          _dateFin = b.bail!.dateFin;
        }
      }
    } else {
      if (widget.groupeId != null && prov.groupeParId(widget.groupeId!) != null) {
        _groupeId = widget.groupeId;
      } else if (prov.groupes.length == 1) {
        _groupeId = prov.groupes.first.id;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cat = context.read<CategoriesProvider>();
      if (cat.categories.isEmpty) cat.load();
    });
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _adresseCtrl.dispose();
    _villeCtrl.dispose();
    _quartierCtrl.dispose();
    _proprioCtrl.dispose();
    _loyerCtrl.dispose();
    _jourCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  Future<void> _choisirDate({required bool debut}) async {
    final base = (debut ? _dateDebut : _dateFin) ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(base.year, base.month, base.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      final utc = DateTime.utc(d.year, d.month, d.day);
      if (debut) {
        _dateDebut = utc;
      } else {
        _dateFin = utc;
      }
    });
  }

  Future<void> _creerGroupe() async {
    final ok = await GroupeDialog.show(context);
    if (ok == true && mounted) {
      final groupes = context.read<GestionProvider>().groupes;
      if (groupes.isNotEmpty) setState(() => _groupeId = groupes.first.id);
    }
  }

  Future<void> _enregistrer() async {
    final nom = _nomCtrl.text.trim();
    final adresse = _adresseCtrl.text.trim();
    final ville = _villeCtrl.text.trim();

    String? err;
    double? loyer;
    int? jour;

    if (_groupeId == null) {
      err = 'Choisissez un groupe.';
    } else if (nom.isEmpty) {
      err = 'Donnez un nom au bien (ex : Studio A).';
    } else if (_typeBien == null) {
      err = 'Choisissez le type de bien.';
    } else if (adresse.isEmpty) {
      err = 'Indiquez l\'adresse du bien.';
    } else if (ville.isEmpty) {
      err = 'Indiquez la ville.';
    } else if (_avecBail) {
      loyer = double.tryParse(_loyerCtrl.text.replaceAll(' ', '').replaceAll(',', '.'));
      jour = int.tryParse(_jourCtrl.text.trim());
      if (loyer == null || loyer <= 0) {
        err = 'Indiquez un loyer valide.';
      } else if (jour == null || jour < 1 || jour > 31) {
        err = 'Le jour d\'échéance doit être compris entre 1 et 31.';
      } else if (_dateDebut == null) {
        err = 'Choisissez la date de début du bail.';
      } else if (_dateFin != null && _dateFin!.isBefore(_dateDebut!)) {
        err = 'La date de fin doit suivre la date de début.';
      }
    }

    if (err != null) {
      setState(() => _erreur = err);
      return;
    }

    setState(() {
      _envoi = true;
      _erreur = null;
    });

    final data = <String, dynamic>{
      'groupeId': _groupeId,
      'nom': nom,
      'typeBien': _typeBien,
      'adresse': adresse,
      'ville': ville,
      'quartier': _quartierCtrl.text.trim(),
      'proprietaireNom': _proprioCtrl.text.trim(),
      if (_avecBail)
        'bail': {
          'montantLoyer': loyer,
          'jourEcheance': jour,
          'dateDebut': _dateDebut!.toIso8601String(),
          'dateFin': _dateFin?.toIso8601String(),
        },
    };

    final prov = context.read<GestionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = _edition
        ? await prov.modifierBien(widget.bienId!, data)
        : await prov.ajouterBien(data);

    if (!mounted) return;
    if (ok) {
      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(_edition ? 'Bien mis à jour' : 'Bien ajouté'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _envoi = false;
        _erreur = prov.error ?? 'Une erreur est survenue.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_edition && _bien == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(title: const Text('Modifier le bien')),
        body: Center(child: Text('Bien introuvable.', style: AppText.bodySmall)),
      );
    }

    final prov = context.watch<GestionProvider>();
    final cat = context.watch<CategoriesProvider>();
    final suggestions = context.read<SuggestionsProvider>().villesEtQuartiers;

    // Liste des types : catégories de l'app + valeur actuelle + "Autre"
    final typeItems = <DropdownMenuItem<String>>[
      ...cat.categories.map((c) => DropdownMenuItem<String>(value: c.value, child: Text(c.label))),
    ];
    if (_typeBien != null && !typeItems.any((i) => i.value == _typeBien)) {
      typeItems.add(DropdownMenuItem<String>(value: _typeBien, child: Text(_typeBien!)));
    }
    if (!typeItems.any((i) => i.value == 'Autre')) {
      typeItems.add(const DropdownMenuItem<String>(value: 'Autre', child: Text('Autre')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: Text(_edition ? 'Modifier le bien' : 'Nouveau bien')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 24 + MediaQuery.of(context).padding.bottom),
        children: [
          Text('Informations', style: AppText.sectionTitle),
          const SizedBox(height: 12),

          // ── Groupe ──
          if (prov.groupes.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kGoldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kGold.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Un bien appartient à un groupe (une résidence, un immeuble…). Créez d\'abord votre premier groupe.',
                    style: AppText.bodySmall.copyWith(color: kGoldDark),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _creerGroupe,
                    child: const Text('Créer un groupe'),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _groupeId,
              hint: const Text('Choisir un groupe'),
              decoration: const InputDecoration(
                labelText: 'Groupe',
                prefixIcon: Icon(Icons.apartment_outlined, size: 18),
              ),
              items: prov.groupes
                  .map((g) => DropdownMenuItem<String>(value: g.id, child: Text(g.nom)))
                  .toList(),
              onChanged: (v) => setState(() => _groupeId = v),
            ),
          const SizedBox(height: 14),

          TextField(
            controller: _nomCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nom du bien',
              hintText: 'Ex : Studio A, Appartement 2B',
            ),
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            initialValue: _typeBien,
            hint: const Text('Choisir le type'),
            decoration: const InputDecoration(
              labelText: 'Type de bien',
              prefixIcon: Icon(Icons.home_work_outlined, size: 18),
            ),
            items: typeItems,
            onChanged: (v) => setState(() => _typeBien = v),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _adresseCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              hintText: 'Rue, repère, numéro de porte…',
            ),
          ),
          const SizedBox(height: 14),

          AutocompleteField(
            label: 'Ville',
            controller: _villeCtrl,
            hint: 'Cotonou, Calavi…',
            suggestions: suggestions,
            icon: Icons.location_city_outlined,
          ),
          const SizedBox(height: 14),

          AutocompleteField(
            label: 'Quartier (optionnel)',
            controller: _quartierCtrl,
            hint: 'Fidjrossè, Akpakpa…',
            suggestions: suggestions,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _proprioCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nom du propriétaire (optionnel)',
            ),
          ),
          const SizedBox(height: 24),

          // ── Bail ──
          Text('Loyer et bail', style: AppText.sectionTitle),
          const SizedBox(height: 4),
          if (!_bailExistant)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _avecBail,
              onChanged: (v) => setState(() => _avecBail = v),
              title: Text('Définir le loyer maintenant', style: AppText.label),
              subtitle: Text(
                'Vous pourrez aussi le faire plus tard, en modifiant le bien.',
                style: AppText.cardMeta,
              ),
            ),
          if (_avecBail) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _loyerCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Loyer mensuel',
                suffixText: 'FCFA',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _jourCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jour d\'échéance du loyer',
                helperText: 'Jour du mois (1 à 31)',
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => _choisirDate(debut: true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Début du bail',
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                ),
                child: Text(
                  _dateDebut != null ? _formatDate(_dateDebut!) : 'Choisir une date',
                  style: AppText.body.copyWith(color: _dateDebut != null ? kBlack : kGrey),
                ),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => _choisirDate(debut: false),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fin du bail (optionnel)',
                  suffixIcon: _dateFin != null
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _dateFin = null),
                        )
                      : const Icon(Icons.calendar_today_outlined, size: 18),
                ),
                child: Text(
                  _dateFin != null ? _formatDate(_dateFin!) : 'Durée indéterminée',
                  style: AppText.body.copyWith(color: _dateFin != null ? kBlack : kGrey),
                ),
              ),
            ),
          ],

          if (_erreur != null) ...[
            const SizedBox(height: 16),
            Text(_erreur!, style: AppText.bodySmall.copyWith(color: kRed)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _envoi ? null : _enregistrer,
            child: _envoi
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kBlack),
                  )
                : Text(_edition ? 'Enregistrer les modifications' : 'Ajouter le bien'),
          ),
        ],
      ),
    );
  }
}
