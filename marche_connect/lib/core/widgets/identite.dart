// =====================================================================
//  identite.dart : l'IDENTITÉ VISUELLE de MARCHÉ_CONNECT
//
//  1. BandeDrapeau : fine bande orange | blanc | vert, en haut de
//     CHAQUE écran (posée une seule fois dans main.dart).
//
//        ███████████░░░░░░░░░░░███████████
//          orange      blanc      vert
//
//  2. LogoMarcheConnect : pictogramme + nom « Marché Connect ».
//
//        ┌────┐
//        │ 🧺 │  Marché Connect        (« Connect » en orange)
//        └────┘
// =====================================================================

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bande tricolore du drapeau ivoirien.
class BandeDrapeau extends StatelessWidget {
  const BandeDrapeau({super.key, this.hauteur = 4});

  final double hauteur;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: hauteur,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ColoredBox(color: AppColors.orangeDrapeau)),
          Expanded(child: ColoredBox(color: AppColors.blancDrapeau)),
          Expanded(child: ColoredBox(color: AppColors.vertDrapeau)),
        ],
      ),
    );
  }
}

/// Logo : pictogramme (panier sur fond vert, coin orange) + nom.
class LogoMarcheConnect extends StatelessWidget {
  const LogoMarcheConnect({
    super.key,
    this.taille = 32,
    this.surFondVert = false,
    this.avecNom = true,
  });

  /// Taille du pictogramme ; le texte suit proportionnellement.
  final double taille;

  /// Vrai dans la barre verte du haut : « Marché » en blanc,
  /// « Connect » en orange clair (lisible sur le vert).
  final bool surFondVert;

  /// Faux pour n'afficher que le pictogramme.
  final bool avecNom;

  @override
  Widget build(BuildContext context) {
    final couleurMarche = surFondVert
        ? AppColors.blancDrapeau
        : AppColors.primaire;
    final couleurConnect = surFondVert
        ? AppColors.accentSurVert
        : AppColors.accent;

    // Semantics : les lecteurs d'écran annoncent « MARCHÉ_CONNECT ».
    // FittedBox (scaleDown) : si la place manque (petit téléphone, boutons
    // à droite de la barre), le logo RÉTRÉCIT au lieu de déborder.
    return Semantics(
      label: 'MARCHÉ_CONNECT',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Pictogramme(taille: taille, surFondVert: surFondVert),
            if (avecNom) ...[
              SizedBox(width: taille * 0.3),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Marché',
                      style: TextStyle(color: couleurMarche),
                    ),
                    TextSpan(
                      text: 'Connect',
                      style: TextStyle(color: couleurConnect),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: taille * 0.62,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pictogramme extends StatelessWidget {
  const _Pictogramme({required this.taille, required this.surFondVert});

  final double taille;
  final bool surFondVert;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        // Dans la barre verte, le pictogramme est blanc pour ressortir.
        color: surFondVert ? AppColors.blancDrapeau : AppColors.primaire,
        borderRadius: BorderRadius.circular(taille * 0.28),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.shopping_basket_rounded,
              size: taille * 0.6,
              color: surFondVert ? AppColors.primaire : AppColors.blancDrapeau,
            ),
          ),
          // Petit coin orange : rappel du drapeau.
          Positioned(
            right: taille * 0.1,
            top: taille * 0.1,
            child: Container(
              width: taille * 0.22,
              height: taille * 0.22,
              decoration: const BoxDecoration(
                color: AppColors.orangeDrapeau,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
