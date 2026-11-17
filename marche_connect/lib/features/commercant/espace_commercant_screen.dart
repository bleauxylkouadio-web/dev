// =====================================================================
//  espace_commercant_screen.dart : ESPACE COMMERÇANT (3 onglets)
//
//  Maquette « Espace commerçant » (diapositive 14) :
//    Mes produits
//    Pagnes wax      Dispo
//    Savon karité    Épuisé
//    + Photo et prix
//    3 nouvelles commandes
//
//   ┌ Étal de Mariam                        [⎋] ┐
//   │  (contenu de l'onglet)                    │
//   │                       [+ Commande assistée]│ ← bouton flottant
//   ├───────────────────────────────────────────┤
//   │ 🧾 Commandes ③   🧺 Produits   🏪 Mon étal  │
//   └───────────────────────────────────────────┘
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../auth/session_provider.dart';
import 'commercant_providers.dart';
import 'onglets/commandes_recues_onglet.dart';
import 'onglets/mes_produits_onglet.dart';
import 'onglets/mon_etal_onglet.dart';

class EspaceCommercantScreen extends ConsumerStatefulWidget {
  const EspaceCommercantScreen({super.key});

  @override
  ConsumerState<EspaceCommercantScreen> createState() => _EspaceCommercantScreenState();
}

class _EspaceCommercantScreenState extends ConsumerState<EspaceCommercantScreen> {
  int _onglet = 0; // 0 = Commandes, 1 = Produits, 2 = Mon étal

  @override
  Widget build(BuildContext context) {
    final etal = ref.watch(monEtalProvider);
    final nbEnAttente = ref.watch(nbCommandesEnAttenteProvider);

    // Compte sans étal (ex. administrateur qui visite l'espace).
    if (ref.watch(monEtalIdProvider) == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Espace commerçant')),
        body: const EtatVide(
          titre: 'Aucun étal lié à ce compte',
          message: 'Connectez-vous avec un compte commerçant.',
          icone: Icons.store,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(etal.value?.nom ?? 'Espace commerçant'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(sessionProvider.notifier).deconnecter(),
          ),
        ],
      ),

      // IndexedStack : garde les 3 onglets en mémoire (la position de
      // défilement est conservée quand on passe de l'un à l'autre).
      body: IndexedStack(
        index: _onglet,
        children: const [
          CommandesRecuesOnglet(),
          MesProduitsOnglet(),
          MonEtalOnglet(),
        ],
      ),

      // Bouton flottant : l'action principale de l'onglet affiché.
      floatingActionButton: switch (_onglet) {
        0 => FloatingActionButton.extended(
            onPressed: () => context.push(Routes.commercantAssiste),
            icon: const Icon(Icons.support_agent),
            label: const Text('Commande assistée'),
          ),
        1 => FloatingActionButton.extended(
            onPressed: () => context.push(Routes.commercantNouveauProduit),
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.surAccent,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Photo et prix'),
          ),
        _ => null,
      },

      bottomNavigationBar: NavigationBar(
        selectedIndex: _onglet,
        onDestinationSelected: (i) => setState(() => _onglet = i),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: nbEnAttente > 0,
              label: Text('$nbEnAttente'),
              child: const Icon(Icons.receipt_long),
            ),
            label: 'Commandes',
          ),
          const NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Produits'),
          const NavigationDestination(icon: Icon(Icons.storefront), label: 'Mon étal'),
        ],
      ),
    );
  }
}
