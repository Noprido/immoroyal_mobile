import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:immoroyal/providers/navbar_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/api_constants.dart';
import '../../models/annonce.dart';
import '../../providers/annonces_home_provider.dart';
import '../../providers/annonces_liste_provider.dart';
import '../../providers/recherches_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/categories_stats_provider.dart';
import '../../providers/suggestions_provider.dart';
import '../../widgets/recherches/recherche_card.dart';
import '../../core/utils/guard_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../core/utils/search_matcher.dart';
import '../../core/utils/local_slang_resolver.dart';
import '../../core/utils/text_normalize.dart';
import 'dart:async';

bool _firstFrameDone = false;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollCtrl = ScrollController();
  Timer? _metricsDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchFocus.addListener(_onFocusChange);
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.isScrollingNotifier.value) {
        FocusScope.of(context).unfocus();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _firstFrameDone = true);
      context.read<AnnoncesHomeProvider>().load();
      context.read<RecherchesProvider>().load();
      context.read<CategoriesProvider>().load();
      context.read<CategoriesStatsProvider>().load();
      context.read<SuggestionsProvider>().load();
    });
  }

  // Source unique de vérité pour hide/show de la navbar
  void _onFocusChange() {
    // debugPrint('[FOCUS] hasFocus=${_searchFocus.hasFocus}');
    if (_searchFocus.hasFocus) {
      context.read<NavBarProvider>().hide();
    } else {
      context.read<NavBarProvider>().show();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _metricsDebounce?.cancel();
    _scrollCtrl.dispose();
    _searchFocus.removeListener(_onFocusChange);
    _searchFocus.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  double? _lastRawBottom;
  bool _closingHandled = false;

  @override
  void didChangeMetrics() {
    final rawBottom = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;

    if (_searchFocus.hasFocus &&
        _lastRawBottom != null &&
        rawBottom < _lastRawBottom! &&
        !_closingHandled) {
      // Le clavier commence à se refermer (bouton retour, geste, etc.)
      _closingHandled = true;
      _searchFocus.unfocus(); // déclenche _onFocusChange -> show() immédiatement
    }

    if (rawBottom == 0) {
      _closingHandled = false; // reset pour la prochaine ouverture/fermeture
    }

    _lastRawBottom = rawBottom;
  }
  
  
  void _search() {
    final texte = _searchCtrl.text.trim();
    final filtresProv = context.read<AnnoncesListeProvider>();

    if (texte.isEmpty) {
      filtresProv.clearFiltres();
      context.go('/annonces');
      return;
    }

    final suggProv = context.read<SuggestionsProvider>();
    final catProv = context.read<CategoriesProvider>();

    final slang = LocalSlangResolver().resolve(texte);

    final matcher = SearchMatcher.build(
      villes: suggProv.villes,
      quartiers: suggProv.quartiers,
      categories: catProv.categories.map((c) => c.value).toList(),
    );
    final texteAMatcher = slang.texteRestant.isEmpty ? texte : slang.texteRestant;
    final result = matcher.match(texteAMatcher);

    final typeBienFinal = slang.typeBien ?? result.typeBien;

    final rienDetecte = typeBienFinal == null &&
        result.ville == null && result.quartier == null &&
        slang.nbChambres == null && slang.standing == null &&
        (result.q == null || result.q!.isEmpty);

    if (rienDetecte) {
      filtresProv.rechercherTexte(q: texte);
    } else {
      filtresProv.rechercherTexte(
        ville: result.ville,
        quartier: result.quartier,
        typeBien: typeBienFinal,
        nbChambres: slang.nbChambres,
        nbSalons: slang.nbSalons,
        standing: slang.standing,
        q: result.q,
      );
    }

    context.go('/annonces');
  }
  
  void _selectCat(String typeBien) {
    context.read<AnnoncesListeProvider>().setFiltres(typeBien: typeBien);
    context.go('/annonces'); // ou context.push si tu veux garder le bouton retour
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: !_firstFrameDone
          ? const CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: SizedBox.shrink(),
                ),
              ],
            )
          : Consumer<AnnoncesHomeProvider>(
              builder: (_, prov, __) {
                return GestureDetector(
                  onTap: () {
                    // debugPrint('[TAP] screen tapped, unfocusing');
                    FocusScope.of(context).unfocus();
                  },
                  // onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.opaque,
                  child: RefreshIndicator(
                    color: kGold,
                    onRefresh: () async {
                      await Future.wait([
                        context.read<AnnoncesHomeProvider>().load(silent: true),
                        context.read<RecherchesProvider>().load(),
                        context.read<CategoriesProvider>().load(silent: true),
                        context.read<CategoriesStatsProvider>().load(),
                        context.read<SuggestionsProvider>().load(),
                      ]);
                    },
                    child: CustomScrollView(
                      controller: _scrollCtrl,
                      slivers: [
                        _buildAppBar(),
                        SliverToBoxAdapter(child: _buildSearchBar()),
                        if (prov.loading) ...[
                          SliverToBoxAdapter(child: _buildCategories()),
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: HomeSkeleton(),
                          ),
                        ] else ...[
                          SliverToBoxAdapter(child: _buildCategories()),
                          SliverToBoxAdapter(child: _buildEnAvant()),
                          SliverToBoxAdapter(child: _buildDernieres()),
                          SliverToBoxAdapter(child: _buildRecherches()),
                          SliverToBoxAdapter(child: _buildToutesAnnonces()),
                          SliverToBoxAdapter(child: SizedBox(height: 100 + MediaQuery.of(context).padding.bottom)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),     
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 80 + MediaQuery.of(context).padding.bottom),
        child: FloatingActionButton(
          onPressed: () { if (guardAuth(context)) context.push('/annonces/creer'); },
          backgroundColor: kGold,
          foregroundColor: kBlack,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── AppBar ──
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: kNavBar,
      pinned: true,
      elevation: 0,
      toolbarHeight: 56,
      title: Image.asset('assets/images/IMMOROYAL_4_1.png', height: 45, fit: BoxFit.contain),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: kWhite),
          onPressed: () {},
        ),
      ],
    );
  }

  // ── Barre de recherche ──
Widget _buildSearchBar() {
  final suggProv = context.watch<SuggestionsProvider>();
  final catProv = context.watch<CategoriesProvider>();

  List<_SearchSuggestion> toutesSuggestions() {
    final list = <_SearchSuggestion>[];
    for (final v in suggProv.villes) {
      list.add(_SearchSuggestion(label: v, type: _SuggestionType.ville, icon: Icons.location_city_outlined));
    }
    for (final q in suggProv.quartiers) {
      list.add(_SearchSuggestion(label: q, type: _SuggestionType.quartier, icon: Icons.place_outlined));
    }
    for (final c in catProv.categories) {
      list.add(_SearchSuggestion(label: c.value, type: _SuggestionType.typeBien, icon: c.icon));
    }
    return list;
  }

  List<_SearchSuggestion> filtrer(String texte) {
    final q = normalize(texte);
    if (q.isEmpty) return const [];
    final source = toutesSuggestions();

    final matches = source.where((s) => normalize(s.label).contains(q)).toList();
    matches.sort((a, b) {
      final aStarts = normalize(a.label).startsWith(q) ? 0 : 1;
      final bStarts = normalize(b.label).startsWith(q) ? 0 : 1;
      if (aStarts != bStarts) return aStarts - bStarts;
      return a.label.length - b.label.length;
    });
    return matches.take(8).toList();
  }

  Widget _highlighted(String text, String query) {
    final normText = normalize(text);
    final normQuery = normalize(query);
    final idx = normText.indexOf(normQuery);
    if (idx == -1 || query.isEmpty) {
      return Text(text, style: AppText.bodySmall.copyWith(color: kBlack));
    }

    return RichText(
      text: TextSpan(
        style: AppText.bodySmall.copyWith(color: kBlack),
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: const TextStyle(fontWeight: FontWeight.w700, color: kGoldDark),
          ),
          TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }

  return Container(
    color: kNavBar,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    child: Row(
      children: [
        Expanded(
          child: RawAutocomplete<_SearchSuggestion>(
            textEditingController: _searchCtrl,
            focusNode: _searchFocus,
            displayStringForOption: (s) => s.label,
            optionsBuilder: (value) => filtrer(value.text),
            onSelected: (s) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _search());
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
              return Container(
                height: 48,
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(Icons.search, color: Color(0xFF888888), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onSubmitted: (_) => _search(),
                        style: GoogleFonts.dmSans(color: kGrey, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ville, quartier, type de bien...',
                          hintStyle: GoogleFonts.dmSans(color: const Color(0xFF666666), fontSize: 14),
                          border: InputBorder.none,
                          fillColor: Colors.transparent,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 260,
                      maxWidth: MediaQuery.of(context).size.width - 32 - 58, // 58 ≈ largeur bouton flèche + espacement
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, i) {
                        final option = options.elementAt(i);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Icon(option.icon, size: 16, color: kGrey),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _highlighted(option.label, _searchCtrl.text),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _search,
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_forward, color: kBlack, size: 22),
          ),
        ),
      ],
    ),
  );
}

  // ── Catégories cercles horizontaux (dynamiques, plus de focus) ──
Widget _buildCategories() {
  return Consumer2<CategoriesProvider, CategoriesStatsProvider>(
    builder: (_, catProv, statsProv, __) {
      if (catProv.loading && catProv.categories.isEmpty) {
        return const SizedBox(height: 116);
      }
      if (catProv.categories.isEmpty) return const SizedBox.shrink();

      return Container(
        color: kWhite,
        padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
        child: SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: catProv.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) {
              final cat = catProv.categories[i];
              final count = statsProv.counts[cat.value];
              return GestureDetector(
                onTap: () => _selectCat(cat.value),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            shape: BoxShape.circle,
                            border: Border.all(color: kGold, width: 1.5),
                          ),
                          child: Icon(cat.icon, color: kDark, size: 26),
                        ),
                        if (count != null && count > 0)
                          Positioned(
                            top: -4, right: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: kGoldDark,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: kWhite, width: 1.5),
                              ),
                              constraints: const BoxConstraints(minWidth: 18),
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: kWhite, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.label,
                      style: AppText.cardMeta.copyWith(color: kGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      
      );
    },
  );
}

  // ── En avant — scroll horizontal ──
  Widget _buildEnAvant() {
    return Consumer<AnnoncesHomeProvider>(
      builder: (_, prov, __) {
        final enAvant = prov.annonces.where((a) => a.enAvant).toList();
        if (enAvant.isEmpty) return const SizedBox.shrink();
        return Container(
          color: const Color(0xFFF5F5F5),
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('En vedette', style: AppText.sectionTitle),
                    GestureDetector(onTap: () => context.go('/annonces'), child: Text('Voir tout', style: AppText.labelGold)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: enAvant.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, i) => _CardEnAvant(annonce: enAvant[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Dernières annonces — liste verticale ──
  Widget _buildDernieres() {
    final annonces = context.read<AnnoncesHomeProvider>().annonces.where((a) => !a.enAvant).take(6).toList();
    if (annonces.isEmpty) return const SizedBox.shrink();
    return Container(
      color: kWhite,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dernières annonces', style: AppText.sectionTitle),
              GestureDetector(onTap: () => context.go('/annonces'), child: Text('Voir tout', style: AppText.labelGold)),
            ],
          ),
          const SizedBox(height: 14),
          ...annonces.map((a) => _CardVerticale(annonce: a)),
        ],
      ),
    );
  }

  // ── Je cherche ──
  Widget _buildRecherches() {
    return Consumer<RecherchesProvider>(
      builder: (_, prov, __) {
        if (prov.loading || prov.recherches.isEmpty) return const SizedBox.shrink();
        return Container(
          color: const Color(0xFFF5F5F5),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Je cherche', style: AppText.sectionTitle),
                  GestureDetector(onTap: () => context.go('/recherches'), child: Text('Voir tout', style: AppText.labelGold)),
                ],
              ),
              const SizedBox(height: 14),
              ...prov.recherches.take(3).map((r) => RechercheCard(recherche: r)),
            ],
          ),
        );
      },
    );
  }
}

