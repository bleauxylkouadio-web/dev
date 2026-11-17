// =====================================================================
//  app_sizes.dart : espacements, arrondis et tailles minimales
//
//  Pourquoi un fichier dédié ? Pour que tous les écrans aient les mêmes
//  marges et les mêmes tailles de boutons : l'application paraît
//  cohérente et on peut tout ajuster depuis un seul endroit.
// =====================================================================

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
  /// Badges « Disponible / Épuisé ».
  static const double petit = 8;

  /// Boutons, champs de saisie, cartes.
  static const double moyen = 12;

  /// Feuilles qui montent du bas de l'écran (panier rapide…).
  static const double grand = 20;
}

/// Tailles minimales des éléments touchables.
///
/// Exigence UX-06 : « gros boutons ». Google recommande 48 au minimum.
/// On prend plus grand, car l'application est utilisée debout, au marché,
/// parfois avec les mains occupées.
abstract final class AppSizes {
  /// Hauteur des boutons principaux (« Commander », « Payer 1 500 F »).
  static const double hauteurBouton = 56;

  /// Taille minimale de toute zone touchable (icône, case à cocher…).
  static const double zoneTouchMin = 48;

  /// Taille des icônes dans les boutons et les listes.
  static const double icone = 26;

  /// Taille des photos de produits dans les listes.
  static const double photoProduit = 72;
}
