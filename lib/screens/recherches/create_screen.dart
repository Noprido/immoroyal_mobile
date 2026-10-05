import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/network/dio_client.dart';
import '../../widgets/common/gold_button.dart';
import 'package:provider/provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/suggestions_provider.dart';
import '../../widgets/common/autocomplete_field.dart';

// const _typesBiensRecherche = [
//   'Appartement meublé', 'Appartement vide', 'Maison',
//   'Entrée personnelle', 'Chambre', 'Terrain',
//   'Boutique', 'Magasin', 'Bureau', 'Autre',
// ];

const _dureesLocationRecherche = [
  {'label': 'Par heure',   'value': 'heure'},
  {'label': 'Par 6h',      'value': '6h'},
  {'label': 'Par 12h',     'value': '12h'},
  {'label': 'Par 24h',     'value': '24h'},
  {'label': 'Par semaine', 'value': 'semaine'},
  {'label': 'Par mois',    'value': 'mois'},
];

class CreateRechercheScreen extends StatefulWidget {
  const CreateRechercheScreen({super.key});
  @override
  State<CreateRechercheScreen> createState() => _CreateRechercheScreenState();
}

class _CreateRechercheScreenState extends State<CreateRechercheScreen> {
  int _step = 0;
  bool _submitting = false;
  String? _error;
  bool _firstFrameDone = false;

  // ── Étape 1 ──
  final _titreCtrl       = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _typeTransaction = 'location';
  String? _typeBien;
  final _autreTypeBienCtrl = TextEditingController();

  // ── Étape 2 ──
  final _budgetCtrl  = TextEditingController();
  String _dureeLocation = 'mois';
  bool _fondsDisponibles = false;

  // ── Étape 3 ──
  bool _localisationImporte = false;
  final _villeCtrl    = TextEditingController();
  final _quartierCtrl = TextEditingController();

  // ── Étape 4 ──
  final _chambresCtrl = TextEditingController();
  final _salonsCtrl   = TextEditingController();
  final _douchesCtrl  = TextEditingController();
  final _cuisinesCtrl = TextEditingController();

