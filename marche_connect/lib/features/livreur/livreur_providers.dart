// =====================================================================
//  livreur_providers.dart : DONNÉES et ACTIONS du livreur
//
//  Cahier des charges : « Livreur : missions, itinéraire, scan QR de
//  remise ».
//
//  Cycle d'une mission :
//    Disponible ── « Accepter » ──► dans mes missions
//    Prête ── « J'ai récupéré la commande » ──► En livraison
//    En livraison ── scan du ticket QR (ou code) ──► Livrée ✔
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';
import '../auth/session_provider.dart';

/// Missions du livreur connecté : commandes acceptées, prêtes ou en route.
final missionsProvider = FutureProvider.autoDispose<List<Commande>>((ref) async {
  final livreur = ref.watch(sessionProvider);
  if (livreur == null) return [];
  return ref.watch(commandeRepositoryProvider).missionsDuLivreur(livreur.id);
});

// ---------------------------------------------------------------------
//  COMMANDES DISPONIBLES DANS LA MÊME COMMUNE (tournées)
// ---------------------------------------------------------------------

/// Les communes où le livreur va livrer :
///  - s'il a des courses : les communes de livraison de ces courses
///    (il peut prendre d'autres commandes sur le même trajet) ;
///  - sinon : sa commune de travail, choisie à l'inscription.
List<Commune> communesDuLivreur(List<Commande> missions, Utilisateur? livreur) {
  final communes = <Commune>{
    for (final m in missions)
      if (m.communeLivraison != null) m.communeLivraison!,
  };
  if (communes.isEmpty && livreur?.commune != null) communes.add(livreur!.commune!);
  return communes.toList();
}

/// Commandes sans livreur, à livrer dans les communes du livreur.
final commandesDisponiblesProvider = FutureProvider.autoDispose<List<Commande>>((ref) async {
  final livreur = ref.watch(sessionProvider);
  if (livreur == null) return [];
  // `.future` : on attend que les missions soient chargées.
  final missions = await ref.watch(missionsProvider.future);
  final repo = ref.watch(commandeRepositoryProvider);
  return [
    for (final commune in communesDuLivreur(missions, livreur)) ...await repo.commandesDisponibles(commune),
  ];
});

class LivreurActions {
  LivreurActions(this._ref);

  final Ref _ref;

  /// Le livreur prend une commande disponible. Renvoie faux si un autre
  /// livreur a été plus rapide.
  Future<bool> accepter(Commande commande) async {
    final livreur = _ref.read(sessionProvider);
    if (livreur == null) return false;
    final acceptee = await _ref.read(commandeRepositoryProvider).accepterLivraison(commande.id, livreur.id);
    _ref.invalidate(missionsProvider); // recharge aussi les disponibles
    return acceptee != null;
  }

  /// Le livreur a pris la commande à l'étal : elle passe « En route ».
  Future<void> recuperer(Commande commande) async {
    await _ref.read(commandeRepositoryProvider).changerStatut(commande.id, StatutCommande.enLivraison);
    _ref.invalidate(missionsProvider);
  }

  /// Valide la remise avec le contenu du QR ou le code à 6 chiffres.
  /// Renvoie la commande livrée, ou null si le code est refusé.
  Future<Commande?> validerRemise(String qrOuCode) async {
    final commande = await _ref.read(commandeRepositoryProvider).validerRemise(qrOuCode);
    _ref.invalidate(missionsProvider);
    return commande;
  }
}

final livreurActionsProvider = Provider<LivreurActions>((ref) => LivreurActions(ref));
