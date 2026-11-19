// =====================================================================
//  app_theme.dart : le « style » global de l'application
//
//  Un ThemeData décrit l'apparence par défaut de TOUS les composants
//  Flutter : boutons, cartes, champs de saisie, barres, onglets…
//  Les écrans écrivent simplement `FilledButton(...)` : couleur, hauteur,
//  arrondi et police viennent d'ici. Changer le style d'un composant
//  = le changer UNE fois dans ce fichier.
//
//  Principes du design (version « pro ») :
//   - aplats propres, sans ombres lourdes ; cartes blanches à fine bordure ;
//   - un seul bouton PLEIN par écran pour l'action principale ;
//   - vert ivoirien = marque et navigation ; orange = achat / paiement ;
//   - coins arrondis réguliers (14 pour les boutons, 16 pour les cartes) ;
//   - gros boutons (54) et textes lisibles au soleil (UX-06).
// =====================================================================

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_sizes.dart';

abstract final class AppTheme {
  /// Thème clair (le seul pour le MVP : plus lisible en plein soleil).
  static ThemeData get clair {
    // -----------------------------------------------------------------
    // 1. Le jeu de couleurs : quel « rôle » joue chaque couleur.
    // -----------------------------------------------------------------
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaire,
      onPrimary: AppColors.blancDrapeau,
      primaryContainer: AppColors.primaireClair,
      onPrimaryContainer: AppColors.primaireFonce,
      secondary: AppColors.accent,
      onSecondary: AppColors.surAccent,
      secondaryContainer: AppColors.accentClair,
      onSecondaryContainer: AppColors.surAccent,
      error: AppColors.erreur,
      onError: AppColors.blancDrapeau,
      surface: AppColors.surface,
      onSurface: AppColors.texte,
      onSurfaceVariant: AppColors.texteSecondaire,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.fond,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceGrisee,
      outline: AppColors.bordure,
      outlineVariant: AppColors.bordure,
    );

