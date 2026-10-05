import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/recherches_provider.dart';
import '../../widgets/recherches/recherche_card.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../core/utils/guard_auth.dart';
import '../../providers/categories_provider.dart';
import '../../providers/suggestions_provider.dart';
import '../../widgets/common/autocomplete_field.dart';
import 'package:immoroyal/providers/navbar_provider.dart';

// const _typesBiens = [
//   'Appartement meublé','Appartement vide','Maison','Terrain',
//   'Boutique','Magasin','Bureau','Chambre','Entrée personnelle','Autre',
// ];

class RecherchesListScreen extends StatefulWidget {
  const RecherchesListScreen({super.key});
  @override
  State<RecherchesListScreen> createState() => _RecherchesListScreenState();
}

class _RecherchesListScreenState extends State<RecherchesListScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<RecherchesProvider>();
      if (prov.recherches.isEmpty) prov.load();
    });
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<RecherchesProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  // void _showFiltres() {
  //   context.read<NavBarProvider>().hide();
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: kWhite,
  //     shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
  //     builder: (_) => _FiltresSheet(),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      // appBar: AppBar(
      //   backgroundColor: kNavBar,
      //   title: RichText(text: const TextSpan(children: [
      //     TextSpan(text: 'Je ', style: TextStyle(color: kWhite, fontSize: 20, fontWeight: FontWeight.w700)),
      //     TextSpan(text: 'cherche', style: TextStyle(color: kGold, fontSize: 20, fontWeight: FontWeight.w700)),
      //   ])),
      //   actions: [
      //     IconButton(icon: const Icon(Icons.tune, color: kWhite), onPressed: _showFiltres),
      //   ],
      // ),
      body: Consumer<RecherchesProvider>(
        builder: (_, prov, __) => Column(
          children: [
            // Compteur
            Container(
              color: kWhite,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              width: double.infinity,
              child: Text(
                prov.loading ? 'Chargement...' : '${prov.recherches.length} recherche${prov.recherches.length > 1 ? "s" : ""}',
                style: AppText.bodySmall,
              ),
            ),
            Expanded(
              child: prov.loading
                  ? const RechercheListSkeleton(count: 3)
                  : prov.recherches.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.search_off, size: 64, color: kGreyBorder),
                          const SizedBox(height: 16),
                          Text('Aucune recherche', style: AppText.sectionTitle.copyWith(color: kGrey)),
                        ]))
                      : RefreshIndicator(
                          color: kGold,
                          onRefresh: () => prov.load(),
                          child: ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(16),
                            itemCount: prov.recherches.length + (prov.loadingMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == prov.recherches.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: kGold, strokeWidth: 2)));
                              return RechercheCard(recherche: prov.recherches[i]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 80 + MediaQuery.of(context).padding.bottom),
        child: FloatingActionButton(
          heroTag: null,
          onPressed: () { if (guardAuth(context)) context.push('/recherches/creer'); },
          backgroundColor: kGold,
          foregroundColor: kBlack,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

void showRecherchesFiltres(BuildContext context) {
  context.read<NavBarProvider>().hide();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kWhite,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _FiltresSheet(),
  );
}

class _FiltresSheet extends StatefulWidget {
  @override
  State<_FiltresSheet> createState() => _FiltresSheetState();
}

class _FiltresSheetState extends State<_FiltresSheet> {
  final _villeCtrl = TextEditingController();
  String? _typeBien;
  String? _typeTransaction;

  late final NavBarProvider _navBarProvider;

  @override
  void initState() {
    super.initState();
    _navBarProvider = context.read<NavBarProvider>();
    final prov = context.read<RecherchesProvider>();
    _villeCtrl.text  = prov.filtreVille ?? '';
    _typeBien        = prov.filtreTypeBien;
    _typeTransaction = prov.filtreTypeTransaction;

    final catProv = context.read<CategoriesProvider>();
    if (catProv.categories.isEmpty) {
      catProv.load();
    }
  }

  @override
  void dispose() {
    _villeCtrl.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navBarProvider.show();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggProv = context.read<SuggestionsProvider>();
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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Filtrer les recherches', style: AppText.sectionTitle),
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: kGrey)),
          ]),
          const SizedBox(height: 20),
          AutocompleteField(label: 'Ville', controller: _villeCtrl, hint: 'Cotonou...', suggestions: suggProv.villesEtQuartiers, icon: Icons.location_on_outlined),
          const SizedBox(height: 16),
          Text('Type de transaction', style: AppText.label),
          const SizedBox(height: 8),
          Row(children: [
            _Btn('Location', 'location', _typeTransaction, (v) => setState(() => _typeTransaction = _typeTransaction == v ? null : v)),
            const SizedBox(width: 10),
            _Btn('Achat', 'achat', _typeTransaction, (v) => setState(() => _typeTransaction = _typeTransaction == v ? null : v)),
          ]),
          const SizedBox(height: 16),
          Text('Type de bien', style: AppText.label),
          const SizedBox(height: 8),
          Consumer<CategoriesProvider>(
            builder: (_, catProv, __) {
              return DropdownButtonFormField<String>(
                initialValue: _typeBien,
                hint: const Text('Tous'),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.home_work_outlined, size: 18)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tous')),
                  ...catProv.categories.map((c) => DropdownMenuItem(value: c.value, child: Text(c.label))),
                  const DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                ],
                onChanged: (v) => setState(() => _typeBien = v),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () { context.read<RecherchesProvider>().setFiltres(); Navigator.pop(context); }, child: const Text('Effacer'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: () {
              context.read<RecherchesProvider>().setFiltres(
                ville: _villeCtrl.text.trim().isEmpty ? null : _villeCtrl.text.trim(),
                typeBien: _typeBien, typeTransaction: _typeTransaction,
              );
              Navigator.pop(context);
            }, child: const Text('Appliquer'))),
          ]),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label, value;
  final String? selected;
  final void Function(String) onTap;
  const _Btn(this.label, this.value, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) {
    final sel = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: sel ? kGold : kWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: sel ? kGold : kGreyBorder)),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: sel ? kBlack : kGrey, fontSize: 14)),
      ),
    );
  }
}
