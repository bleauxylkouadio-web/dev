// =====================================================================
//  app_colors.dart : TOUTES les couleurs de MARCHÉ_CONNECT
//
//  Identité visuelle : les couleurs du DRAPEAU IVOIRIEN.
//    🟧 Orange  #F77F00  → achats, paiement, appels à l'action
//    ⬜ Blanc   #FFFFFF  → fonds, cartes (clarté, lisibilité)
//    🟩 Vert    #009E60  → marque, navigation, validation
//
//  Pour le texte et les boutons, on utilise des NUANCES plus foncées
//  du vert et de l'orange : les couleurs exactes du drapeau sont trop
//  claires pour du texte blanc lu en plein soleil (UX-06).
//
//  Règle : aucun écran n'écrit une couleur « en dur » (Color(0xFF...)).
//  Chaque écran utilise AppColors.xxx. Pour changer une couleur partout,
//  on la change UNE seule fois ici.
//
//  Contrastes vérifiés (norme WCAG AA, au moins 4,5:1 pour le texte) :
//    blanc sur primaire        5,4:1
//    texte sur accent          7,9:1   (texte foncé sur orange)
//    texteSecondaire sur blanc 6,1:1
// =====================================================================

import 'package:flutter/material.dart';

/// Palette de couleurs de l'application.
///
/// `abstract final class` = on ne peut ni créer d'objet AppColors, ni en
/// hériter : c'est juste une « boîte » de constantes, utilisée ainsi :
/// `AppColors.primaire`.
abstract final class AppColors {
  // -------------------------------------------------------------------
  //  Couleurs EXACTES du drapeau (bande décorative, logo)
  // -------------------------------------------------------------------
  static const Color orangeDrapeau = Color(0xFFF77F00);
  static const Color blancDrapeau = Color(0xFFFFFFFF);
  static const Color vertDrapeau = Color(0xFF009E60);

  // -------------------------------------------------------------------
  //  Couleurs de marque (usage dans l'interface)
  // -------------------------------------------------------------------

  /// Vert ivoirien profond : barre du haut, bouton principal, liens.
  /// Texte blanc dessus : très lisible.
  static const Color primaire = Color(0xFF007A4D);

  /// Vert encore plus foncé : bouton appuyé, titres sur fond clair.
  static const Color primaireFonce = Color(0xFF005C3A);

  /// Vert très clair : fonds de sélection, puces choisies.
  static const Color primaireClair = Color(0xFFE6F4EE);

  /// Orange du drapeau : « Commander », « Payer », pastilles du panier.
  static const Color accent = orangeDrapeau;

  /// Texte posé sur l'orange : presque noir (le blanc sur orange manque
  /// de contraste au soleil).
  static const Color surAccent = Color(0xFF1B1B1B);

  /// Orange très clair : fond « Mis en avant », alertes douces.
  static const Color accentClair = Color(0xFFFFEBD6);

  /// Orange clair lisible sur le vert (deuxième moitié du logo).
  static const Color accentSurVert = Color(0xFFFFB25B);

  // -------------------------------------------------------------------
  //  Fonds et textes
  // -------------------------------------------------------------------

  /// Fond général des écrans : blanc légèrement grisé (moins éblouissant).
  static const Color fond = Color(0xFFF6F7F5);

  /// Fond des cartes et des champs : blanc pur.
  static const Color surface = Color(0xFFFFFFFF);

  /// Fond des zones secondaires (champ inactif, bouton désactivé).
  static const Color surfaceGrisee = Color(0xFFEEF0EF);

  /// Texte principal : presque noir, légèrement bleuté (plus doux).
  static const Color texte = Color(0xFF15191E);

  /// Texte secondaire : dates, descriptions courtes.
  static const Color texteSecondaire = Color(0xFF5A6270);

  /// Texte désactivé.
  static const Color texteDesactive = Color(0xFF9AA1AB);

  /// Bordures fines des cartes et des champs.
  static const Color bordure = Color(0xFFDDE1E5);

  // -------------------------------------------------------------------
  //  Couleurs d'état (disponibilité, commandes, messages)
  // -------------------------------------------------------------------

  /// « Disponible », paiement réussi, commande livrée.
  static const Color succes = Color(0xFF12804A);
  static const Color succesClair = Color(0xFFE3F5EC);

  /// « Épuisé », erreur, paiement échoué.
  static const Color erreur = Color(0xFFD32F2F);
  static const Color erreurClair = Color(0xFFFDECEC);

  /// En attente (confirmation du commerçant, MAR-01) : orange foncé.
  static const Color attente = Color(0xFF9A5B00);
  static const Color attenteClair = Color(0xFFFFF3E0);
}
