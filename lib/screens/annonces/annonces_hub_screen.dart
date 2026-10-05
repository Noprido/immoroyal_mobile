import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../recherches/list_screen.dart';
import 'list_screen.dart';

/// Hôte de l'onglet "Annonces" : deux tabs internes
/// (Annonces / Je cherche). Les deux écrans gardent leur propre
/// Scaffold (FAB, body) mais n'ont plus d'AppBar : c'est ce widget
/// qui fournit l'AppBar, le TabBar et le bouton filtres.
class AnnoncesHubScreen extends StatefulWidget {
  final int initialTab; // 0 = Annonces, 1 = Je cherche
  const AnnoncesHubScreen({super.key, this.initialTab = 0});

  @override
  State<AnnoncesHubScreen> createState() => _AnnoncesHubScreenState();
}

class _AnnoncesHubScreenState extends State<AnnoncesHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;
    _tab = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tab.addListener(() {
      if (_tab.index != _tabIndex) {
        setState(() => _tabIndex = _tab.index);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AnnoncesHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cas : context.go('/recherches') alors que le hub est déjà construit
    if (widget.initialTab != oldWidget.initialTab) {
      _tab.animateTo(widget.initialTab);
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _onFiltres() {
    if (_tabIndex == 0) {
      showAnnoncesFiltres(context);
    } else {
      showRecherchesFiltres(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: kNavBar,
        title: Image.asset(
          'assets/images/IMMOROYAL_4_1.png',
          height: 50,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: kWhite),
            onPressed: _onFiltres,
            tooltip: 'Filtres',
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: kGold,
          unselectedLabelColor: kGrey,
          indicatorColor: kGold,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'Annonces'),
            Tab(text: 'Je cherche'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _KeepAlive(child: AnnoncesListScreen()),
          _KeepAlive(child: RecherchesListScreen()),
        ],
      ),
    );
  }
}

/// Garde chaque tab vivant (scroll + données conservés au swipe).
class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
