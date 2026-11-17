// =====================================================================
//  produit_repository.dart : CONTRAT d'accès aux produits
//  (vitrine côté client + « Mes produits » côté commerçant)
// =====================================================================

import '../models/models.dart';

abstract interface class ProduitRepository {
  /// Produits d'un étal.
  ///
  /// - Côté CLIENT : `inclureEpuises: false` (par défaut) → les produits
  ///   épuisés sont masqués automatiquement (MAR-01).
  /// - Côté COMMERÇANT : `inclureEpuises: true` → il voit tout son stock.
  Future<List<Produit>> listerProduits(
    String etalId, {
    bool inclureEpuises = false,
  });

  /// Un produit précis, ou `null`.
  Future<Produit?> trouverProduit(String id);

  /// UX-04 : Disponible ⇄ Épuisé en un geste. Renvoie le produit modifié.
  Future<Produit> basculerDisponibilite(String produitId);

  /// MAR-03 : nouveau prix (la date de mise à jour change aussi).
  Future<Produit> changerPrix(String produitId, int nouveauPrix);

  /// Ajout d'un produit par le commerçant (« + Photo et prix »).
  /// L'identifiant est attribué par le serveur : on le reçoit dans le retour.
  Future<Produit> ajouterProduit({
    required String etalId,
    required String nom,
    required int prix,
    required UniteVente unite,
    required CategorieProduit categorie,
    String? description,
    String? photoUrl,
  });
}
