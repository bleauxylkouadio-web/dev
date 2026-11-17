// =====================================================================
//  client_shell.dart : la « coquille » des écrans principaux du client
//
//  Une coquille (shell) est un cadre commun autour de plusieurs écrans.
//  Ici : la barre de navigation du bas, toujours visible sur
//  Étals · Panier · Commandes. Seul le contenu (`child`) change.
//
//  ┌──────────────────────────┐
//  │   écran actuel (child)   │
//  │                          │
//  ├──────────────────────────┤
//  │  🏪 Étals  🛒② Panier  🧾 │  ← NavigationBar (② = nombre de produits)
//  └──────────────────────────┘
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/panier/panier_provider.dart';
import 'routes.dart';

class ClientShell extends ConsumerWidget {
  const ClientShell({super.key, required this.child});

  /// L'écran à afficher au-dessus de la barre.
  final Widget child;

  /// Les onglets, dans l'ordre : (adresse, icône, libellé).
  static const _onglets = [
    (Routes.etals, Icons.storefront, 'Étals'),
    (Routes.panier, Icons.shopping_cart, 'Panier'),
    (Routes.mesCommandes, Icons.receipt_long, 'Commandes'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Adresse actuelle → numéro de l'onglet à surligner.
    final adresse = GoRouterState.of(context).uri.path;
    final index = _onglets.indexWhere((o) => adresse.startsWith(o.$1));
    // .select : ne redessine la barre que si le NOMBRE change.
    final nbPanier = ref.watch(panierProvider.select((p) => p.nombreLignes));

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        // context.go : REMPLACE la page (pas d'empilement entre onglets).
        onDestinationSelected: (i) => context.go(_onglets[i].$1),
        destinations: [
          for (final (route, icone, libelle) in _onglets)
            NavigationDestination(
              // Badge (widget Flutter) : pastille avec le nombre de produits.
              icon: Badge(
                isLabelVisible: route == Routes.panier && nbPanier > 0,
                label: Text('$nbPanier'),
                child: Icon(icone),
              ),
              label: libelle,
            ),
        ],
      ),
    );
  }
}