Widget _buildToutesAnnonces() {
  return Consumer<AnnoncesHomeProvider>(
    builder: (_, prov, __) {
      final nonVedettes = prov.annonces.where((a) => !a.enAvant).toList();
      final reste = nonVedettes.skip(6).toList();
      if (reste.isEmpty) return const SizedBox.shrink();

      return Container(
        color: const Color(0xFFF5F5F5),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toutes les annonces', style: AppText.sectionTitle),
            const SizedBox(height: 14),
            Builder(
              builder: (context) {
                final rows = <Widget>[];
                for (int i = 0; i < reste.length; i += 2) {
                  rows.add(
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _CardGrille(annonce: reste[i])),
                        const SizedBox(width: 12),
                        i + 1 < reste.length
                            ? Expanded(child: _CardGrille(annonce: reste[i + 1]))
                            : const Expanded(child: SizedBox()),
                      ],
                    ),
                  );
                  rows.add(const SizedBox(height: 12));
                }
                if (prov.hasMore) {
                  rows.add(
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(color: kGold, strokeWidth: 2),
                      ),
                    ),
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) => prov.loadMore());
                }
                return Column(children: rows);
              },
            ),
          ],
        ),
      );
    },
  );
}

// ── Card En vedette (horizontale) ──
class _CardEnAvant extends StatelessWidget {
  final AnnonceModel annonce;
  const _CardEnAvant({required this.annonce});

