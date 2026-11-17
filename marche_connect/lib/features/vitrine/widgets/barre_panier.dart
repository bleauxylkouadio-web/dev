// =====================================================================
//  barre_panier.dart : gros bouton fixé en bas de la vitrine
//
//   ┌──────────────────────────────────────────┐
//   │ 🛒②  Voir le panier                  1 500 F │
//   └──────────────────────────────────────────┘
//
//  UX-01 : commande en 3 écrans maximum
//    1. Vitrine  →  2. Panier  →  3. Paiement
//  Ce bouton est le passage de l'écran 1 à l'écran 2.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../panier/panier_provider.dart';

class BarrePanier extends StatelessWidget {
  const BarrePanier({super.key, required this.panier});

  final Panier panier;

  @override
  Widget build(BuildContext context) {
    final n = panier.nombreLignes;

    // SafeArea : évite la barre de gestes des téléphones récents.
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.surAccent,
          ),
          onPressed: () => context.push(Routes.panier),
          // Sur un petit téléphone (360 px), le texte doit tenir sur une
          // ligne : le nombre de produits va dans une pastille sur l'icône,
          // et « Voir le panier » se raccourcit avec « … » si besoin.
          child: Row(
            children: [
              Badge(
                label: Text('$n'),
                backgroundColor: AppColors.primaireFonce,
                child: const Icon(Icons.shopping_cart),
              ),
              const SizedBox(width: AppSpacing.m),
              const Expanded(
                child: Text('Voir le panier', overflow: TextOverflow.ellipsis),
              ),
              Text(formaterPrix(panier.sousTotal)),
            ],
          ),
        ),
      ),
    );
  }
}