    // -----------------------------------------------------------------
    // 2. Les textes : hiérarchie nette (titres gras, texte courant aéré).
    // -----------------------------------------------------------------
    const textTheme = TextTheme(
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 17, height: 1.4),
      bodyMedium: TextStyle(fontSize: 15, height: 1.4),
      bodySmall: TextStyle(fontSize: 13.5, height: 1.35),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );

    // ---------- Formes communes ----------
    final formeBouton = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.moyen));
    final formeCarte = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.carte),
      side: const BorderSide(color: AppColors.bordure),
    );
    OutlineInputBorder bordureChamp(Color couleur, [double epaisseur = 1.2]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.moyen),
          borderSide: BorderSide(color: couleur, width: epaisseur),
        );

    // Bouton : toute la largeur, 54 de haut, pas d'ombre, texte gras.
    const tailleBouton = Size(double.infinity, AppSizes.hauteurBouton);
    final styleDesactive = WidgetStateProperty.resolveWith<Color?>(
      (etats) => etats.contains(WidgetState.disabled) ? AppColors.surfaceGrisee : null,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(bodyColor: AppColors.texte, displayColor: AppColors.texte),
      scaffoldBackgroundColor: AppColors.fond,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,

      // ================= BARRE DU HAUT =================
      // Vert ivoirien, texte blanc, sans ombre (la bande du drapeau
      // au-dessus fait la séparation).
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaire,
        foregroundColor: AppColors.blancDrapeau,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        titleSpacing: AppSpacing.m,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.blancDrapeau,
        ),
      ),

      // ================= ONGLETS (dans la barre verte) =================
      // Trait ORANGE sous l'onglet choisi : vert + orange = Côte d'Ivoire.
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.blancDrapeau,
        unselectedLabelColor: Color(0xCCFFFFFF),
        indicatorColor: AppColors.orangeDrapeau,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),

      // ================= BOUTON PLEIN (action principale) =================
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: tailleBouton,
          shape: formeBouton,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          textStyle: textTheme.labelLarge,
          disabledForegroundColor: AppColors.texteDesactive,
        ).copyWith(backgroundColor: _couleurBouton(AppColors.primaire, styleDesactive)),
      ),

      // ================= BOUTON À CONTOUR (action secondaire) =================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: tailleBouton,
          shape: formeBouton,
          foregroundColor: AppColors.primaire,
          backgroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          side: const BorderSide(color: AppColors.primaire, width: 1.5),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ================= BOUTON TEXTE (action discrète) =================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaire,
          minimumSize: const Size(AppSizes.zoneTouchMin, AppSizes.zoneTouchMin),
          shape: formeBouton,
          textStyle: textTheme.titleSmall,
        ),
      ),

      // ================= BOUTON ROND FLOTTANT =================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaire,
        foregroundColor: AppColors.blancDrapeau,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.carte)),
        extendedTextStyle: textTheme.labelLarge,
      ),

      // ================= CARTES =================
      // Blanches, fine bordure grise, sans ombre : net et moderne.
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: formeCarte,
      ),

      // ================= CHAMPS DE SAISIE =================
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 16),
        border: bordureChamp(AppColors.bordure),
        enabledBorder: bordureChamp(AppColors.bordure),
        focusedBorder: bordureChamp(AppColors.primaire, 2),
        errorBorder: bordureChamp(AppColors.erreur),
        focusedErrorBorder: bordureChamp(AppColors.erreur, 2),
        disabledBorder: bordureChamp(AppColors.surfaceGrisee),
        labelStyle: const TextStyle(fontSize: 15, color: AppColors.texteSecondaire),
        floatingLabelStyle: const TextStyle(color: AppColors.primaire, fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(color: AppColors.texteDesactive),
        prefixIconColor: AppColors.texteSecondaire,
        suffixIconColor: AppColors.texteSecondaire,
        errorStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
      ),

      // ================= PUCES (filtres, choix) =================
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaireClair,
        disabledColor: AppColors.surfaceGrisee,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.texte),
        secondaryLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaireFonce),
        side: WidgetStateBorderSide.resolveWith(
          (etats) => BorderSide(
            color: etats.contains(WidgetState.selected) ? AppColors.primaire : AppColors.bordure,
            width: etats.contains(WidgetState.selected) ? 1.5 : 1,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pilule)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: 10),
        showCheckmark: false,
        iconTheme: const IconThemeData(color: AppColors.primaire, size: 18),
      ),

      // ================= CHOIX SEGMENTÉ (Retrait | Livraison) =================
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 50)),
          textStyle: WidgetStatePropertyAll(textTheme.titleSmall),
          shape: WidgetStatePropertyAll(formeBouton),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.bordure)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (etats) => etats.contains(WidgetState.selected) ? AppColors.primaire : AppColors.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (etats) => etats.contains(WidgetState.selected) ? AppColors.blancDrapeau : AppColors.texte,
          ),
        ),
      ),

      // ================= INTERRUPTEUR (Dispo / Épuisé) =================
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.blancDrapeau),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        trackColor: WidgetStateProperty.resolveWith(
          (etats) => etats.contains(WidgetState.selected) ? AppColors.succes : AppColors.texteDesactive,
        ),
      ),

      // ================= BARRE DE NAVIGATION DU BAS =================
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: AppColors.primaireClair,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.moyen)),
        iconTheme: WidgetStateProperty.resolveWith(
          (etats) => IconThemeData(
            color: etats.contains(WidgetState.selected) ? AppColors.primaire : AppColors.texteSecondaire,
            size: 26,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (etats) => TextStyle(
            fontSize: 13,
            fontWeight: etats.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: etats.contains(WidgetState.selected) ? AppColors.primaire : AppColors.texteSecondaire,
          ),
        ),
      ),

      // ================= MENU LATÉRAL (back-office sur ordinateur) =================
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaireClair,
        selectedIconTheme: const IconThemeData(color: AppColors.primaire),
        unselectedIconTheme: const IconThemeData(color: AppColors.texteSecondaire),
        selectedLabelTextStyle: const TextStyle(color: AppColors.primaire, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: const TextStyle(color: AppColors.texteSecondaire),
      ),

      // ================= PASTILLES (nombre sur une icône) =================
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.orangeDrapeau,
        textColor: AppColors.surAccent,
        textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),

      // ================= FENÊTRES ET FEUILLES =================
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.grand)),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: AppColors.texte),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.texte),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.bordure,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.grand)),
        ),
      ),

      // ================= MESSAGES EN BAS D'ÉCRAN =================
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.texte,
        actionTextColor: AppColors.accentSurVert,
        contentTextStyle: const TextStyle(fontSize: 15, color: AppColors.blancDrapeau),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.moyen)),
      ),

      // ================= DIVERS =================
      dividerTheme: const DividerThemeData(color: AppColors.bordure, thickness: 1, space: 1),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.primaire),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primaire),
      iconTheme: const IconThemeData(color: AppColors.texte),
      expansionTileTheme: const ExpansionTileThemeData(
        shape: Border(),
        collapsedShape: Border(),
        iconColor: AppColors.primaire,
      ),
    );
  }

  // -------------------------------------------------------------------
  //  Styles de boutons particuliers (à passer dans `style:`)
  // -------------------------------------------------------------------

  /// Bouton ORANGE (couleur du drapeau) : réservé à l'achat et au
  /// paiement (« Voir le panier », « Continuer », « Payer 1 500 F »).
  /// Texte foncé : lisible au soleil sur l'orange.
  static ButtonStyle get boutonOrange => ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((etats) {
          if (etats.contains(WidgetState.disabled)) return AppColors.surfaceGrisee;
          if (etats.contains(WidgetState.pressed)) return const Color(0xFFE06F00);
          return AppColors.accent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith(
          (etats) => etats.contains(WidgetState.disabled) ? AppColors.texteDesactive : AppColors.surAccent,
        ),
        iconColor: WidgetStateProperty.resolveWith(
          (etats) => etats.contains(WidgetState.disabled) ? AppColors.texteDesactive : AppColors.surAccent,
        ),
      );

  /// Bouton ROUGE : action destructrice (refuser une commande…).
  static ButtonStyle get boutonDanger => FilledButton.styleFrom(
        backgroundColor: AppColors.erreur,
        foregroundColor: AppColors.blancDrapeau,
      );

  /// Couleur de fond d'un bouton plein : normale, plus foncée quand on
  /// appuie, grise quand il est désactivé.
  static WidgetStateProperty<Color?> _couleurBouton(
    Color normale,
    WidgetStateProperty<Color?> desactive,
  ) {
    return WidgetStateProperty.resolveWith((etats) {
      if (etats.contains(WidgetState.disabled)) return desactive.resolve(etats);
      if (etats.contains(WidgetState.pressed)) return AppColors.primaireFonce;
      return normale;
    });
  }
}
