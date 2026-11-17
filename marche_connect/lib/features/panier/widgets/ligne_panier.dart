// =====================================================================
//  ligne_panier.dart : une ligne du panier avec ses boutons − et +
//
//   Tomates                                     [🗑]
//   500 F / kg
//   [ − ]   2 kg   [ + ]                    1 000 F
//
//  MAR-02 : au kilo, on avance par demi-kilo (0,5) ; au lot, à la
//  pièce ou à la portion, par 1.
// =====================================================================

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';

/// Pas d'augmentation selon l'unité.
double pasPourUnite(UniteVente unite) => unite == UniteVente.kg ? 0.5 : 1;

class LignePanier extends StatelessWidget {
  const LignePanier({
    super.key,
    required this.ligne,
    required this.onQuantite,
    required this.onRetirer,
  });

  final LigneCommande ligne;

  /// Appelé avec la nouvelle quantité (0 = retirer).
  final ValueChanged<double> onQuantite;
  final VoidCallback onRetirer;

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    final pas = pasPourUnite(ligne.unite);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.s, AppSpacing.xs, AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Nom + supprimer ----------
            Row(
              children: [
                Expanded(child: Text(ligne.nomProduit, style: textes.titleMedium)),
                IconButton(
                  tooltip: 'Retirer ${ligne.nomProduit}',
                  icon: const Icon(Icons.delete_outline, color: AppColors.erreur),
                  onPressed: onRetirer,
                ),
              ],
            ),
            Text(
              formaterPrixUnitaire(ligne.prixUnitaire, ligne.unite),
              style: textes.bodySmall?.copyWith(color: AppColors.texteSecondaire),
            ),
            const SizedBox(height: AppSpacing.s),

            // ---------- − quantité + ........ total ----------
            Row(
              children: [
                _BoutonQuantite(
                  icone: Icons.remove,
                  tooltip: 'Moins',
                  // En dessous d'un pas, la ligne est retirée.
                  onPressed: () => onQuantite(ligne.quantite - pas),
                ),
                SizedBox(
                  width: 88,
                  child: Text(
                    formaterQuantite(ligne.quantite, ligne.unite),
                    style: textes.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                _BoutonQuantite(
                  icone: Icons.add,
                  tooltip: 'Plus',
                  onPressed: () => onQuantite(ligne.quantite + pas),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s),
                  child: Text(formaterPrix(ligne.total), style: textes.titleMedium),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton rond − ou +, assez gros pour un doigt (48 × 48).
class _BoutonQuantite extends StatelessWidget {
  const _BoutonQuantite({required this.icone, required this.tooltip, required this.onPressed});

  final IconData icone;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: tooltip,
      icon: Icon(icone),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size(AppSizes.zoneTouchMin, AppSizes.zoneTouchMin),
        side: const BorderSide(color: AppColors.primaire, width: 2),
        foregroundColor: AppColors.primaire,
      ),
    );
  }
}
