import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/constants/app_config.dart';
import 'app.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'services/push_notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await initializeDateFormatting('fr_FR', null);

  // Firebase (pas besoin de FirebaseOptions ici : lu automatiquement
  // depuis google-services.json sur Android)
  await Firebase.initializeApp();
  await PushNotificationsService.init();

  // Initialisation Hive (uniquement si persistance active)
  if (AppConfig.persistanceActive) {
    await Hive.initFlutter();
    await Hive.openBox(AppConfig.hiveBoxAnnonces);
    await Hive.openBox(AppConfig.hiveBoxConversations);
    await Hive.openBox(AppConfig.hiveBoxProfil);
    await Hive.openBox(AppConfig.hiveBoxRecherches);
    await Hive.openBox(AppConfig.hiveBoxCategories);
  }

  FlutterNativeSplash.remove();
  runApp(const ImmoRoyalApp());
}