  @override
  Widget build(BuildContext context) {
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api/v1', '');
    final thumb = annonce.thumbnail;
    return GestureDetector(
      onTap: () => context.push('/annonces/${annonce.id}'),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 120, width: double.infinity,
                    child: thumb != null
                        ? CachedNetworkImage(imageUrl: '$baseUrl$thumb', fit: BoxFit.cover, placeholder: (_, __) => Container(color: kGreyLight), errorWidget: (_, __, ___) => Container(color: kGreyLight))
                        : Container(color: kGreyLight, child: const Icon(Icons.image_outlined, color: kGrey)),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kGold.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Color.fromARGB(255, 255, 215, 85),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'En vedette',
                            style: AppText.badge.copyWith(color: kWhite),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (annonce.hasVideo)
                    const Positioned(top: 8, right: 8, child: Icon(Icons.play_circle_fill, color: kWhite, size: 26)),

                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: annonce.isLocation
                          ? kGreen.withValues(alpha: 0.85)
                          : kRed.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            annonce.isLocation ? Icons.vpn_key : Icons.swap_horiz,
                            color: kWhite,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            annonce.isLocation ? 'À louer' : 'À vendre',
                            style: const TextStyle(color: kWhite, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(annonce.typeBien, style: AppText.cardMeta),
                  const SizedBox(height: 2),
                  Text(annonce.titre, style: AppText.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on, size: 11, color: kGrey),
                    const SizedBox(width: 2),
                    Expanded(child: Text(annonce.ville, style: AppText.cardMeta, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 6),
                  Text(AppFormatters.fcfa(annonce.prixAffiche), style: AppText.price.copyWith(fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// card des annonces restantes
class _CardGrille extends StatelessWidget {
  final AnnonceModel annonce;
  const _CardGrille({required this.annonce});

  @override
  Widget build(BuildContext context) {
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api/v1', '');
    final thumb = annonce.thumbnail;

    return GestureDetector(
      onTap: () => context.push('/annonces/${annonce.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 120, width: double.infinity,
                    child: thumb != null
                        ? CachedNetworkImage(imageUrl: '$baseUrl$thumb', fit: BoxFit.cover, placeholder: (_, __) => Container(color: kGreyLight), errorWidget: (_, __, ___) => Container(color: kGreyLight))
                        : Container(color: kGreyLight, child: const Icon(Icons.image_outlined, color: kGrey)),
                  ),
                  Positioned(
                    bottom: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: annonce.isLocation ? kGreen.withValues(alpha: 0.85) : kRed.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            Icon(
                              annonce.isLocation ? Icons.vpn_key : Icons.swap_horiz,
                              color: kWhite,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              annonce.isLocation ? 'À louer' : 'À vendre',
                              style: const TextStyle(color: kWhite, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                    ),
                  ),
                  if (annonce.hasVideo)
                    const Positioned(top: 8, right: 8, child: Icon(Icons.play_circle_fill, color: kWhite, size: 24)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(annonce.typeBien, style: AppText.cardMeta),
                  const SizedBox(height: 2),
                  Text(annonce.titre, style: AppText.cardTitle.copyWith(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on, size: 11, color: kGrey),
                    const SizedBox(width: 2),
                    Expanded(child: Text(annonce.ville, style: AppText.cardMeta.copyWith(fontSize: 11), overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 4),
                  Text(AppFormatters.fcfa(annonce.prixAffiche), style: AppText.price.copyWith(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card verticale (image gauche + infos droite) ──
class _CardVerticale extends StatelessWidget {
  final AnnonceModel annonce;
  const _CardVerticale({required this.annonce});

  @override
  Widget build(BuildContext context) {
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api/v1', '');
    final thumb = annonce.thumbnail;
    return GestureDetector(
      onTap: () => context.push('/annonces/${annonce.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: SizedBox(
          height: 125,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                child: SizedBox(
                  width: 110,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      thumb != null
                          ? CachedNetworkImage(
                              imageUrl: '$baseUrl$thumb',
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: kGreyLight),
                              errorWidget: (_, __, ___) => Container(color: kGreyLight),
                            )
                          : Container(color: kGreyLight, child: const Icon(Icons.image_outlined, color: kGrey)),
                      Positioned(
                        bottom: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: annonce.isLocation ? kGreen.withValues(alpha: 0.85) : kRed.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(annonce.isLocation ? Icons.vpn_key : Icons.swap_horiz, color: kWhite, size: 11),
                              const SizedBox(width: 4),
                              Text(annonce.isLocation ? 'À louer' : 'À vendre', style: const TextStyle(color: kWhite, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      if (annonce.hasVideo)
                        const Positioned(bottom: 6, right: 6, child: Icon(Icons.play_circle_fill, color: kWhite, size: 22)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(annonce.typeBien, style: AppText.cardMeta),
                      const SizedBox(height: 3),
                      Text(annonce.titre, style: AppText.cardTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on, size: 11, color: kGrey),
                        const SizedBox(width: 2),
                        Expanded(child: Text('${annonce.quartier}, ${annonce.ville}', style: AppText.cardMeta, overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 6),
                      Text(AppFormatters.fcfa(annonce.prixAffiche), style: AppText.price.copyWith(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SuggestionType { ville, quartier, typeBien }

class _SearchSuggestion {
  final String label;
  final _SuggestionType type;
  final IconData icon;
  const _SearchSuggestion({required this.label, required this.type, required this.icon});
}