  @override
  void dispose() {
    _titreCtrl.dispose(); _descriptionCtrl.dispose(); _autreTypeBienCtrl.dispose();
    _budgetCtrl.dispose(); _villeCtrl.dispose(); _quartierCtrl.dispose();
    _chambresCtrl.dispose(); _salonsCtrl.dispose(); _douchesCtrl.dispose();
    _cuisinesCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _firstFrameDone = true);
      final catProv = context.read<CategoriesProvider>();
      if (catProv.categories.isEmpty) catProv.load();
      // final suggProv = context.read<SuggestionsProvider>();
      // if (suggProv.villes.isEmpty) suggProv.load();
    });
  }

  String? _validateStep() {
    switch (_step) {
      case 0:
        if (_titreCtrl.text.trim().isEmpty) return 'Le titre est requis.';
        if (_typeBien == null) return 'Le type de bien est requis.';
        if (_typeBien == 'Autre' && _autreTypeBienCtrl.text.trim().isEmpty)
          return 'Précisez le type de bien.';
        return null;
      case 1:
        if (_budgetCtrl.text.trim().isEmpty) return 'Le budget est requis.';
        return null;
      case 2:
        if (!_localisationImporte && _villeCtrl.text.trim().isEmpty)
          return 'Indiquez une ville ou cochez "Peu importe".';
        return null;
      case 3:
        return null;
      default:
        return null;
    }
  }

  void _next() {
    final err = _validateStep();
    if (err != null) { setState(() => _error = err); return; }
    setState(() { _error = null; _step++; });
  }

  void _prev() => setState(() { _error = null; _step--; });

  Future<void> _submit() async {
    final err = _validateStep();
    if (err != null) { setState(() => _error = err); return; }
    setState(() { _submitting = true; _error = null; });

    try {
      await DioClient.instance.post('/recherches', data: {
        'titre':               _titreCtrl.text.trim(),
        'description':         _descriptionCtrl.text.trim(),
        'typeBien':            _typeBien,
        'autreTypeBien':       _autreTypeBienCtrl.text.trim(),
        'typeTransaction':     _typeTransaction,
        'localisationImporte': _localisationImporte,
        'ville':               _villeCtrl.text.trim(),
        'quartier':            _quartierCtrl.text.trim(),
        'budgetMax':           _budgetCtrl.text.trim(),
        'dureeLocation':       _dureeLocation,
        'fondsDisponibles':    _fondsDisponibles,
        'nbChambres':          _chambresCtrl.text.trim(),
        'nbSalons':            _salonsCtrl.text.trim(),
        'nbDouches':           _douchesCtrl.text.trim(),
        'nbCuisines':          _cuisinesCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recherche publiée !'), backgroundColor: kActiveGreen),
        );
        context.go('/recherches');
      }
    } catch (e) {
      String msg = 'Erreur lors de la publication.';
      try {
        final data = (e as dynamic).response?.data;
        if (data is Map) msg = data['error'] ?? msg;
      } catch (_) {}
      if (mounted) setState(() { _error = msg; _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kNavBar,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new, color: kWhite, size: 20),
        ),
        title: const Text('Je cherche', style: TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: !_firstFrameDone
          ? const SizedBox.shrink()
          : Column(
              children: [
                _Stepper(currentStep: _step),

          if (_error != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: kRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: AppText.bodySmall.copyWith(color: kRed))),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStep(),
            ),
          ),

          _buildNavButtons(),
        ],
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _buildEtape1(),
      1 => _buildEtape2(),
      2 => _buildEtape3(),
      3 => _buildEtape4(),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildEtape1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'Informations générales'),
        const SizedBox(height: 20),

        _Field(label: 'Titre *', ctrl: _titreCtrl, hint: 'Ex: Cherche appartement à Cotonou'),
        const SizedBox(height: 16),

        Text('Type de transaction *', style: AppText.label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _ToggleBtn(label: 'Location', selected: _typeTransaction == 'location', onTap: () => setState(() => _typeTransaction = 'location'))),
            const SizedBox(width: 10),
            Expanded(child: _ToggleBtn(label: 'Achat', selected: _typeTransaction == 'achat', onTap: () => setState(() => _typeTransaction = 'achat'))),
          ],
        ),
        const SizedBox(height: 16),

        Text('Type de bien *', style: AppText.label),
        const SizedBox(height: 8),
        Consumer<CategoriesProvider>(
          builder: (_, catProv, __) {
            return DropdownButtonFormField<String>(
              initialValue: _typeBien,
              hint: const Text('Choisir...'),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.home_outlined, size: 18)),
              items: [
                ...catProv.categories.map((c) => DropdownMenuItem(value: c.value, child: Text(c.label))),
                const DropdownMenuItem(value: 'Autre', child: Text('Autre')),
              ],
              onChanged: (v) => setState(() => _typeBien = v),
            );
          },
        ),

        if (_typeBien == 'Autre') ...[
          const SizedBox(height: 16),
          _Field(label: 'Précisez le type de bien *', ctrl: _autreTypeBienCtrl, hint: 'Ex: Villa, duplex...'),
        ],

        const SizedBox(height: 16),
        Text('Description (optionnel)', style: AppText.label),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionCtrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Décrivez ce que vous recherchez...'),
        ),
      ],
    );
  }

  Widget _buildEtape2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'Budget'),
        const SizedBox(height: 20),

        Text('Budget maximum *', style: AppText.label),
        const SizedBox(height: 8),
        TextFormField(
          controller: _budgetCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '100 000', suffixText: 'FCFA'),
        ),
        const SizedBox(height: 16),

        if (_typeTransaction == 'location') ...[
          Text('Durée souhaitée', style: AppText.label),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _dureeLocation,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.schedule, size: 18)),
            items: _dureesLocationRecherche.map((d) => DropdownMenuItem(
              value: d['value'], child: Text(d['label']!),
            )).toList(),
            onChanged: (v) => setState(() => _dureeLocation = v!),
          ),
          const SizedBox(height: 16),
        ],

        // Fonds disponibles
        GestureDetector(
          onTap: () => setState(() => _fondsDisponibles = !_fondsDisponibles),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _fondsDisponibles ? kActiveGreen.withValues(alpha: 0.08) : kGreyLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _fondsDisponibles ? kActiveGreen : kGreyBorder),
            ),
            child: Row(
              children: [
                Icon(
                  _fondsDisponibles ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: _fondsDisponibles ? kActiveGreen : kGrey,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fonds disponibles', style: AppText.bodyBold),
                      Text('Je déclare avoir les fonds nécessaires', style: AppText.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEtape3() {
    final suggProv = context.read<SuggestionsProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'Localisation'),
        const SizedBox(height: 20),

        // Peu importe
        GestureDetector(
          onTap: () => setState(() => _localisationImporte = !_localisationImporte),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _localisationImporte ? kGoldBg : kGreyLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _localisationImporte ? kGold : kGreyBorder),
            ),
            child: Row(
              children: [
                Icon(
                  _localisationImporte ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: _localisationImporte ? kGold : kGrey,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text('La localisation m\'importe peu', style: AppText.bodyBold),
              ],
            ),
          ),
        ),

        if (!_localisationImporte) ...[
          const SizedBox(height: 16),
          AutocompleteField(label: 'Ville / Commune *', controller: _villeCtrl, hint: 'Cotonou, Abomey-Calavi...', suggestions: suggProv.villes, icon: Icons.location_city_outlined),
          const SizedBox(height: 16),
          AutocompleteField(label: 'Quartier (optionnel)', controller: _quartierCtrl, hint: 'Fidjrossè, Akpakpa...', suggestions: suggProv.quartiers, icon: Icons.place_outlined),
        ],
      ],
    );
  }

  Widget _buildEtape4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'Caractéristiques souhaitées'),
        const SizedBox(height: 8),
        Text('Optionnel — laissez à 0 si peu importe', style: AppText.bodySmall),
        const SizedBox(height: 20),
        _Field(label: 'Chambres', ctrl: _chambresCtrl, type: TextInputType.number),
        const SizedBox(height: 16),
        _Field(label: 'Salons', ctrl: _salonsCtrl, type: TextInputType.number),
        const SizedBox(height: 16),
        _Field(label: 'Douches', ctrl: _douchesCtrl, type: TextInputType.number),
        const SizedBox(height: 16),
        _Field(label: 'Cuisines', ctrl: _cuisinesCtrl, type: TextInputType.number),
      ],
    );
  }

  Widget _buildNavButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: const BoxDecoration(color: kWhite, border: Border(top: BorderSide(color: kGreyBorder))),
      child: Column(
        children: [
          if (_step > 0) ...[
            GoldButton.outlined(label: '← Précédent', onPressed: _prev),
            const SizedBox(height: 10),
          ],
          if (_step < 3)
            GoldButton(label: 'Suivant →', onPressed: _next)
          else
            GoldButton(label: 'Publier ma recherche', icon: Icons.check, loading: _submitting, onPressed: _submit),
          const SizedBox(height: 10),
          GoldButton.ghost(label: '× Annuler', onPressed: () => context.pop()),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int currentStep;
  const _Stepper({required this.currentStep});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: kWhite,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i == currentStep;
          final isDone   = i < currentStep;
          final isLast   = i == 3;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: isActive ? kGold : isDone ? kActiveGreen : kGreyLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: isActive ? kGold : isDone ? kActiveGreen : kGreyBorder),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: kWhite, size: 16)
                        : Text('${i + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isActive ? kBlack : kGrey)),
                  ),
                ),
                if (!isLast) Expanded(child: Container(height: 2, color: isDone ? kActiveGreen : kGreyBorder)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 18, color: kGold, margin: const EdgeInsets.only(right: 10)),
        Text(label, style: AppText.sectionTitle.copyWith(fontSize: 15)),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String? hint;
  final TextInputType? type;
  const _Field({required this.label, required this.ctrl, this.hint, this.type});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 8),
        TextFormField(controller: ctrl, keyboardType: type, decoration: InputDecoration(hintText: hint)),
      ],
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? kGold : kWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? kGold : kGreyBorder),
        ),
        child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? kBlack : kGrey, fontSize: 14))),
      ),
    );
  }
}