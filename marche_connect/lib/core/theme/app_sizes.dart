// =====================================================================
//  app_sizes.dart : espacements, arrondis et tailles minimales
//
//  Pourquoi un fichier dédié ? Pour que tous les écrans aient les mêmes
//  marges et les mêmes tailles de boutons : l'application paraît
//  cohérente et on peut tout ajuster depuis un seul endroit.
// =====================================================================

import 'package:flutter/painting.dart';

/// Espacements (en « pixels logiques », l'unité de Flutter, indépendante
/// de la résolution de l'écran).
abstract final class AppSpacing {
  /// 4 : entre une icône et son texte.
  static const double xs = 4;

  /// 8 : entre deux éléments proches (prix et date de mise à jour).
  static const double s = 8;

  /// 16 : marge standard des écrans et entre deux cartes.
  static const double m = 16;

  /// 24 : entre deux sections d'un écran.
  static const double l = 24;

  /// 32 : grands espaces (haut de l'écran de connexion).
  static const double xl = 32;
}

/// Arrondis des coins.
abstract final class AppRadius {
  /// Photos, petits éléments.
  static const double petit = 10;

  /// Boutons et champs de saisie.
  static const double moyen = 14;

  /// Cartes.
  static const double carte = 16;

  /// Fenêtres et feuilles qui montent du bas de l'écran.
  static const double grand = 24;

  /// Pilule (badges « Disponible / Épuisé », puces).
  static const double pilule = 999;
}

/// Ombres douces : les cartes « flottent » légèrement au-dessus du fond.
abstract final class AppOmbres {
  static const List<BoxShadow> carte = [
    BoxShadow(color: Color(0x0F15191E), blurRadius: 12, offset: Offset(0, 4)),
  ];
}

/// Tailles minimales des éléments touchables.
///
/// Exigence UX-06 : « gros boutons ». Google recommande 48 au minimum.
/// On prend plus grand, car l'application est utilisée debout, au marché,
/// parfois avec les mains occupées.
abstract final class AppSizes {
  /// Hauteur des boutons principaux (« Commander », « Payer 1 500 F »).
  static const double hauteurBouton = 54;

  /// Taille minimale de toute zone touchable (icône, case à cocher…).
  static const double zoneTouchMin = 48;

  /// Taille des icônes dans les boutons et les listes.
  static const double icone = 26;

  /// Taille des photos de produits dans les listes.
  static const double photoProduit = 72;
}
