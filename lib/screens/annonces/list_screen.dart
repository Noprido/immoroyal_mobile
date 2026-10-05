import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/annonces_liste_provider.dart';
import '../../widgets/annonces/annonce_card.dart';
import '../../widgets/common/loading_shimmer.dart';
// import '../../widgets/common/app_navbar.dart';
import '../../core/utils/guard_auth.dart';
import '../../providers/categories_provider.dart';
import '../../providers/suggestions_provider.dart';
import '../../widgets/common/autocomplete_field.dart';
import 'package:immoroyal/providers/navbar_provider.dart';

// const _typesBiens = [
//   'Appartement meublé', 'Appartement vide', 'Maison',
//   'Terrain', 'Boutique', 'Magasin', 'Bureau', 'Entrée personnelle', 'Chambre',
// ];

class AnnoncesListScreen extends StatefulWidget {
  const AnnoncesListScreen({super.key});
  @override
  State<AnnoncesListScreen> createState() => _AnnoncesListScreenState();
}

class _AnnoncesListScreenState extends State<AnnoncesListScreen> {

  late final NavBarProvider _navBarProvider; // ⬅️ NOUVEAU

  @override
  void initState() {
    super.initState();
    _navBarProvider = context.read<NavBarProvider>(); // ⬅️ NOUVEAU, capturé tôt

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AnnoncesListeProvider>().load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navBarProvider.show();
    });
    super.dispose();
  }

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
      //   title: Image.asset(
      //     'assets/images/IMMOROYAL_4_1.png',
      //     height: 50,
      //     fit: BoxFit.contain,
      //   ),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.tune, color: kWhite),
      //       onPressed: _showFiltres,
      //       tooltip: 'Filtres',
      //     ),
      //   ],
      // ),
      body: Consumer<AnnoncesListeProvider>(
        builder: (_, prov, __) {
          return Column(
            children: [
              // Barre filtres actifs
              if (prov.filtreVille != null || prov.filtreTypeBien != null || prov.filtreTypeTransaction != null)
                _FiltresActifsBar(prov: prov),

              // Compteur
              Container(
                color: kWhite,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                width: double.infinity,
                child: Text(
                  prov.loading ? 'Chargement...' : '${prov.annonces.length} annonce${prov.annonces.length > 1 ? "s" : ""}',
                  style: AppText.bodySmall,
                ),
              ),

              // Liste
              Expanded(
                child: prov.loading
                    ? const AnnonceListSkeleton()
                    : prov.annonces.isEmpty
                        ? _EmptyState()
                        : RefreshIndicator(
                            color: kGold,
                            onRefresh: () => prov.load(),
                            child: NotificationListener<ScrollEndNotification>(
                              onNotification: (notification) {
                                if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
                                  context.read<AnnoncesListeProvider>().loadMore();
                                }
                                return false;
                              },
                              child: ListView.builder(
                                // plus de controller ici
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                                itemCount: prov.annonces.length + (prov.loadingMore ? 1 : 0),
                                itemBuilder: (_, i) {
                                if (i == prov.annonces.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator(color: kGold, strokeWidth: 2)),
                                  );
                                }
                                return AnnonceCard(annonce: prov.annonces[i]);
                              },
                              ),
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 80 + MediaQuery.of(context).padding.bottom),
        child: FloatingActionButton(
          heroTag: null,
          onPressed: () { if (guardAuth(context)) context.push('/annonces/creer'); },
          backgroundColor: kGold,
          foregroundColor: kBlack,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

void showAnnoncesFiltres(BuildContext context) {
  context.read<NavBarProvider>().hide();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kWhite,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _FiltresSheet(),
  );
}

class _FiltresActifsBar extends StatelessWidget {
  final AnnoncesListeProvider prov;
  const _FiltresActifsBar({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kGoldBg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 16, color: kGoldDark),
          const SizedBox(width: 6),
          Expanded(
            child: Wrap(
              spacing: 6,
              children: [
                if (prov.filtreVille != null) _Chip(label: prov.filtreVille!),
                if (prov.filtreTypeBien != null) _Chip(label: prov.filtreTypeBien!),
                if (prov.filtreTypeTransaction != null) _Chip(label: prov.filtreTypeTransaction == 'location' ? 'Location' : 'Vente'),
                if (prov.filtreQ != null) _Chip(label: '🔍 ${prov.filtreQ!}'),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => {
              context.read<NavBarProvider>().show(),
              prov.clearFiltres()
            },
            child: Text('Effacer', style: AppText.labelGold.copyWith(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: kGold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: kGold.withOpacity(0.4))),
      child: Text(label, style: const TextStyle(fontSize: 12, color: kGoldDark, fontWeight: FontWeight.w500)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 64, color: kGreyBorder),
          const SizedBox(height: 16),
          Text('Aucune annonce trouvée', style: AppText.sectionTitle.copyWith(color: kGrey)),
          const SizedBox(height: 8),
          Text('Essayez de modifier vos filtres', style: AppText.bodySmall),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.read<AnnoncesListeProvider>().clearFiltres(),
            child: Text('Effacer les filtres', style: AppText.labelGold),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom sheet filtres ─────────────────────────────────────────
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

    final prov = context.read<AnnoncesListeProvider>();
    _villeCtrl.text = prov.filtreVille ?? '';
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

  void _appliquer() {
    // _navBarProvider.show();
    context.read<AnnoncesListeProvider>().setFiltres(
      ville:           _villeCtrl.text.trim().isEmpty ? null : _villeCtrl.text.trim(),
      typeBien:        _typeBien,
      typeTransaction: _typeTransaction,
    );
    Navigator.pop(context);
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filtrer les annonces', style: AppText.sectionTitle),
              GestureDetector(
                onTap: () {
                  // context.read<NavBarProvider>().show();
                  Navigator.pop(context);
                },
                child: const Icon(Icons.close, color: kGrey),
              ),
            ],
          ),
          const SizedBox(height: 20),

          AutocompleteField(label: 'Ville / Quartier', controller: _villeCtrl, hint: 'Cotonou, Fidjrossè...', suggestions: suggProv.villesEtQuartiers, icon: Icons.location_on_outlined),
          const SizedBox(height: 16),

          Text('Type de transaction', style: AppText.label),
          const SizedBox(height: 8),
          Row(
            children: [
              _ToggleBtn(label: 'À louer', value: 'location', selected: _typeTransaction, onTap: (v) => setState(() => _typeTransaction = _typeTransaction == v ? null : v)),
              const SizedBox(width: 10),
              _ToggleBtn(label: 'À vendre', value: 'vente', selected: _typeTransaction, onTap: (v) => setState(() => _typeTransaction = _typeTransaction == v ? null : v)),
            ],
          ),
          const SizedBox(height: 16),

          Text('Type de bien', style: AppText.label),
          const SizedBox(height: 8),
          Consumer<CategoriesProvider>(
            builder: (_, catProv, __) {
              return DropdownButtonFormField<String>(
                initialValue: _typeBien,
                hint: const Text('Tous les types'),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.home_work_outlined, size: 18)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tous les types')),
                  ...catProv.categories.map((c) => DropdownMenuItem(value: c.value, child: Text(c.label))),
                ],
                onChanged: (v) => setState(() => _typeBien = v),
              );
            },
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() { _villeCtrl.clear(); _typeBien = null; _typeTransaction = null; });
                    context.read<AnnoncesListeProvider>().clearFiltres();
                    // context.read<NavBarProvider>().show();
                    Navigator.pop(context);
                  },
                  child: const Text('Effacer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _appliquer,
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label, value;
  final String? selected;
  final void Function(String) onTap;

  const _ToggleBtn({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kGold : kWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? kGold : kGreyBorder),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? kBlack : kGrey, fontSize: 14)),
      ),
    );
  }
}
