// =====================================================================
//  livreur_providers.dart : DONNÉES et ACTIONS du livreur
//
//  Cahier des charges : « Livreur : missions, itinéraire, scan QR de
//  remise ».
//
//  Cycle d'une mission :
//    Prête ── « J'ai récupéré la commande » ──► En livraison
//    En livraison ── scan du ticket QR (ou code) ──► Livrée ✔
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';
import '../auth/session_provider.dart';

/// Missions du livreur connecté : commandes prêtes ou en route.
final missionsProvider = FutureProvider.autoDispose<List<Commande>>((ref) async {
  final livreur = ref.watch(sessionProvider);
  if (livreur == null) return [];
  return ref.watch(commandeRepositoryProvider).missionsDuLivreur(livreur.id);
});

class LivreurActions {
  LivreurActions(this._ref);

  final Ref _ref;

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
