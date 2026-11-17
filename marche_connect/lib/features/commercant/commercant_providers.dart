// =====================================================================
//  commercant_providers.dart : DONNÉES et ACTIONS de l'espace commerçant
//
//  - Données (FutureProvider) : mon étal, mes produits, commandes reçues.
//  - Actions (CommercantActions) : chaque action appelle le repository
//    PUIS « invalide » la liste concernée → elle se recharge et l'écran
//    se met à jour tout seul.
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';
import '../auth/session_provider.dart';

/// Identifiant de l'étal du commerçant connecté (null pour les autres rôles).
final monEtalIdProvider = Provider<String?>((ref) => ref.watch(sessionProvider)?.etalId);

final monEtalProvider = FutureProvider.autoDispose<Etal?>((ref) async {
  final id = ref.watch(monEtalIdProvider);
  if (id == null) return null;
  return ref.watch(etalRepositoryProvider).trouverEtal(id);
});

/// TOUS mes produits, épuisés compris (le commerçant voit tout son stock).
final mesProduitsProvider = FutureProvider.autoDispose<List<Produit>>((ref) async {
  final id = ref.watch(monEtalIdProvider);
  if (id == null) return [];
  return ref.watch(produitRepositoryProvider).listerProduits(id, inclureEpuises: true);
});

/// Commandes reçues par mon étal, la plus récente en premier.
final commandesRecuesProvider = FutureProvider.autoDispose<List<Commande>>((ref) async {
  final id = ref.watch(monEtalIdProvider);
  if (id == null) return [];
  return ref.watch(commandeRepositoryProvider).commandesDeLEtal(id);
});

/// Nombre de commandes qui attendent une réponse (pastille de l'onglet).
final nbCommandesEnAttenteProvider = Provider.autoDispose<int>((ref) {
  final liste = ref.watch(commandesRecuesProvider).value ?? [];
  return liste.where((c) => c.statut == StatutCommande.enAttente).length;
});

// ---------------------------------------------------------------------
//  ACTIONS
// ---------------------------------------------------------------------

class CommercantActions {
  CommercantActions(this._ref);

  final Ref _ref;

  // ---------- Produits ----------

  /// UX-04 : Disponible ⇄ Épuisé en un geste.
  Future<void> basculerDisponibilite(Produit produit) async {
    await _ref.read(produitRepositoryProvider).basculerDisponibilite(produit.id);
    _ref.invalidate(mesProduitsProvider);
  }

  /// MAR-03 : nouveau prix (les commandes déjà passées gardent l'ancien).
  Future<void> changerPrix(Produit produit, int nouveauPrix) async {
    await _ref.read(produitRepositoryProvider).changerPrix(produit.id, nouveauPrix);
    _ref.invalidate(mesProduitsProvider);
  }

  Future<Produit> ajouterProduit({
    required String nom,
    required int prix,
    required UniteVente unite,
    required CategorieProduit categorie,
    String? description,
  }) async {
    final produit = await _ref.read(produitRepositoryProvider).ajouterProduit(
          etalId: _ref.read(monEtalIdProvider)!,
          nom: nom,
          prix: prix,
          unite: unite,
          categorie: categorie,
          description: description,
        );
    _ref.invalidate(mesProduitsProvider);
    return produit;
  }

  // ---------- Commandes ----------

  Future<void> changerStatut(Commande commande, StatutCommande statut) async {
    await _ref.read(commandeRepositoryProvider).changerStatut(commande.id, statut);
    _ref.invalidate(commandesRecuesProvider);
  }

  /// Mode assisté : commande saisie pour un client sans smartphone.
  /// Le commerçant la saisit lui-même : elle est confirmée d'office.
  Future<Commande> creerCommandeAssistee({
    required String nomClient,
    required String telephoneClient,
    required List<LigneCommande> lignes,
    required MoyenPaiement moyenPaiement,
  }) async {
    final repo = _ref.read(commandeRepositoryProvider);
    final commande = await repo.creerCommande(
      etalId: _ref.read(monEtalIdProvider)!,
      nomClient: nomClient,
      telephoneClient: telephoneClient,
      lignes: lignes,
      modeLivraison: ModeLivraison.retrait,
      moyenPaiement: moyenPaiement,
      saisieAssistee: true,
    );
    final confirmee = await repo.changerStatut(commande.id, StatutCommande.confirmee);
    _ref.invalidate(commandesRecuesProvider);
    return confirmee;
  }
}

final commercantActionsProvider = Provider<CommercantActions>((ref) => CommercantActions(ref));
