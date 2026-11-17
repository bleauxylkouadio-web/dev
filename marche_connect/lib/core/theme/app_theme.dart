// =====================================================================
//  app_theme.dart : le « style » global de l'application
//
//  Un ThemeData décrit l'apparence par défaut de TOUS les composants
//  Flutter : boutons, cartes, champs de saisie, barre du haut…
//  Une fois branché dans main.dart, un simple `FilledButton(...)` aura
//  automatiquement notre couleur, notre hauteur et notre police,
//  sans rien écrire de plus dans les écrans.
// =====================================================================

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_sizes.dart';

abstract final class AppTheme {
  /// Thème clair (le seul pour le MVP : le mode clair est plus lisible
  /// en plein soleil que le mode sombre).
  static ThemeData get clair {
    // -----------------------------------------------------------------
    // 1. Le jeu de couleurs (ColorScheme)
    //    Flutter lit ces « rôles » pour colorer ses composants :
    //    primary = action principale, onPrimary = texte posé dessus, etc.
    // -----------------------------------------------------------------
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaire,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaireClair,
      onPrimaryContainer: AppColors.primaireFonce,
      secondary: AppColors.accent,
      onSecondary: AppColors.surAccent,
      error: AppColors.erreur,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.texte,
      onSurfaceVariant: AppColors.texteSecondaire,
      outline: AppColors.bordure,
    );

    // -----------------------------------------------------------------
    // 2. Les textes
    //    Tailles légèrement plus grandes que celles de Flutter par défaut
    //    (UX-06) et textes en gras pour les prix et les titres.
    // -----------------------------------------------------------------
    const textTheme = TextTheme(
      // Gros titre d'écran : « Étal de Mariam ».
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      // Titre de section ou de carte : « Tomates 1 kg ».
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      // Texte courant.
      bodyLarge: TextStyle(fontSize: 18),
      bodyMedium: TextStyle(fontSize: 16),
      // Petits textes : « Prix mis à jour il y a 2 h » (UX-05).
      bodySmall: TextStyle(fontSize: 14),
      // Texte dans les boutons.
      labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );

    // Forme commune aux boutons et aux champs : coins arrondis.
    final formeArrondie = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.moyen),
    );

    // Taille commune à tous les boutons : toute la largeur disponible
    // (double.infinity) et 56 de haut.
    const tailleBouton = Size(double.infinity, AppSizes.hauteurBouton);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // Applique nos couleurs de texte par défaut à notre TextTheme.
      textTheme: textTheme.apply(
        bodyColor: AppColors.texte,
        displayColor: AppColors.texte,
      ),
      scaffoldBackgroundColor: AppColors.fond,

      // Agrandit la zone de toucher des petits éléments à 48 minimum.
      materialTapTargetSize: MaterialTapTargetSize.padded,

      // ---------------- Barre du haut ----------------
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaire,
        foregroundColor: Colors.white, // couleur du titre et des icônes
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),

      // ---------------- Bouton plein (action principale) ----------------
      // Exemple : « Commander », « Payer 1 500 F ».
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: tailleBouton,
          shape: formeArrondie,
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ---------------- Bouton à contour (action secondaire) ----------------
      // Exemple : « Retrait sur place », « Appeler le commerçant ».
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: tailleBouton,
          shape: formeArrondie,
          side: const BorderSide(color: AppColors.primaire, width: 2),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ---------------- Bouton texte (action discrète) ----------------
      // Exemple : « Voir tout », « Annuler ».
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSizes.zoneTouchMin, AppSizes.zoneTouchMin),
          textStyle: textTheme.titleMedium,
        ),
      ),

      // ---------------- Cartes (produit, commande) ----------------
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        margin: EdgeInsets.zero, // les marges sont gérées par chaque écran
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.moyen),
        ),
      ),

      // ---------------- Champs de saisie ----------------
      // Exemple : numéro de téléphone, prix d'un produit.
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.m,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.moyen),
          borderSide: const BorderSide(color: AppColors.bordure),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.moyen),
          borderSide: const BorderSide(color: AppColors.bordure),
        ),
        // Champ en cours de saisie : bordure verte épaisse, bien visible.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.moyen),
          borderSide: const BorderSide(color: AppColors.primaire, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.moyen),
          borderSide: const BorderSide(color: AppColors.erreur, width: 2),
        ),
        labelStyle: const TextStyle(fontSize: 16),
      ),

      // ---------------- Puces de filtre ----------------
      // Exemple : filtres par commune (Cocody, Abobo…) et par catégorie.
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaireClair,
        labelStyle: const TextStyle(fontSize: 16, color: AppColors.texte),
        side: const BorderSide(color: AppColors.bordure),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: AppSpacing.s,
        ),
      ),

      // ---------------- Barre de navigation du bas ----------------
      // Exemple côté client : Accueil · Panier · Commandes · Profil.
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaireClair,
        height: 72,
      ),

      // ---------------- Messages en bas d'écran (SnackBar) ----------------
      // Exemple : « Produit ajouté au panier ».
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.texte,
        contentTextStyle: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}
