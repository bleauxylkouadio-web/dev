// =====================================================================
//  admin_repository.dart : CONTRAT du back-office administrateur
//  (« comptes, litiges, commissions, statistiques »)
// =====================================================================

import '../models/models.dart';

abstract interface class AdminRepository {
  /// Les chiffres clés du tableau de bord.
  Future<Statistiques> statistiques();

  /// Tous les comptes ; `role` null = tous les rôles.
  Future<List<Utilisateur>> listerUtilisateurs({Role? role});
}
