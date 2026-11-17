// =====================================================================
//  produit.dart : un article vendu par un étal
//
//  Exigences couvertes :
//  - UX-04 : Disponible / Épuisé en un geste (champ `disponible`)
//  - UX-05 : prix affiché avec sa date de mise à jour (`prixMisAJourLe`)
//  - MAR-01 : produit épuisé masqué automatiquement (`visibleParClient`)
//  - MAR-02 : vente au poids, au lot ou à la pièce (`unite`)
//
//  ⚠️ Les prix sont des NOMBRES ENTIERS en francs CFA (int), jamais des
//  nombres à virgule (double). Le franc CFA n'a pas de centimes, et les
//  nombres à virgule font des erreurs d'arrondi (0.1 + 0.2 = 0.30000000000000004).
// =====================================================================

import 'enums.dart';

class Produit {
  const Produit({
    required this.id,
    required this.etalId,
    required this.nom,
    required this.prix,
    required this.unite,
    required this.categorie,
    required this.prixMisAJourLe,
    this.description,
    this.photoUrl,
    this.disponible = true,
  });

  /// Identifiant unique du produit (ex. "p-101").
  final String id;

  /// L'étal qui vend ce produit (lien vers Etal.id).
  final String etalId;

  /// Nom court (ex. "Tomates"). Textes courts : exigence UX-02.
  final String nom;

  /// Prix en francs CFA pour UNE unité (ex. 500 pour 500 F le kg).
  final int prix;

  /// Unité de vente : kg, lot, pièce ou portion.
  final UniteVente unite;

  /// Catégorie, pour les filtres.
  final CategorieProduit categorie;

  /// Date et heure de la dernière modification du prix (UX-05).
  final DateTime prixMisAJourLe;

  /// Précision facultative (ex. "Tas de 5 tomates bien mûres").
  final String? description;

  /// Photo réelle du produit (ACH-01).
  final String? photoUrl;

  /// Vrai = « Disponible », faux = « Épuisé ».
  final bool disponible;

  /// MAR-01 : un produit épuisé est masqué automatiquement côté client.
  /// (Le commerçant, lui, voit toujours tous ses produits.)
  bool get visibleParClient => disponible;

  /// Libellé de l'unité pour l'affichage : "/ kg", "/ lot"…
  String get libelleUnite => '/ ${unite.symbole}';

  // -------------------------------------------------------------------
  //  Actions du commerçant, sous forme de copies
  // -------------------------------------------------------------------

  /// UX-04 : bascule Disponible ⇄ Épuisé en un seul geste.
  Produit basculerDisponibilite() => copyWith(disponible: !disponible);

  /// MAR-03 : le commerçant change son prix ; la date est mise à jour.
  /// Les commandes déjà passées gardent l'ancien prix (voir LigneCommande).
  Produit changerPrix(int nouveauPrix, {DateTime? maintenant}) {
    return copyWith(
      prix: nouveauPrix,
      prixMisAJourLe: maintenant ?? DateTime.now(),
    );
  }

  Produit copyWith({
    String? nom,
    int? prix,
    UniteVente? unite,
    CategorieProduit? categorie,
    DateTime? prixMisAJourLe,
    String? description,
    String? photoUrl,
    bool? disponible,
  }) {
    return Produit(
      id: id,
      etalId: etalId,
      nom: nom ?? this.nom,
      prix: prix ?? this.prix,
      unite: unite ?? this.unite,
      categorie: categorie ?? this.categorie,
      prixMisAJourLe: prixMisAJourLe ?? this.prixMisAJourLe,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      disponible: disponible ?? this.disponible,
    );
  }

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      id: json['id'] as String,
      etalId: json['etalId'] as String,
      nom: json['nom'] as String,
      prix: json['prix'] as int,
      unite: UniteVente.values.byName(json['unite'] as String),
      categorie: CategorieProduit.values.byName(json['categorie'] as String),
      // Les dates voyagent en texte ISO 8601 : "2026-11-17T08:00:00.000".
      prixMisAJourLe: DateTime.parse(json['prixMisAJourLe'] as String),
      description: json['description'] as String?,
      photoUrl: json['photoUrl'] as String?,
      disponible: json['disponible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'etalId': etalId,
        'nom': nom,
        'prix': prix,
        'unite': unite.name,
        'categorie': categorie.name,
        'prixMisAJourLe': prixMisAJourLe.toIso8601String(),
        'description': description,
        'photoUrl': photoUrl,
        'disponible': disponible,
      };
}
