// =====================================================================
//  main.dart : POINT D'ENTRÉE de l'application
//
//  C'est le premier fichier exécuté quand on lance l'application.
//  Il démarre MarcheConnectApp à l'intérieur d'un ProviderScope.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/identite.dart';
import 'data/local/stockage_local.dart';
import 'data/repositories/providers.dart';

/// `main()` est la toute première fonction appelée par Dart.
/// `async` : on attend l'ouverture du stockage local avant d'afficher.
Future<void> main() async {
  // Obligatoire avant tout appel au système (stockage…) fait avant runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // PWA : adresses « propres » dans le navigateur, sans « # ».
  //   avec    : https://marche-connect.ci/etal/e-1
  //   sans    : https://marche-connect.ci/#/etal/e-1
  // Important pour les QR plastifiés : l'adresse imprimée doit être simple.
  // (Sans effet sur Android et iOS.)
  usePathUrlStrategy();

  // MODE HORS LIGNE (étape 15) : ouvre le stockage du téléphone (Hive).
  final stockage = await StockageHive.ouvrir();

  runApp(
    // ProviderScope = le « réservoir » de Riverpod. Tous les providers
    // (session, repositories, routeur…) vivent à l'intérieur.
    // Il doit envelopper TOUTE l'application.
    ProviderScope(
      // On remplace le stockage en mémoire (par défaut) par le vrai.
      overrides: [stockageLocalProvider.overrideWithValue(stockage)],
      child: const MarcheConnectApp(),
    ),
  );
}

/// Le widget « racine » : il enveloppe toute l'application.
///
/// ConsumerWidget = StatelessWidget qui peut lire des providers (`ref`).
class MarcheConnectApp extends ConsumerWidget {
  const MarcheConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `.router` : c'est go_router qui décide quel écran afficher.
    return MaterialApp.router(
      title: 'MARCHÉ_CONNECT',
      debugShowCheckedModeBanner: false,

      // ---------- NAVIGATION (étape 7) ----------
      routerConfig: ref.watch(routerProvider),

      // ---------- THÈME (étape 3) ----------
      theme: AppTheme.clair,

      // ---------- LANGUE FRANÇAISE (UX-02) ----------
      locale: const Locale('fr', 'CI'),
      supportedLocales: const [Locale('fr', 'CI'), Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ---------- IDENTITÉ : bande du drapeau en haut de TOUS les écrans ----------
      // `builder` enveloppe chaque écran. On place :
      //   1. la zone de la barre d'état du téléphone (heure, batterie) en vert ;
      //   2. la bande orange | blanc | vert ;
      //   3. l'écran, sans la marge du haut (déjà occupée par 1 et 2).
      builder: (context, ecran) {
        final margeHaut = MediaQuery.paddingOf(context).top;
        return ColoredBox(
          color: AppColors.fond,
          child: Column(
            children: [
              Container(height: margeHaut, color: AppColors.primaireFonce),
              const BandeDrapeau(),
              Expanded(
                child: MediaQuery.removePadding(context: context, removeTop: true, child: ecran!),
              ),
            ],
          ),
        );
      },
    );
  }
}
