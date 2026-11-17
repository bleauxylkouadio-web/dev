// =====================================================================
//  icones.dart : une icône pour chaque catégorie et chaque statut
//
//  UX-02 : « français avec icônes et photos ». Une icône aide les
//  personnes peu à l'aise avec la lecture à se repérer.
//  Elle sert aussi d'image de remplacement quand un produit n'a pas
//  encore de photo.
// =====================================================================

import 'package:flutter/material.dart';

import '../../data/models/models.dart';

/// Icône d'une catégorie de produits.
IconData iconeCategorie(CategorieProduit categorie) {
  // `switch` sur un enum : Dart vérifie qu'on n'oublie AUCUNE valeur.
  return switch (categorie) {
    CategorieProduit.legumes => Icons.eco,
    CategorieProduit.fruits => Icons.apple,
    CategorieProduit.vivriers => Icons.grass,
    CategorieProduit.poissonViande => Icons.set_meal,
    CategorieProduit.platsCuisines => Icons.restaurant,
    CategorieProduit.epicerie => Icons.local_grocery_store,
    CategorieProduit.pagnes => Icons.checkroom,
    CategorieProduit.beaute => Icons.spa,
    CategorieProduit.autres => Icons.shopping_basket,
  };
}

/// Icône d'un statut de commande.
IconData iconeStatut(StatutCommande statut) {
  return switch (statut) {
    StatutCommande.enAttente => Icons.hourglass_top,
    StatutCommande.confirmee => Icons.thumb_up,
    StatutCommande.prete => Icons.inventory_2,
    StatutCommande.enLivraison => Icons.delivery_dining,
    StatutCommande.livree => Icons.check_circle,
    StatutCommande.annulee => Icons.cancel,
  };
}

/// Icône d'un moyen de paiement.
IconData iconePaiement(MoyenPaiement moyen) {
  return moyen.estMobileMoney ? Icons.phone_android : Icons.payments;
}
