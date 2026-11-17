// =====================================================================
//  photo_produit.dart : photo d'un produit ou d'un étal
//
//  - Avec photo   → l'image, coins arrondis, recadrée en carré.
//  - Sans photo   → l'icône de la catégorie sur fond vert clair.
//  - Image cassée (réseau coupé) → même icône, jamais de croix rouge.
// =====================================================================

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

class PhotoProduit extends StatelessWidget {
  const PhotoProduit({
    super.key,
    required this.iconeRemplacement,
    this.url,
    this.taille = AppSizes.photoProduit,
  });

  /// Adresse de la photo (peut être vide).
  final String? url;

  /// Icône affichée s'il n'y a pas de photo (voir utils/icones.dart).
  final IconData iconeRemplacement;

  final double taille;

  @override
  Widget build(BuildContext context) {
    final remplacement = Container(
      width: taille,
      height: taille,
      color: AppColors.primaireClair,
      child: Icon(iconeRemplacement, color: AppColors.primaire, size: taille * 0.45),
    );

    // ClipRRect = découpe son contenu avec des coins arrondis.
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.petit),
      child: url == null
          ? remplacement
          : Image.network(
              url!,
              width: taille,
              height: taille,
              fit: BoxFit.cover, // remplit le carré sans déformer
              errorBuilder: (_, _, _) => remplacement,
            ),
    );
  }
}
