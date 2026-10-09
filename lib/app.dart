import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:immoroyal/providers/navbar_provider.dart';
import 'package:immoroyal/screens/gestion/gerant/groupe_screen.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/annonces_liste_provider.dart';
import 'providers/annonces_home_provider.dart';
import 'providers/recherches_provider.dart';
import 'providers/categories_stats_provider.dart';
import 'providers/categories_provider.dart';
import 'providers/suggestions_provider.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
// import 'screens/annonces/list_screen.dart';
import 'screens/annonces/details_screen.dart';
import 'screens/annonces/create_screen.dart';
import 'screens/annonces/edit_screen.dart';
// import 'screens/recherches/list_screen.dart';
import 'screens/recherches/details_screen.dart';
import 'screens/recherches/create_screen.dart';
import 'screens/recherches/edit_screen.dart';
import 'screens/messages/conversations_screen.dart';
import 'screens/messages/chat_screen.dart';
import 'screens/profile/dashboard_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/annonces_screen.dart';
import 'screens/profile/recherches_screen.dart';
import 'screens/profile/public_screen.dart';
import 'providers/messages_provider.dart';

import 'screens/gestion/locataire/locataire_onboarding_screen.dart';

import 'providers/gestion_provider.dart';
import 'providers/locataire_provider.dart';

import 'screens/annonces/annonces_hub_screen.dart';
import 'screens/gestion/gestion_shell.dart';

import 'core/network/dio_client.dart';

import 'widgets/common/app_shell.dart';

import 'screens/gestion/gerant/bien_form_screen.dart';
import 'screens/gestion/gerant/bien_detail_screen.dart';

class ImmoRoyalApp extends StatelessWidget {
  const ImmoRoyalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AnnoncesHomeProvider()),
        ChangeNotifierProvider(create: (_) => AnnoncesListeProvider()),
        ChangeNotifierProvider(create: (_) => RecherchesProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesStatsProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => SuggestionsProvider()),
        ChangeNotifierProvider(create: (_) => NavBarProvider()),
        ChangeNotifierProvider(create: (_) => MessagesProvider()),
        ChangeNotifierProxyProvider<AuthProvider, GestionProvider>(
          create: (_) => GestionProvider(),
          update: (_, auth, prev) => (prev ?? GestionProvider())..syncAuth(auth.isAuthenticated),
        ),
        ChangeNotifierProxyProvider<AuthProvider, LocataireProvider>(
          create: (_) => LocataireProvider(),
          update: (_, auth, prev) => (prev ?? LocataireProvider())..syncAuth(auth.isAuthenticated),
        ),
      ],
      child: _AppRoot(),
    );
  }


}

Page<void> _buildPage(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeIn).animate(animation),
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

class _AppRoot extends StatefulWidget {
  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();

    // Ici context est dans l'arbre Provider — ça fonctionne
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().setMessagesProvider(
        context.read<MessagesProvider>(),
      );
    });
  }


   GoRouter _buildRouter() {
    return GoRouter(
      navigatorKey: DioClient.navigatorKey,
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash',   pageBuilder: (ctx, s) => _buildPage(ctx, s, const SplashScreen())),
        GoRoute(path: '/login',    pageBuilder: (ctx, s) => _buildPage(ctx, s, const LoginScreen())),
        GoRoute(path: '/register', pageBuilder: (ctx, s) => _buildPage(ctx, s, const RegisterScreen())),

        // Routes hors shell (pas de BottomNav)
        GoRoute(path: '/annonces/creer',          pageBuilder: (ctx, s) => _buildPage(ctx, s, const CreateAnnonceScreen())),
        GoRoute(path: '/annonces/:id',            pageBuilder: (ctx, s) => _buildPage(ctx, s, AnnonceDetailsScreen(id: s.pathParameters['id']!))),
        GoRoute(path: '/annonces/:id/modifier',   pageBuilder: (ctx, s) => _buildPage(ctx, s, EditAnnonceScreen(id: s.pathParameters['id']!))),
        GoRoute(path: '/recherches/creer',        pageBuilder: (ctx, s) => _buildPage(ctx, s, const CreateRechercheScreen())),
        GoRoute(path: '/recherches/:id/modifier', pageBuilder: (ctx, s) => _buildPage(ctx, s, EditRechercheScreen(id: s.pathParameters['id']!))),
        GoRoute(path: '/recherches/:id',          pageBuilder: (ctx, s) => _buildPage(ctx, s, RechercheDetailsScreen(id: s.pathParameters['id']!))),
        GoRoute(path: '/messages/:conversationId',    pageBuilder: (ctx, s) => _buildPage(ctx, s, ChatScreen(conversationId: s.pathParameters['conversationId']!))),
        GoRoute(path: '/messages/annonce/:annonceId', pageBuilder: (ctx, s) => _buildPage(ctx, s, StartConversationScreen(annonceId: s.pathParameters['annonceId']!))),
        GoRoute(path: '/profil/modifier',         pageBuilder: (ctx, s) => _buildPage(ctx, s, const EditProfileScreen())),
        GoRoute(path: '/profil/annonces',         pageBuilder: (ctx, s) => _buildPage(ctx, s, const ProfileAnnoncesScreen())),
        GoRoute(path: '/profil/recherches',       pageBuilder: (ctx, s) => _buildPage(ctx, s, const ProfileRecherchesScreen())),
        GoRoute(path: '/profil/public/:id',       pageBuilder: (ctx, s) => _buildPage(ctx, s, ProfilePublicScreen(id: s.pathParameters['id']!))),
        GoRoute(path: '/recherches', redirect: (_, __) => '/annonces?tab=recherches'),
        GoRoute(path: '/gestion/locataire/onboarding', pageBuilder: (ctx, s) => _buildPage(ctx, s, const LocataireOnboardingScreen())),
        GoRoute(path: '/gestion/biens/creer',         pageBuilder: (ctx, s) => _buildPage(ctx, s, BienFormScreen(groupeId: s.uri.queryParameters['groupeId']))),
        GoRoute(path: '/gestion/biens/:id/modifier',  pageBuilder: (ctx, s) => _buildPage(ctx, s, BienFormScreen(bienId: s.pathParameters['id']))),
        GoRoute(path: '/gestion/biens/:id',           pageBuilder: (ctx, s) => _buildPage(ctx, s, BienDetailScreen(bienId: s.pathParameters['id']!))),        
        GoRoute(
          path: '/gestion/groupes/:groupeId',
          builder: (_, s) => GroupeScreen(groupeId: s.pathParameters['groupeId']!),
        ),

        // Shell avec BottomNav
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/home', pageBuilder: (ctx, s) => _buildPage(ctx, s, const HomeScreen())),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/annonces', pageBuilder: (ctx, s) => _buildPage(ctx, s,
                AnnoncesHubScreen(initialTab: s.uri.queryParameters['tab'] == 'recherches' ? 1 : 0))),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/gestion', pageBuilder: (ctx, s) => _buildPage(ctx, s, const GestionShell())),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/messages', pageBuilder: (ctx, s) => _buildPage(ctx, s, const ConversationsScreen())),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/profil', pageBuilder: (ctx, s) => _buildPage(ctx, s, const ProfileDashboardScreen())),
            ]),
          ],
        )
      ],
    );
  }
 

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ImmoRoyal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}