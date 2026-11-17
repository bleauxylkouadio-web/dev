// =====================================================================
//  carte_etal.dart : la carte d'un étal dans la liste de recherche
//
//    [photo]  Étal de Mariam                 ★ 4,6 (23 avis)
//             Grand marché d'Adjamé · Allée C, étal n° 14
//             📍 Adjamé                       [Mis en avant]
//
//  MAR-05 : nom, marché et emplacement toujours visibles.
//  ACH-01 : avis visibles avant de commander.
// =====================================================================

import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../utils/icones.dart';
import 'badges.dart';
import 'photo_produit.dart';

class CarteEtal extends StatelessWidget {
  const CarteEtal({super.key, required this.etal, this.onTap});

  final Etal etal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    final secondaire = textes.bodySmall?.copyWith(color: AppColors.texteSecondaire);

    // Un étal fermé est affiché grisé (Opacity) mais reste consultable.
    return Opacity(
      opacity: etal.ouvert ? 1 : 0.6,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhotoProduit(
                  url: etal.photoUrl,
                  iconeRemplacement: iconeCategorie(etal.categories.first),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(etal.nom, style: textes.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(etal.adresseComplete, style: secondaire),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.place, size: 16, color: AppColors.texteSecondaire),
                          const SizedBox(width: AppSpacing.xs),
                          Text(etal.commune.libelle, style: secondaire),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                      // Wrap = comme Row, mais passe à la ligne si pas assez de place.
                      Wrap(
                        spacing: AppSpacing.s,
                        runSpacing: AppSpacing.xs,
                        children: [
                          BadgeNote(note: etal.noteMoyenne, nombreAvis: etal.nombreAvis),
                          if (etal.misEnAvant)
                            const Etiquette(
                              texte: 'Mis en avant',
                              icone: Icons.campaign,
                              couleur: AppColors.surAccent,
                              fond: AppColors.accentClair,
                            ),
                          if (!etal.ouvert)
                            const Etiquette(
                              texte: "Fermé aujourd'hui",
                              icone: Icons.lock_clock,
                              couleur: AppColors.erreur,
                              fond: AppColors.erreurClair,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
