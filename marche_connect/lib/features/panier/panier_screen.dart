// =====================================================================
//  panier_screen.dart : ÉCRAN 2/3 du parcours de commande — le PANIER
//
//  Maquette « Panier et paiement » (diapositive 14) :
//    Mon panier
//    Tomates x2 ........................ 1 000 F
//    Livraison ........................... 500 F
//    Total ............................. 1 500 F
//
//  UX-01 : Vitrine (1) → Panier (2) → Paiement (3).
//  ACH-03 : frais et délai de livraison affichés AVANT validation.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../vitrine/vitrine_providers.dart';
import 'options_livraison.dart';
import 'panier_provider.dart';
import 'widgets/choix_livraison.dart';
import 'widgets/ligne_panier.dart';
import 'widgets/recapitulatif.dart';

/// Stateful : on retient si le client a déjà essayé de continuer
/// (pour n'afficher l'erreur d'adresse qu'à ce moment-là).
class PanierScreen extends ConsumerStatefulWidget {
  const PanierScreen({super.key});

  @override
  ConsumerState<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends ConsumerState<PanierScreen> {
  bool _essaiDeValidation = false;

  void _continuer() {
    final options = ref.read(optionsLivraisonProvider);
    if (options.erreur != null) {
      setState(() => _essaiDeValidation = true);
      return;
    }
    // Si le client n'est pas connecté, le routeur l'enverra d'abord sur
    // la connexion, puis le ramènera ici (règle 2 de redirection.dart).
    context.push(Routes.paiement);
  }

  Future<void> _confirmerVider() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier ?'),
        content: const Text('Tous les produits seront retirés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Vider')),
        ],
      ),
    );
    if (ok == true) ref.read(panierProvider.notifier).vider();
  }

  @override
  Widget build(BuildContext context) {
    final panier = ref.watch(panierProvider);
    final actions = ref.read(panierProvider.notifier);
    final options = ref.watch(optionsLivraisonProvider);
    final textes = Theme.of(context).textTheme;

    // ---------- Panier vide ----------
    if (panier.estVide) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon panier')),
        body: EtatVide(
          titre: 'Votre panier est vide',
          message: 'Choisissez un étal et ajoutez des produits.',
          icone: Icons.shopping_cart_outlined,
          libelleAction: 'Voir les étals',
          onAction: () => context.go(Routes.etals),
        ),
      );
    }

    // Commune de l'étal, pour le libellé de la zone de livraison.
    final etal = ref.watch(etalProvider(panier.etalId!)).value;
    final total = panier.sousTotal + options.frais;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon panier'),
        actions: [
          IconButton(
            tooltip: 'Vider le panier',
            icon: const Icon(Icons.remove_shopping_cart),
            onPressed: _confirmerVider,
          ),
        ],
      ),
      // Bouton fixé en bas : toujours visible, même en faisant défiler.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: FilledButton(
            style: AppTheme.boutonOrange,
            onPressed: _continuer,
            child: Text('Continuer · ${formaterPrix(total)}'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          // ---------- Étal (appui → retour à la vitrine) ----------
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.storefront, color: AppColors.primaire),
            title: Text(panier.nomEtal ?? '', style: textes.titleMedium),
            subtitle: const Text('Ajouter d\'autres produits'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.etal(panier.etalId!)),
          ),
          const SizedBox(height: AppSpacing.s),

          // ---------- Lignes ----------
          for (final ligne in panier.lignes) ...[
            LignePanier(
              // key : aide Flutter à suivre chaque ligne quand on en retire une.
              key: ValueKey(ligne.produitId),
              ligne: ligne,
              onQuantite: (q) => actions.changerQuantite(ligne.produitId, q),
              onRetirer: () => actions.retirer(ligne.produitId),
            ),
            const SizedBox(height: AppSpacing.s),
          ],
          const SizedBox(height: AppSpacing.m),

          // ---------- Retrait ou livraison ----------
          ChoixLivraison(
            communeEtal: etal?.commune,
            afficherErreur: _essaiDeValidation,
          ),
          const SizedBox(height: AppSpacing.m),

          // ---------- Totaux ----------
          Recapitulatif(
            sousTotal: panier.sousTotal,
            fraisLivraison: options.frais,
            avecLivraison: options.mode == ModeLivraison.livraison,
          ),
        ],
      ),
    );
  }
}
