// =====================================================================
//  suivi_repository.dart : CONTRAT du suivi du livreur en direct
//
//  Livreur → envoyerPosition() toutes les ~10 s pendant la livraison.
//  Client  → positionDuLivreur() pour afficher la carte sur le ticket.
//
//  Avec la vraie API, le client pourra recevoir les positions en temps
//  réel (WebSocket) au lieu de redemander toutes les 10 s.
// =====================================================================

import '../models/models.dart';

abstract interface class SuiviRepository {
  /// Enregistre la dernière position du livreur pour une commande.
  /// Refusé si la commande n'est pas « En livraison ».
  Future<void> envoyerPosition(PositionLivreur position);

  /// Dernière position connue du livreur, ou null si la commande n'est
  /// pas en cours de livraison (vie privée) ou si rien n'a été envoyé.
  Future<PositionLivreur?> positionDuLivreur(String commandeId);
}
