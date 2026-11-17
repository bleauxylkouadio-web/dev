// =====================================================================
//  recapitulatif.dart : le bloc « Sous-total / Livraison / Total »
//
//  Utilisé dans le Panier ET dans le Paiement : le client voit le même
//  montant aux deux endroits (ACH-03 : frais affichés avant validation).
//
//    Produits             1 000 F
//    Livraison              500 F
//    ─────────────────────────────
//    Total                1 500 F
// =====================================================================

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/formatters.dart';

class Recapitulatif extends StatelessWidget {
  const Recapitulatif({
    super.key,
    required this.sousTotal,
    required this.fraisLivraison,
    required this.avecLivraison,
  });

  final int sousTotal;
  final int fraisLivraison;

  /// Faux pour un retrait : la ligne affiche « Retrait à l'étal · gratuit ».
  final bool avecLivraison;

  int get total => sousTotal + fraisLivraison;

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          children: [
            _Ligne(libelle: 'Produits', montant: formaterPrix(sousTotal)),
            _Ligne(
              libelle: avecLivraison ? 'Livraison' : "Retrait à l'étal",
              montant: avecLivraison ? formaterPrix(fraisLivraison) : 'Gratuit',
            ),
            const Divider(height: AppSpacing.l),
            _Ligne(
              libelle: 'Total',
              montant: formaterPrix(total),
              style: textes.titleLarge?.copyWith(color: AppColors.primaireFonce),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({required this.libelle, required this.montant, this.style});

  final String libelle;
  final String montant;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final s = style ?? Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(libelle, style: s)),
          Text(montant, style: s),
        ],
      ),
    );
  }
}
