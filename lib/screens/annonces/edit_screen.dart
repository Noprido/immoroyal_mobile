import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../models/annonce.dart';
import '../../services/annonces_service.dart';
import '../../widgets/common/gold_button.dart';
import 'package:provider/provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/suggestions_provider.dart';
import '../../widgets/common/autocomplete_field.dart';
import '../../models/category.dart';
import '../../core/utils/title_generator.dart';


const _dureesLocationEdit = [
  {'label': 'Par heure',   'value': 'heure'},
  {'label': 'Par 6h',      'value': '6h'},
  {'label': 'Par 12h',     'value': '12h'},
  {'label': 'Par 24h',     'value': '24h'},
  {'label': 'Par semaine', 'value': 'semaine'},
  {'label': 'Par mois',    'value': 'mois'},
];

class EditAnnonceScreen extends StatefulWidget {
  final String id;
  const EditAnnonceScreen({super.key, required this.id});
  @override
  State<EditAnnonceScreen> createState() => _EditAnnonceScreenState();
}

class _EditAnnonceScreenState extends State<EditAnnonceScreen> {
  final _service = AnnoncesService();
  AnnonceModel? _annonce;
  bool _loadingAnnonce = true;
  int _step = 0;
  bool _submitting = false;
  String? _error;

  // ── Étape 1 ──
  final _dimensionCtrl = TextEditingController();
  final _villeCtrl       = TextEditingController();
  final _quartierCtrl    = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _typeTransaction = 'location';
  String? _typeBien;
  String? _standing;

  // ── Étape 2 ──
  final _prixCtrl        = TextEditingController();
  final _moisAvanceCtrl  = TextEditingController(text: '0');
  final _cautionEauCtrl  = TextEditingController(text: '0');
  final _cautionElecCtrl = TextEditingController(text: '0');
  final _commissionCtrl  = TextEditingController(text: '0');
  String _dureeLocation  = 'mois';

  // ── Étape 3 ──
  final _chambresCtrl = TextEditingController(text: '0');
  final _salonsCtrl   = TextEditingController(text: '0');
  final _douchesCtrl  = TextEditingController(text: '0');
  final _cuisinesCtrl = TextEditingController(text: '0');
  String? _electriciteType;
  String? _electriciteCompteur;
  String? _eauType;

  // ── Étape 4 ──
  List<String> _photosExistantes = [];
  List<String> _videosExistantes = [];
  final List<XFile> _nouveauxMedias = [];
  final _picker = ImagePicker();

  //Getters
  CategoryModel? get _categorieActuelle {
    if (_typeBien == null) return null;
    return context.read<CategoriesProvider>().byValue(_typeBien!);
  }

  List<String> get _champsAutorises => _categorieActuelle?.champsCaracteristiques ?? [];
  bool get _supporteStanding => _categorieActuelle?.supporteStanding ?? false;
  bool get _afficheDimension => _categorieActuelle?.afficheDimension ?? false;

