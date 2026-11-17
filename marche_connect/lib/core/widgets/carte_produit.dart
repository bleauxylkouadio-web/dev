// =====================================================================
//  carte_produit.dart : la carte d'un produit, en DEUX MODES
//
//  Mode CLIENT (vitrine) — maquette « Vitrine de l'étal » :
//    [photo]  Tomates            [ + Ajouter ]
//             500 F / kg
//             Prix mis à jour il y a 2 h
//
//  Mode COMMERÇANT (mes produits) — maquette « Espace commerçant » :
//    [photo]  Pagnes wax         [ Dispo ●— ]
//             8 000 F / pièce
//
//  Le mode est choisi selon le paramètre fourni :
//    onAjouter   → mode client
//    onBasculer  → mode commerçant (interrupteur Disponible/Épuisé, UX-04)
// =====================================================================

import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../utils/formatters.dart';
import '../utils/icones.dart';
import 'badges.dart';
import 'photo_produit.dart';

class CarteProduit extends StatelessWidget {
  const CarteProduit({
    super.key,
    required this.produit,
    this.onAjouter,
    this.onBasculer,
    this.onTap,
    this.quantiteDansPanier = 0,
  });

  final Produit produit;

  /// Mode client : appui sur « Ajouter ».
  final VoidCallback? onAjouter;

  /// Mode commerçant : appui sur l'interrupteur Disponible/Épuisé.
  final VoidCallback? onBasculer;

  /// Appui sur la carte entière (ouvrir le détail ou modifier le prix).
  final VoidCallback? onTap;

  /// Mode client : quantité déjà dans le panier (affiche « 2 dans le panier »).
  final double quantiteDansPanier;

  bool get _modeCommercant => onBasculer != null;

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;

    return Card(
      // clipBehavior : l'effet d'appui reste dans les coins arrondis.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              PhotoProduit(
                url: produit.photoUrl,
                iconeRemplacement: iconeCategorie(produit.categorie),
              ),
              const SizedBox(width: AppSpacing.m),

              // ---------- Textes ----------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produit.nom,
                      style: textes.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis, // « … » si trop long
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formaterPrixUnitaire(produit.prix, produit.unite),
                      style: textes.titleLarge?.copyWith(color: AppColors.primaireFonce),
                    ),
                    // UX-05 : date de mise à jour du prix.
                    Text(
                      formaterMiseAJourPrix(produit.prixMisAJourLe),
                      style: textes.bodySmall?.copyWith(color: AppColors.texteSecondaire),
                    ),
                    if (quantiteDansPanier > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${formaterQuantite(quantiteDansPanier, produit.unite)} dans le panier',
                        style: textes.bodySmall?.copyWith(
                          color: AppColors.succes,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),

              // ---------- Action à droite ----------
              if (_modeCommercant)
                _InterrupteurDisponibilite(
                  disponible: produit.disponible,
                  onBasculer: onBasculer!,
                )
              else if (!produit.disponible)
                const BadgeDisponibilite(disponible: false)
              else if (onAjouter != null)
                _BoutonAjouter(onAjouter: onAjouter!),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton compact « + » du mode client. Taille 56×56 : facile à toucher.
class _BoutonAjouter extends StatelessWidget {
  const _BoutonAjouter({required this.onAjouter});

  final VoidCallback onAjouter;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onAjouter,
      icon: const Icon(Icons.add_shopping_cart),
      tooltip: 'Ajouter au panier', // lu par les lecteurs d'écran
      style: IconButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.surAccent,
        minimumSize: const Size(AppSizes.hauteurBouton, AppSizes.hauteurBouton),
      ),
    );
  }
}

/// Interrupteur du mode commerçant : un geste = Disponible ⇄ Épuisé (UX-04).
class _InterrupteurDisponibilite extends StatelessWidget {
  const _InterrupteurDisponibilite({
    required this.disponible,
    required this.onBasculer,
  });

  final bool disponible;
  final VoidCallback onBasculer;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: disponible,
          onChanged: (_) => onBasculer(),
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.succes,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: AppColors.erreur,
        ),
        Text(
          disponible ? 'Dispo' : 'Épuisé',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: disponible ? AppColors.succes : AppColors.erreur,
          ),
        ),
      ],
    );
  }
}
