// =====================================================================
//  carte_commande.dart : une commande dans une liste
//
//   Étal de Mariam                         [Prête]
//   N° 482 913 · 17 nov. à 14 h 25
//   1 produit · Livraison                  1 500 F
//
//  Utilisée par « Mes commandes » (client) et, plus tard, par
//  l'espace commerçant (commandes reçues) et le livreur (missions).
// =====================================================================

import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../utils/formatters.dart';
import 'badges.dart';

class CarteCommande extends StatelessWidget {
  const CarteCommande({
    super.key,
    required this.commande,
    this.onTap,
    this.titre,
  });

  final Commande commande;
  final VoidCallback? onTap;

  /// Titre de la carte. Par défaut, le nom de l'étal (vue client).
  /// Le commerçant affichera plutôt le nom du client.
  final String? titre;

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    final secondaire = textes.bodySmall?.copyWith(color: AppColors.texteSecondaire);
    final n = commande.nombreLignes;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(titre ?? commande.nomEtal, style: textes.titleMedium)),
                  const SizedBox(width: AppSpacing.s),
                  // Flexible : un badge long (« En attente de confirmation »)
                  // partage la largeur avec le titre au lieu de déborder.
                  Flexible(child: BadgeStatutCommande(statut: commande.statut)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'N° ${commande.numeroFormate} · '
                '${formaterDateCourte(commande.creeLe)} à ${formaterHeure(commande.creeLe)}',
                style: secondaire,
              ),
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$n produit${n > 1 ? 's' : ''} · ${commande.modeLivraison.libelle}',
                      style: textes.bodyMedium,
                    ),
                  ),
                  Text(formaterPrix(commande.total), style: textes.titleMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