  String get _titreGenere => genererTitrePreview(
    categorie: _categorieActuelle,
    ville: _villeCtrl.text.trim(),
    nbChambres: int.tryParse(_chambresCtrl.text) ?? 0,
    nbSalons: int.tryParse(_salonsCtrl.text) ?? 0,
    nbPieces: (int.tryParse(_chambresCtrl.text) ?? 0) +
              (int.tryParse(_salonsCtrl.text) ?? 0) +
              (int.tryParse(_douchesCtrl.text) ?? 0) +
              (int.tryParse(_cuisinesCtrl.text) ?? 0),
    standing: _standing,
    dimension: double.tryParse(_dimensionCtrl.text) ?? 0,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final annonce = await _service.getAnnonce(widget.id);
      if (mounted) {
        final catProv = context.read<CategoriesProvider>();
        if (catProv.categories.isEmpty) catProv.load();
        setState(() {
          _annonce = annonce;

          // Pré-remplissage étape 1
          // _titreCtrl.text       = annonce.titre;
          _villeCtrl.text       = annonce.ville;
          _quartierCtrl.text    = annonce.quartier;
          _descriptionCtrl.text = annonce.description ?? '';
          _typeTransaction      = annonce.typeTransaction ?? 'location';
          _typeBien             = annonce.typeBien;

          // Pré-remplissage étape 2
          _prixCtrl.text        = annonce.prixAffiche.toString();
          _moisAvanceCtrl.text  = annonce.moisAvance.toString();
          _cautionEauCtrl.text  = annonce.cautionEau.toString();
          _cautionElecCtrl.text = annonce.cautionElec.toString();
          _commissionCtrl.text  = annonce.commissionDemarcheur.toString();
          _dureeLocation        = annonce.dureeLocation ?? 'mois';

          // Pré-remplissage étape 3
          _chambresCtrl.text    = annonce.nbChambres.toString();
          _salonsCtrl.text      = annonce.nbSalons.toString();
          _douchesCtrl.text     = annonce.nbDouches.toString();
          _cuisinesCtrl.text    = annonce.nbCuisines.toString();
          _electriciteType      = annonce.electriciteType;
          _electriciteCompteur  = annonce.electriciteCompteur;
          _eauType              = annonce.eauType;

          _standing = annonce.standing;
          _dimensionCtrl.text = annonce.dimension?.toStringAsFixed(0) ?? '0';

          // Médias existants
          _photosExistantes = List.from(annonce.photos);
          _videosExistantes = List.from(annonce.videos);

          _loadingAnnonce = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingAnnonce = false);
    }
  }

  @override
  void dispose() {
    _dimensionCtrl.dispose(); _villeCtrl.dispose(); _quartierCtrl.dispose();
    _descriptionCtrl.dispose(); _prixCtrl.dispose(); _moisAvanceCtrl.dispose();
    _cautionEauCtrl.dispose(); _cautionElecCtrl.dispose(); _commissionCtrl.dispose();
    _chambresCtrl.dispose(); _salonsCtrl.dispose(); _douchesCtrl.dispose();
    _cuisinesCtrl.dispose();
    super.dispose();
  }

  String? _validateStep() {
    switch (_step) {
      case 0:
        if (_typeBien == null) return 'Le type de bien est requis.';
        if (_villeCtrl.text.trim().isEmpty) return 'La ville est requise.';
        if (_quartierCtrl.text.trim().isEmpty) return 'Le quartier est requis.';
        return null;
      case 1:
        if (_prixCtrl.text.trim().isEmpty) return 'Le loyer/prix est requis.';
        return null;
      case 2:
        if (_afficheDimension) {
          if (_dimensionCtrl.text.trim().isEmpty || (double.tryParse(_dimensionCtrl.text) ?? 0) <= 0) {
            return 'La dimension du terrain est requise.';
          }
        } else {
          if (_electriciteType == null) return 'Le type d\'électricité est requis.';
          if (_eauType == null) return 'Le type d\'eau est requis.';
          if (_supporteStanding && _standing == null) return 'Le standing est requis.';

          if (_champsAutorises.isNotEmpty) {
            final total = (int.tryParse(_chambresCtrl.text) ?? 0) ; 
                          // (int.tryParse(_salonsCtrl.text) ?? 0) +
                          // (int.tryParse(_douchesCtrl.text) ?? 0) +
                          // (int.tryParse(_cuisinesCtrl.text) ?? 0);
            if (total < 1) return 'Au moins une chambre est requise.';
          }
        }
        return null;
      case 3:
        final totalMedias = _photosExistantes.length + _videosExistantes.length + _nouveauxMedias.length;
        if (totalMedias == 0) return 'Ajoutez au moins un média.';
        final videos = _videosExistantes.length + _nouveauxMedias.where((f) {
          final ext = f.path.split('.').last.toLowerCase();
          return ['mp4', 'webm', 'mov'].contains(ext);
        }).length;
        if (videos > 3) return 'Maximum 3 vidéos.';
        if (totalMedias > 10) return 'Maximum 10 médias au total.';
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

  Future<void> _pickMedias() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () async {
                Navigator.pop(context);
                final files = await _picker.pickMultiImage();
                if (files.isNotEmpty) setState(() => _nouveauxMedias.addAll(files));
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Choisir une vidéo'),
              onTap: () async {
                Navigator.pop(context);
                final file = await _picker.pickVideo(source: ImageSource.gallery);
                if (file != null) setState(() => _nouveauxMedias.add(file));
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () async {
                Navigator.pop(context);
                final file = await _picker.pickImage(source: ImageSource.camera);
                if (file != null) setState(() => _nouveauxMedias.add(file));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final err = _validateStep();
    if (err != null) { setState(() => _error = err); return; }
    setState(() { _submitting = true; _error = null; });

    try {
      final isTerrain  = _typeBien == 'Terrain';
      
      final nbPieces = (int.tryParse(_chambresCtrl.text) ?? 0) +
                       (int.tryParse(_salonsCtrl.text) ?? 0) +
                       (int.tryParse(_douchesCtrl.text) ?? 0) +
                       (int.tryParse(_cuisinesCtrl.text) ?? 0);

      final formData = FormData();

      formData.fields.addAll([
        MapEntry('typeTransaction',      _typeTransaction),
        MapEntry('typeBien',             _typeBien!),
        MapEntry('ville',                _villeCtrl.text.trim()),
        MapEntry('quartier',             _quartierCtrl.text.trim()),
        MapEntry('description',          _descriptionCtrl.text.trim()),
        if (_typeTransaction == 'location')
          MapEntry('loyer', _prixCtrl.text.trim())
        else
          MapEntry('prix', _prixCtrl.text.trim()),
        MapEntry('dureeLocation',        _dureeLocation),
        MapEntry('moisAvance',           _moisAvanceCtrl.text.trim() != '' ? _moisAvanceCtrl.text.trim() : '0'),
        MapEntry('cautionEau',           isTerrain || _cautionEauCtrl.text.trim() == '' ? '0' : _cautionEauCtrl.text.trim()),
        MapEntry('cautionElec',          isTerrain || _cautionElecCtrl.text.trim() == '' ? '0' : _cautionElecCtrl.text.trim()),
        MapEntry('commissionDemarcheur',  _typeTransaction == 'vente' || _commissionCtrl.text.trim() == '' ? '0' : _commissionCtrl.text.trim()),

        if (_champsAutorises.contains('nbChambres')) MapEntry('nbChambres', _chambresCtrl.text.trim()),
        if (_champsAutorises.contains('nbSalons'))   MapEntry('nbSalons',   _salonsCtrl.text.trim() == '' ? '0' : _salonsCtrl.text.trim()),
        if (_champsAutorises.contains('nbDouches'))  MapEntry('nbDouches',  _douchesCtrl.text.trim() == '' ? '0' : _douchesCtrl.text.trim()),
        if (_champsAutorises.contains('nbCuisines')) MapEntry('nbCuisines', _cuisinesCtrl.text.trim() == '' ? '0' : _cuisinesCtrl.text.trim()),
        if (_electriciteType != null)     MapEntry('electriciteType', _electriciteType!),
        if (_electriciteCompteur != null) MapEntry('electriciteCompteur', _electriciteCompteur!),
        if (_eauType != null)             MapEntry('eauType', _eauType!),
        if (_supporteStanding && _standing != null) MapEntry('standing', _standing!),
        if (_afficheDimension) MapEntry('dimension', _dimensionCtrl.text.trim()),
      ]);

      // Médias existants conservés
      for (final p in _photosExistantes) {
        formData.fields.add(MapEntry('photosExistantes', p));
      }
      for (final v in _videosExistantes) {
        formData.fields.add(MapEntry('videosExistantes', v));
      }

      // Nouveaux médias
      for (final file in _nouveauxMedias) {
        formData.files.add(MapEntry(
          'medias',
          await MultipartFile.fromFile(file.path, filename: file.name),
        ));
      }

      await DioClient.instance.put('/annonces/${widget.id}', data: formData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonce mise à jour !'), backgroundColor: kActiveGreen),
        );
        context.pop();
      }
    } catch (e) {
      String msg = 'Erreur lors de la mise à jour.';
      try {
        final data = (e as dynamic).response?.data;
        if (data is Map) msg = data['error'] ?? msg;
      } catch (_) {}
      if (mounted) setState(() { _error = msg; _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingAnnonce) {
      return const Scaffold(
        backgroundColor: kWhite,
        body: Center(child: CircularProgressIndicator(color: kGold)),
      );
    }

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kNavBar,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new, color: kWhite, size: 20),
        ),
        title: const Text('Modifier l\'annonce', style: TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(
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
    final suggProv = context.read<SuggestionsProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'Informations générales'),
        const SizedBox(height: 20),
        // _Field(label: 'Titre de l\'annonce *', ctrl: _titreCtrl, hint: 'Ex: Beau studio meublé à Fidjrossè'),
        // const SizedBox(height: 16),
        Text('Type de transaction *', style: AppText.label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _ToggleBtn(icon: Icons.vpn_key, label: 'À louer', selected: _typeTransaction == 'location', onTap: () => setState(() => _typeTransaction = 'location'))),
            const SizedBox(width: 10),
            Expanded(child: _ToggleBtn(icon: Icons.swap_horiz, label: 'À vendre', selected: _typeTransaction == 'vente', onTap: () => setState(() => _typeTransaction = 'vente'))),
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
              items: catProv.categories
                  .map((c) => DropdownMenuItem(value: c.value, child: Text(c.label)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _typeBien = v;
                  final cat = catProv.byValue(v ?? '');
                  if (cat != null && cat.venteParDefaut) {
                    _typeTransaction = 'vente';
                  }
                });
              },
            );
          },
        ),
        const SizedBox(height: 16),
        AutocompleteField(label: 'Ville / Commune *', controller: _villeCtrl, hint: 'Cotonou, Abomey-Calavi...', suggestions: suggProv.villes, icon: Icons.location_city_outlined),
        const SizedBox(height: 16),
        AutocompleteField(label: 'Quartier / Village *', controller: _quartierCtrl, hint: 'Fidjrossè, Akpakpa...', suggestions: suggProv.quartiers, icon: Icons.place_outlined),
        const SizedBox(height: 16),
        Text('Description (facultatif)', style: AppText.label),
        const SizedBox(height: 8),
        TextFormField(controller: _descriptionCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Décrivez votre bien...')),
      ],
    );
  }

