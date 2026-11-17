// =====================================================================
//  vitrine_etal_screen.dart : VITRINE D'UN ÉTAL
//
//  ⭐ Écran ouvert par le scan du QR plastifié de l'étal (/etal/:id),
//  sans installation ni compte (parcours QR, diapositive 7).
//
//  Maquette « Vitrine de l'étal » (diapositive 14) :
//    Étal de Mariam · Adjamé
//    Tomates 1 kg    500 F   [+]
//    Piment frais    300 F   Épuisé  (masqué côté client, MAR-01)
//    [ Commander ]   → barre « Voir le panier » en bas
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../panier/panier_provider.dart';
import 'vitrine_providers.dart';
import 'widgets/barre_panier.dart';
import 'widgets/entete_etal.dart';

class VitrineEtalScreen extends ConsumerWidget {
  const VitrineEtalScreen({super.key, required this.etalId});

  /// Identifiant lu dans l'adresse /etal/:id (ex. « e-1 »).
  final String etalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etalAsync = ref.watch(etalProvider(etalId));

    return etalAsync.when(
      loading: () => const Scaffold(body: Chargement()),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: MessageErreur(onReessayer: () => ref.invalidate(etalProvider(etalId))),
      ),
      data: (etal) => etal == null
          // QR abîmé, ancien ou mal recopié.
          ? Scaffold(
              appBar: AppBar(),
              body: EtatVide(
                titre: 'Étal introuvable',
                message: "Ce QR code ne correspond à aucun étal.",
                icone: Icons.qr_code_2,
                libelleAction: 'Voir tous les étals',
                onAction: () => context.go(Routes.etals),
              ),
            )
          : _Vitrine(etal: etal),
    );
  }
}

/// La vitrine une fois l'étal chargé.
class _Vitrine extends ConsumerWidget {
  const _Vitrine({required this.etal});

  final Etal etal;

  /// Ajoute un produit ; si le panier contient un AUTRE étal, demande
  /// d'abord la permission de le vider.
  Future<void> _ajouter(BuildContext context, WidgetRef ref, Produit produit) async {
    final panier = ref.read(panierProvider.notifier);
    final resultat = panier.ajouter(produit, etal);

    if (resultat == ResultatAjout.autreEtal) {
      final ancienEtal = ref.read(panierProvider).nomEtal;
      // showDialog attend la réponse : true (Vider) ou false/null (Annuler).
      final vider = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Vider le panier ?'),
          content: Text(
            'Votre panier contient des produits de « $ancienEtal ».\n'
            'Une commande se fait auprès d\'un seul étal.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Vider et ajouter'),
            ),
          ],
        ),
      );
      if (vider != true) return;
      panier.viderEtAjouter(produit, etal);
    }

    if (!context.mounted) return;
    // Message court en bas de l'écran ; remplace le précédent s'il y en a un.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${produit.nom} ajouté au panier'),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produits = ref.watch(produitsEtalProvider(etal.id));
    final panier = ref.watch(panierProvider);
    final textes = Theme.of(context).textTheme;
    // La barre du bas n'apparaît que pour le panier DE CET ÉTAL.
    final panierDeCetEtal = !panier.estVide && panier.etalId == etal.id;

    return Scaffold(
      appBar: AppBar(title: Text(etal.nom)),
      bottomNavigationBar: panierDeCetEtal ? BarrePanier(panier: panier) : null,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          // Bandeau « Hors ligne » (UX-03), invisible quand le réseau va bien.
          const BandeauHorsLigne(),
          EnteteEtal(etal: etal),
          const SizedBox(height: AppSpacing.l),
          Text('Produits', style: textes.titleLarge),
          const SizedBox(height: AppSpacing.s),

          // ListView dans un ListView : on « déplie » le résultat ici avec
          // `...` plutôt que d'imbriquer deux listes qui défilent.
          ...produits.when(
            loading: () => [const SizedBox(height: 160, child: Chargement())],
            error: (_, _) => [
              MessageErreur(onReessayer: () => ref.invalidate(produitsEtalProvider(etal.id))),
            ],
            data: (liste) => liste.isEmpty
                ? [
                    const EtatVide(
                      titre: 'Aucun produit disponible',
                      message: 'Revenez plus tard ou appelez le commerçant.',
                      icone: Icons.remove_shopping_cart,
                    ),
                  ]
                : [
                    for (final produit in liste) ...[
                      CarteProduit(
                        produit: produit,
                        quantiteDansPanier:
                            panierDeCetEtal ? panier.quantiteDe(produit.id) : 0,
                        // Étal fermé : pas de bouton Ajouter.
                        onAjouter: etal.ouvert ? () => _ajouter(context, ref, produit) : null,
                      ),
                      const SizedBox(height: AppSpacing.s),
                    ],
                  ],
          ),
        ],
      ),
    );
  }
}
