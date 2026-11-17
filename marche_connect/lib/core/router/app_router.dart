// =====================================================================
//  app_router.dart : le ROUTEUR de l'application (go_router)
//
//  Il associe chaque adresse (routes.dart) à un écran, et applique les
//  règles d'accès (redirection.dart) avant chaque changement de page.
//
//  Il est fourni par Riverpod pour pouvoir écouter la session :
//  dès qu'on se connecte ou se déconnecte, les règles sont recalculées
//  et l'utilisateur est redirigé si besoin.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/tableau_de_bord_screen.dart';
import '../../features/auth/connexion_screen.dart';
import '../../features/auth/session_provider.dart';
import '../../features/commande/mes_commandes_screen.dart';
import '../../features/commande/ticket_screen.dart';
import '../../features/commercant/ajout_produit_screen.dart';
import '../../features/commercant/espace_commercant_screen.dart';
import '../../features/commercant/mode_assiste_screen.dart';
import '../../features/livreur/missions_screen.dart';
import '../../features/livreur/scan_screen.dart';
import '../../features/paiement/paiement_screen.dart';
import '../../features/panier/panier_screen.dart';
import '../../features/vitrine/liste_etals_screen.dart';
import '../../features/vitrine/vitrine_etal_screen.dart';
import 'client_shell.dart';
import 'redirection.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // go_router ne connaît pas Riverpod. On fait le pont avec un
  // ValueNotifier : à chaque changement de session, on l'incrémente,
  // et go_router (qui l'écoute via refreshListenable) relance `redirect`.
  final changementSession = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => changementSession.value++);
  ref.onDispose(changementSession.dispose);

  return GoRouter(
    // Première page : la liste des étals (consultation sans compte, UX-01).
    initialLocation: Routes.etals,
    refreshListenable: changementSession,

    // Appelé avant CHAQUE navigation : voir redirection.dart.
    redirect: (context, state) =>
        calculerRedirection(ref.read(sessionProvider), state.uri),

    // Page affichée pour une adresse inconnue (ex. vieux QR, faute de frappe).
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page introuvable')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.go(Routes.etals),
          child: const Text("Retour à l'accueil"),
        ),
      ),
    ),

    routes: [
      // ---------------- Écrans client AVEC la barre du bas ----------------
      ShellRoute(
        builder: (context, state, child) => ClientShell(child: child),
        routes: [
          GoRoute(
            path: Routes.etals,
            builder: (context, state) => const ListeEtalsScreen(),
          ),
          GoRoute(
            path: Routes.panier,
            builder: (context, state) => const PanierScreen(),
          ),
          GoRoute(
            path: Routes.mesCommandes,
            builder: (context, state) => const MesCommandesScreen(),
          ),
        ],
      ),

      // ---------------- Écrans plein écran (avec bouton retour) ----------------
      GoRoute(
        path: Routes.connexion,
        builder: (context, state) => const ConnexionScreen(),
      ),
      GoRoute(
        path: Routes.etalModele, // /etal/:id
        // `:id` dans l'adresse → state.pathParameters['id'].
        builder: (context, state) =>
            VitrineEtalScreen(etalId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.paiement,
        builder: (context, state) => const PaiementScreen(),
      ),
      GoRoute(
        path: Routes.ticketModele, // /ticket/:id
        builder: (context, state) =>
            TicketScreen(commandeId: state.pathParameters['id']!),
      ),

      // ---------------- Espaces par rôle ----------------
      GoRoute(
        path: Routes.commercant,
        builder: (context, state) => const EspaceCommercantScreen(),
      ),
      // Placés après /commercant : même règle d'accès (redirection.dart
      // protège /commercant et toutes ses sous-pages).
      GoRoute(
        path: Routes.commercantAssiste,
        builder: (context, state) => const ModeAssisteScreen(),
      ),
      GoRoute(
        path: Routes.commercantNouveauProduit,
        builder: (context, state) => const AjoutProduitScreen(),
      ),
      GoRoute(
        path: Routes.livreur,
        builder: (context, state) => const MissionsScreen(),
      ),
      GoRoute(
        path: Routes.livreurScan,
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: Routes.admin,
        builder: (context, state) => const TableauDeBordScreen(),
      ),
    ],
  );
});