  Widget _buildEtape2() {
    final isLocation = _typeTransaction == 'location';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'Informations financières'),
        const SizedBox(height: 20),
        Text(isLocation ? 'Loyer *' : 'Prix *', style: AppText.label),
        const SizedBox(height: 8),
        TextFormField(
          controller: _prixCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '50 000', suffixText: 'FCFA'),
        ),
        if (isLocation) ...[
          const SizedBox(height: 16),
          Text('Durée *', style: AppText.label),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _dureeLocation,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.schedule, size: 18)),
            items: _dureesLocationEdit.map((d) => DropdownMenuItem(value: d['value'], child: Text(d['label']!))).toList(),
            onChanged: (v) => setState(() => _dureeLocation = v!),
          ),
          const SizedBox(height: 16),
          _Field(label: 'Mois d\'avance', ctrl: _moisAvanceCtrl, type: TextInputType.number),
          const SizedBox(height: 16),
          _Field(label: 'Caution eau (FCFA)', ctrl: _cautionEauCtrl, type: TextInputType.number),
          const SizedBox(height: 16),
          _Field(label: 'Caution électricité (FCFA)', ctrl: _cautionElecCtrl, type: TextInputType.number),
          const SizedBox(height: 16),
          _Field(label: 'Commission démarcheur (FCFA)', ctrl: _commissionCtrl, type: TextInputType.number),
        ],
      ],
    );
  }

  Widget _buildEtape3() {
    final champs = _champsAutorises;
    final isTerrain = _afficheDimension;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(label: 'Caractéristiques'),
        const SizedBox(height: 20),

        if (isTerrain) ...[
          _Field(
            label: 'Dimension (m²) *',
            ctrl: _dimensionCtrl,
            type: TextInputType.number,
            hint: '345',
            onChanged: (_) => setState(() {}),
          ),
        ] else ...[
          if (champs.contains('nbChambres')) ...[
            _Field(label: 'Chambres *', ctrl: _chambresCtrl, type: TextInputType.number, hint: '0', onChanged: (_) => setState(() {})),
            const SizedBox(height: 16),
          ],
          if (champs.contains('nbSalons')) ...[
            _Field(label: 'Salons', ctrl: _salonsCtrl, type: TextInputType.number, hint: '0', onChanged: (_) => setState(() {})),
            const SizedBox(height: 16),
          ],
          if (champs.contains('nbDouches')) ...[
            _Field(label: 'Douches', ctrl: _douchesCtrl, type: TextInputType.number, hint: '0'),
            const SizedBox(height: 16),
          ],
          if (champs.contains('nbCuisines')) ...[
            _Field(label: 'Cuisines', ctrl: _cuisinesCtrl, type: TextInputType.number, hint: '0'),
            const SizedBox(height: 16),
          ],

          if (_supporteStanding) ...[
            Text('Standing *', style: AppText.label),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _standing,
              hint: const Text('Choisir...'),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.star_outline, size: 18)),
              items: const [
                DropdownMenuItem(value: 'sanitaire', child: Text('Sanitaire')),
                DropdownMenuItem(value: 'semi-sanitaire', child: Text('Semi-sanitaire')),
                DropdownMenuItem(value: 'ordinaire', child: Text('Ordinaire')),
              ],
              onChanged: (v) => setState(() => _standing = v),
            ),
            const SizedBox(height: 16),
          ],

          Text('Électricité *', style: AppText.label),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _electriciteType,
            hint: const Text('Choisir...'),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.bolt, size: 18)),
            items: const [
              DropdownMenuItem(value: 'personnel', child: Text('Personnel')),
              DropdownMenuItem(value: 'commun',    child: Text('Commun')),
            ],
            onChanged: (v) => setState(() => _electriciteType = v),
          ),
          const SizedBox(height: 16),

          Text('Type de compteur *', style: AppText.label),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _electriciteCompteur,
            hint: const Text('Choisir...'),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.electric_meter, size: 18)),
            items: const [
              DropdownMenuItem(value: 'standard', child: Text('Standard')),
              DropdownMenuItem(value: 'carte',    child: Text('Carte')),
            ],
            onChanged: (v) => setState(() => _electriciteCompteur = v),
          ),
          const SizedBox(height: 16),

          Text('Eau *', style: AppText.label),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _eauType,
            hint: const Text('Choisir...'),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.water_drop, size: 18)),
            items: const [
              DropdownMenuItem(value: 'personnel', child: Text('Personnel')),
              DropdownMenuItem(value: 'commun',    child: Text('Commun')),
            ],
            onChanged: (v) => setState(() => _eauType = v),
          ),
        ],

        const SizedBox(height: 24),
        Text('Titre généré', style: AppText.label),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: kGreyLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kGreyBorder),
          ),
          child: Text(
            _titreGenere.isEmpty ? '—' : _titreGenere,
            style: AppText.bodyBold.copyWith(color: kDark),
          ),
        ),
      ],
    );
  }

  Widget _buildEtape4() {
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api/v1', '');
    final totalMedias = _photosExistantes.length + _videosExistantes.length + _nouveauxMedias.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: 'Photos et vidéos'),
        const SizedBox(height: 8),
        Text('Au moins 1 média · Max 10 au total · Max 3 vidéos', style: AppText.bodySmall),
        const SizedBox(height: 20),

        GestureDetector(
          onTap: _pickMedias,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: kGreyLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kGreyBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload_outlined, size: 36, color: kGrey),
                const SizedBox(height: 8),
                Text('Ajouter des médias', style: AppText.bodyBold),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('$totalMedias média${totalMedias > 1 ? "s" : ""} au total', style: AppText.bodySmall),
        const SizedBox(height: 12),

        // Vidéos existantes
        if (_videosExistantes.isNotEmpty) ...[
          Text('Vidéos existantes', style: AppText.labelGold),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: _videosExistantes.length,
            itemBuilder: (_, i) => Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(color: kDark, child: const Center(child: Icon(Icons.play_circle_fill, color: kGold, size: 32))),
                ),
                Positioned(
                  top: 4, right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _videosExistantes.removeAt(i)),
                    child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle), child: const Icon(Icons.close, color: kWhite, size: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Photos existantes
        if (_photosExistantes.isNotEmpty) ...[
          Text('Photos existantes', style: AppText.labelGold),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: _photosExistantes.length,
            itemBuilder: (_, i) => Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(imageUrl: '$baseUrl${_photosExistantes[i]}', fit: BoxFit.cover, placeholder: (_, __) => Container(color: kGreyLight), errorWidget: (_, __, ___) => Container(color: kGreyLight)),
                ),
                Positioned(
                  top: 4, right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _photosExistantes.removeAt(i)),
                    child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle), child: const Icon(Icons.close, color: kWhite, size: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Nouveaux médias
        if (_nouveauxMedias.isNotEmpty) ...[
          Text('Nouveaux médias', style: AppText.labelGold),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: _nouveauxMedias.length,
            itemBuilder: (_, i) {
              final file    = _nouveauxMedias[i];
              final isVideo = ['mp4', 'webm', 'mov'].contains(file.path.split('.').last.toLowerCase());
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isVideo
                        ? Container(color: kDark, child: const Center(child: Icon(Icons.play_circle_fill, color: kGold, size: 32)))
                        : Image.file(File(file.path), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _nouveauxMedias.removeAt(i)),
                      child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle), child: const Icon(Icons.close, color: kWhite, size: 12)),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
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
            GoldButton(label: 'Mettre à jour', icon: Icons.check, loading: _submitting, onPressed: _submit),
          const SizedBox(height: 10),
          GoldButton.ghost(label: '× Annuler', onPressed: () => context.pop()),
        ],
      ),
    );
  }
}

// ─── Widgets locaux ───────────────────────────────────────────────
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
    final void Function(String)? onChanged;

    const _Field({required this.label, required this.ctrl, this.hint, this.type, this.onChanged});

    @override
    Widget build(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            keyboardType: type,
            onChanged: onChanged,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      );
    }
  }


class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? kBlack : kGrey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? kBlack : kGrey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}