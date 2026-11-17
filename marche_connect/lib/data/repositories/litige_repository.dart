// =====================================================================
//  litige_repository.dart : CONTRAT d'accès aux litiges (ACH-04)
// =====================================================================

import '../models/models.dart';

abstract interface class LitigeRepository {
  /// Le client signale un problème sur une commande livrée.
  Future<Litige> signaler({
    required Commande commande,
    required MotifLitige motif,
    String description = '',
  });

  /// Le litige d'une commande, s'il existe (pour l'afficher sur le ticket).
  Future<Litige?> litigeDeLaCommande(String commandeId);

  /// Liste pour le back-office. `statut` null = tous. Les plus anciens
  /// ouverts en premier (ce sont les plus urgents).
  Future<List<Litige>> listerLitiges({StatutLitige? statut});

  /// L'administrateur tranche : remboursement ou rejet, avec un message.
  Future<Litige> traiter(String litigeId, {required StatutLitige decision, required String reponse});
}
