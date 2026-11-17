// =====================================================================
//  paiement_screen.dart : ÉCRAN 3/3 du parcours de commande — PAYER
//
//  Maquette « Panier et paiement » :
//    Payer avec  [Wave] [Orange] [MTN] [Moov]
//    [ Payer 1 500 F ]
//
//  Accessible seulement connecté (règle 2 de redirection.dart).
//  Après le paiement, on REMPLACE la pile de pages par le ticket
//  (context.go) : le bouton retour ne ramène pas à un panier vide.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../auth/session_provider.dart';
import '../panier/options_livraison.dart';
import '../panier/panier_provider.dart';
import '../panier/widgets/recapitulatif.dart';
import 'paiement_controller.dart';
import 'widgets/choix_moyen_paiement.dart';

class PaiementScreen extends ConsumerWidget {
  const PaiementScreen({super.key});

  Future<void> _payer(BuildContext context, WidgetRef ref) async {
    final commande = await ref.read(paiementControllerProvider.notifier).payer();
    if (commande != null && context.mounted) {
      context.go(Routes.ticket(commande.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panier = ref.watch(panierProvider);
    final options = ref.watch(optionsLivraisonProvider);
    final etat = ref.watch(paiementControllerProvider);
    final client = ref.watch(sessionProvider);
    final textes = Theme.of(context).textTheme;
    final avecLivraison = options.mode == ModeLivraison.livraison;
    final total = panier.sousTotal + options.frais;

    // Arrivé ici avec un panier vide (ex. adresse tapée à la main).
    if (panier.estVide) {
      return Scaffold(
        appBar: AppBar(title: const Text('Paiement')),
        body: EtatVide(
          titre: 'Rien à payer',
          message: 'Votre panier est vide.',
          icone: Icons.shopping_cart_outlined,
          libelleAction: 'Voir les étals',
          onAction: () => context.go(Routes.etals),
        ),
      );
    }

    final libelleBouton = etat.moyen.estMobileMoney
        ? 'Payer ${formaterPrix(total)}'
        : 'Commander · ${formaterPrix(total)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.surAccent,
            ),
            onPressed: etat.enCours ? null : () => _payer(context, ref),
            child: etat.enCours
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 3)),
                      SizedBox(width: AppSpacing.m),
                      Flexible(child: Text('Validez sur votre téléphone…', overflow: TextOverflow.ellipsis)),
                    ],
                  )
                : Text(libelleBouton),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          // ---------- Résumé ----------
          Text(panier.nomEtal ?? '', style: textes.titleLarge),
          Text(
            avecLivraison
                ? 'Livraison : ${options.adresse.trim()}'
                : "Retrait à l'étal",
            style: textes.bodyMedium?.copyWith(color: AppColors.texteSecondaire),
          ),
          const SizedBox(height: AppSpacing.m),
          Recapitulatif(
            sousTotal: panier.sousTotal,
            fraisLivraison: options.frais,
            avecLivraison: avecLivraison,
          ),
          const SizedBox(height: AppSpacing.l),

          // ---------- Erreur ----------
          if (etat.erreur != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.erreurClair,
                borderRadius: BorderRadius.circular(AppRadius.moyen),
              ),
              child: Text(
                etat.erreur!,
                style: const TextStyle(color: AppColors.erreur, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
          ],

          // ---------- Moyens de paiement ----------
          Text('Payer avec', style: textes.titleMedium),
          const SizedBox(height: AppSpacing.s),
          ChoixMoyenPaiement(
            choisi: etat.moyen,
            avecLivraison: avecLivraison,
            actif: !etat.enCours,
            onChoisir: ref.read(paiementControllerProvider.notifier).choisirMoyen,
          ),

          // ---------- Numéro débité ----------
          if (etat.moyen.estMobileMoney && client != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s),
              child: Text(
                'Demande envoyée au ${formaterTelephone(client.telephone)}',
                style: textes.bodySmall,
              ),
            ),
          const SizedBox(height: AppSpacing.l),

          // ---------- Confiance (ACH-05) ----------
          const Row(
            children: [
              Icon(Icons.lock, size: 18, color: AppColors.succes),
              SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  'Paiement sécurisé par un agrégateur agréé. '
                  'Aucun code secret ni donnée bancaire n\'est conservé.',
                  style: TextStyle(fontSize: 14, color: AppColors.texteSecondaire),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
