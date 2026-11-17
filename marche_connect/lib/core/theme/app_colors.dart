// =====================================================================
//  app_colors.dart : TOUTES les couleurs de MARCHÉ_CONNECT
//
//  Règle : aucun écran n'écrit une couleur « en dur » (Color(0xFF...)).
//  Chaque écran utilise AppColors.xxx. Pour changer une couleur partout,
//  on la change UNE seule fois ici.
//
//  Exigence UX-06 : contrastes élevés, lisible en plein soleil.
//  Tous les couples texte/fond ci-dessous ont un contraste d'au moins
//  4.5:1 (norme d'accessibilité WCAG AA).
// =====================================================================

import 'package:flutter/material.dart';

/// Palette de couleurs de l'application.
///
/// `abstract final class` = on ne peut ni créer d'objet AppColors, ni en
/// hériter : c'est juste une « boîte » de constantes, utilisée ainsi :
/// `AppColors.primaire`.
abstract final class AppColors {
  // -------------------------------------------------------------------
  //  Couleurs de marque
  // -------------------------------------------------------------------

  /// Vert foncé : couleur principale (barre du haut, boutons principaux).
  /// Évoque les produits frais du marché. Texte blanc dessus = très lisible.
  static const Color primaire = Color(0xFF0B6E4F);

  /// Vert encore plus foncé : bouton appuyé, titres importants.
  static const Color primaireFonce = Color(0xFF07523A);

  /// Vert très clair : fonds de sections, puces sélectionnées.
  static const Color primaireClair = Color(0xFFE3F2EC);

  /// Orange : couleur d'accent (bouton « Commander », badge du panier).
  /// Attire l'œil sur l'action principale de l'écran.
  static const Color accent = Color(0xFFE8730C);

  /// Texte posé sur le orange. On utilise du noir et non du blanc :
  /// le blanc sur orange manque de contraste en plein soleil.
  static const Color surAccent = Color(0xFF1A1A1A);

  /// Orange très clair : fond du badge « Mis en avant ».
  static const Color accentClair = Color(0xFFFFD9B8);

  // -------------------------------------------------------------------
  //  Fonds et textes
  // -------------------------------------------------------------------

  /// Fond général des écrans (blanc cassé, moins éblouissant que le blanc pur).
  static const Color fond = Color(0xFFF7F7F5);

  /// Fond des cartes (produit, commande) : blanc pur pour ressortir sur le fond.
  static const Color surface = Color(0xFFFFFFFF);

  /// Texte principal : presque noir (contraste maximal).
  static const Color texte = Color(0xFF1A1A1A);

  /// Texte secondaire : dates, descriptions courtes. Reste lisible (contraste 7:1).
  static const Color texteSecondaire = Color(0xFF4A4A4A);

  /// Bordures des champs et séparateurs.
  static const Color bordure = Color(0xFFBDBDBD);

  // -------------------------------------------------------------------
  //  Couleurs d'état (disponibilité, commandes, messages)
  // -------------------------------------------------------------------

  /// Produit « Disponible », paiement réussi, commande livrée.
  static const Color succes = Color(0xFF1B7F3B);

  /// Fond clair associé au vert succès (badge « Disponible »).
  static const Color succesClair = Color(0xFFDFF3E5);

  /// Produit « Épuisé », erreur, paiement échoué.
  static const Color erreur = Color(0xFFC62828);

  /// Fond clair associé au rouge (badge « Épuisé »).
  static const Color erreurClair = Color(0xFFFBE3E3);

  /// Commande en attente de confirmation par le commerçant (MAR-01 : 10 min).
  static const Color attente = Color(0xFF8A5A00);

  /// Fond clair associé à l'état « en attente ».
  static const Color attenteClair = Color(0xFFFFF1D6);
}
