# ImmoRoyal Mobile — Flutter

Application mobile Android/iOS pour ImmoRoyal, la plateforme immobilière du Bénin.

## Stack
- Flutter 3.x / Dart 3.x
- State management : Provider
- Navigation : GoRouter
- HTTP : Dio (avec intercepteur JWT)
- Stockage sécurisé : flutter_secure_storage

## Structure livrée (Phase 1 — Base)

```
lib/
├── main.dart                        ✅ Point d'entrée
├── app.dart                         ✅ GoRouter + providers
├── core/
│   ├── theme/
│   │   ├── colors.dart              ✅ Palette or/noir/blanc
│   │   ├── text_styles.dart         ✅ Typographie (Playfair + Inter)
│   │   └── theme.dart               ✅ ThemeData complet
│   ├── constants/api_constants.dart ✅ URLs, clés, limites
│   ├── network/dio_client.dart      ✅ Dio + intercepteur JWT
│   └── utils/formatters.dart        ✅ FCFA, dates, prix
├── models/
│   ├── user.dart                    ✅
│   ├── annonce.dart                 ✅
│   ├── recherche.dart               ✅
│   └── message.dart                 ✅ (+ ConversationModel)
├── services/
│   └── auth_service.dart            ✅
├── providers/
│   └── auth_provider.dart           ✅
├── screens/
│   ├── splash/splash_screen.dart    ✅ Animation + vérification JWT
│   ├── auth/login_screen.dart       ✅ Formulaire complet
│   ├── auth/register_screen.dart    ✅ Formulaire complet
│   ├── home/home_screen.dart        ✅ Structure (sections Phase 3)
│   └── [autres]                     🔲 Stubs (Phase 3 & 4)
└── widgets/
    ├── common/
    │   ├── gold_button.dart          ✅ Filled / Outlined / Ghost
    │   ├── app_shell.dart            ✅ BottomNavigationBar 5 tabs
    │   ├── app_navbar.dart           ✅ AppBar + SliverAppBar
    │   └── loading_shimmer.dart      ✅ Skeleton cards
    └── annonces/
        └── annonce_card.dart         ✅ Card complète avec actions
```

## Démarrage

### 1. Cloner et installer les dépendances
```bash
flutter pub get
```

### 2. Configurer l'URL de l'API
Créer un fichier `.env` à la racine :
```
API_BASE_URL=http://192.168.1.100:3000/api/v1
```
Ou passer la variable à la compilation :
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000/api/v1
```

### 3. Lancer sur Android
```bash
flutter run -d android
```

## Phases de développement

| Phase | Contenu | Status |
|-------|---------|--------|
| **Phase 1** | Backend API Node.js `/api/v1` + JWT | 🔲 À faire côté Node.js |
| **Phase 2** | Base Flutter (thème, nav, auth, modèles) | ✅ **Livré** |
| **Phase 3** | Écrans principaux (home, listes, détails) | 🔲 Prochain |
| **Phase 4** | Création, messagerie, profil | 🔲 |
| **Phase 5** | Notifications push, polish, tests | 🔲 |

## Décisions design

### Fidélité au web
- Même palette exacte (kGold `#D4AF37`, kNavBar `#1A1A1A`)
- Boutons full-width avec coins arrondis 8px (identique au web)
- Badge statut coloré (Actif/Inactif/Suspendu)
- Logo IMMO(blanc) + ROYAL(or)

### Adaptations natives
- `BottomNavigationBar` noire avec icône active dorée (remplace le burger)
- `SliverAppBar` qui colle au défilement
- Animations de transition entre pages
- `shimmer` skeleton loading au lieu de spinner
- `SafeArea` sur tous les écrans
- `HapticFeedback` sur les actions importantes (à brancher)
- `photo_view` pinch-to-zoom pour la galerie (Phase 3)
- Chewie pour la vidéo en plein écran paysage (Phase 3)
