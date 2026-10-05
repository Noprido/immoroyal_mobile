import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:immoroyal/providers/messages_provider.dart';
import 'package:immoroyal/providers/navbar_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../core/theme/colors.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _tabs = [
    _TabItem(icon: Icons.home_outlined, label: 'Accueil'),
    _TabItem(icon: Icons.real_estate_agent_outlined, label: 'Annonces'),
    _TabItem(icon: Icons.apartment_outlined, label: 'Gestion'),
    _TabItem(icon: Icons.chat_bubble_outline, label: 'Messages'),
    _TabItem(icon: Icons.person_outline, label: 'Profil'),
  ];

  // Historique des onglets visités, dans l'ordre. Toujours au moins [0].
  late List<int> _tabHistory;
  bool _showRegister = false;

  @override
  void initState() {
    super.initState();
    _tabHistory = [widget.navigationShell.currentIndex];
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se déclenche à CHAQUE changement de branche, peu importe la cause :
    // tap sur GNav, context.go() depuis un écran, goBranch() manuel, etc.
    final newIndex = widget.navigationShell.currentIndex;
    if (_tabHistory.isEmpty || _tabHistory.last != newIndex) {
      _tabHistory.removeWhere((i) => i == newIndex); // évite les doublons/boucles
      _tabHistory.add(newIndex);
    }

    if (newIndex != 2 && newIndex != 3 && newIndex != 4) {
      _showRegister = false;
    }
  }

  void _onTabTap(BuildContext context, int i) {
    widget.navigationShell.goBranch(
      i,
      initialLocation: i == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nonLus = context.watch<MessagesProvider>().nonLus;

    final currentIndex = widget.navigationShell.currentIndex;
    final isProtected = currentIndex == 2 || currentIndex == 3 || currentIndex == 4; // Gestion / Messages / Profil
    final isAuth = context.watch<AuthProvider>().isAuthenticated;

    if (isAuth && _showRegister) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showRegister = false);
      });
    }

    final Widget authScreen = _showRegister
    ? RegisterScreen(
        showBackButton: false,
        onSwitchToLogin: () => setState(() => _showRegister = false),
      )
    : LoginScreen(
        showBackButton: false,
        onSwitchToRegister: () => setState(() => _showRegister = true),
      );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PopScope(
        canPop: _tabHistory.length <= 1,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_tabHistory.length > 1) {
            setState(() => _tabHistory.removeLast());
            final previousIndex = _tabHistory.last;
            context.read<NavBarProvider>().show();
            widget.navigationShell.goBranch(previousIndex);
          }
        },
        child: Stack(
          children: [
             (isProtected && !isAuth) ? authScreen : widget.navigationShell,
            Positioned(
              left: 16, right: 16,
              bottom: 20 + MediaQuery.of(context).padding.bottom,
              child: Consumer<NavBarProvider>(
                builder: (_, navProv, child) {
                  return AnimatedSlide(
                    offset: navProv.visible ? Offset.zero : const Offset(0, 10),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: child!,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: kNavBar,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 4))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: GNav(
                      selectedIndex: widget.navigationShell.currentIndex,
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      onTabChange: (i) => _onTabTap(context, i),
                      backgroundColor: kNavBar,
                      color: const Color(0xFF888888),
                      activeColor: kBlack,
                      tabBackgroundColor: kGold,
                      gap: 6,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      duration: const Duration(milliseconds: 300),
                      tabs: _tabs.asMap().entries.map((entry) {
                        final i = entry.key;
                        final tab = entry.value;
                        final showBadge = i == 3 && nonLus > 0;

                        return GButton(
                          icon: tab.icon,
                          text: tab.label,
                          leading: showBadge
                              ? Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(tab.icon, color: currentIndex == 3 ? kBlack : const Color(0xFF888888)),
                                    Positioned(
                                      right: -6, top: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: Text(
                                          nonLus > 99 ? '99+' : '$nonLus',
                                          style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}