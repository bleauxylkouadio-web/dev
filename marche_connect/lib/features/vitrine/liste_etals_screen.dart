// =====================================================================
//  liste_etals_screen.dart : ACCUEIL CLIENT — les étals du marché
//
//  Module « Vitrine et recherche » : recherche + filtres par commune
//  et catégorie. Consultable SANS compte (UX-01).
//
//   ┌ MARCHÉ_CONNECT                 [Se connecter] ┐
//   │ 🔍 Rechercher…                                │
//   │ [Toutes] [Cocody] [Abobo] …                   │
//   │ [Légumes] [Fruits] …                          │
//   │ 5 étals                                       │
//   │ ┌ Chez Tantie Awa ★ 4,8   [Mis en avant] ┐    │
//   │ ┌ Étal de Mariam ★ 4,6                  ┐    │
//   └───────────────────────────────────────────────┘
// =====================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/providers.dart';
import '../auth/session_provider.dart';
import 'vitrine_providers.dart';
import 'widgets/filtres_etals.dart';

class ListeEtalsScreen extends ConsumerWidget {
  const ListeEtalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(sessionProvider);
    // AsyncValue<List<Etal>> : chargement, erreur ou données.
    final etals = ref.watch(etalsFiltresProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MARCHÉ_CONNECT'),
        actions: [
          // Développement uniquement : simuler une coupure réseau.
          if (kDebugMode) const _BoutonCoupureReseau(),
          if (utilisateur == null)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => context.push(Routes.connexion),
              icon: const Icon(Icons.login),
              label: const Text('Se connecter'),
            )
          else
            IconButton(
              tooltip: 'Se déconnecter (${utilisateur.nom})',
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(sessionProvider.notifier).deconnecter(),
            ),
        ],
      ),
      body: Column(
        children: [
          const BandeauHorsLigne(), // visible seulement sans réseau (UX-03)
          const FiltresEtalsBarre(),
          const Divider(height: 1),
          // Expanded : la liste prend toute la hauteur restante.
          Expanded(
            // RefreshIndicator : tirer la liste vers le bas pour recharger.
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(etalsFiltresProvider.future),
              // .when : un affichage pour chacun des 3 états.
              child: etals.when(
                loading: () => const Chargement(message: 'Recherche des étals…'),
                error: (erreur, _) => MessageErreur(
                  // invalidate : oublie le résultat et relance le chargement.
                  onReessayer: () => ref.invalidate(etalsFiltresProvider),
                ),
                data: (liste) => liste.isEmpty
                    ? EtatVide(
                        titre: 'Aucun étal trouvé',
                        message: 'Essayez une autre commune ou un autre mot.',
                        icone: Icons.search_off,
                        libelleAction: 'Effacer les filtres',
                        onAction: () => ref.read(filtresEtalsProvider.notifier).effacer(),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        // +1 : la première ligne est le compteur « 5 étals ».
                        itemCount: liste.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Text(
                              '${liste.length} étal${liste.length > 1 ? 's' : ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.texteSecondaire),
                            );
                          }
                          final etal = liste[index - 1];
                          return CarteEtal(
                            etal: etal,
                            // push : la vitrine s'ouvre AU-DESSUS (bouton retour).
                            onTap: () => context.push(Routes.etal(etal.id)),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// (Développement) Bouton 📶 qui coupe / rétablit le réseau SIMULÉ,
/// pour tester le mode hors ligne sans débrancher le Wi-Fi.
class _BoutonCoupureReseau extends ConsumerStatefulWidget {
  const _BoutonCoupureReseau();

  @override
  ConsumerState<_BoutonCoupureReseau> createState() => _BoutonCoupureReseauState();
}

class _BoutonCoupureReseauState extends ConsumerState<_BoutonCoupureReseau> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(mockDatabaseProvider);
    return IconButton(
      tooltip: db.reseauCoupe ? 'Rétablir le réseau (démo)' : 'Couper le réseau (démo)',
      icon: Icon(db.reseauCoupe ? Icons.wifi_off : Icons.wifi),
      onPressed: () {
        setState(() => db.reseauCoupe = !db.reseauCoupe);
        ref.invalidate(etalsFiltresProvider); // recharge la liste
      },
    );
  }
}
