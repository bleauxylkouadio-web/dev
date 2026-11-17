// =====================================================================
//  admin_providers.dart : DONNÉES et ACTIONS du back-office
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';

final statistiquesProvider = FutureProvider.autoDispose<Statistiques>((ref) {
  return ref.watch(adminRepositoryProvider).statistiques();
});

/// Litiges filtrés par statut (null = tous).
final litigesProvider = FutureProvider.autoDispose.family<List<Litige>, StatutLitige?>((ref, statut) {
  return ref.watch(litigeRepositoryProvider).listerLitiges(statut: statut);
});

/// Comptes filtrés par rôle (null = tous).
final utilisateursProvider = FutureProvider.autoDispose.family<List<Utilisateur>, Role?>((ref, role) {
  return ref.watch(adminRepositoryProvider).listerUtilisateurs(role: role);
});

/// Tous les étals (sans filtre).
final tousLesEtalsProvider = FutureProvider.autoDispose<List<Etal>>((ref) {
  return ref.watch(etalRepositoryProvider).listerEtals();
});

class AdminActions {
  AdminActions(this._ref);

  final Ref _ref;

  /// Tranche un litige puis recharge les listes et les chiffres.
  Future<void> traiterLitige(Litige litige, {required StatutLitige decision, required String reponse}) async {
    await _ref.read(litigeRepositoryProvider).traiter(litige.id, decision: decision, reponse: reponse);
    // invalidate sur une « family » sans paramètre : toutes les variantes.
    _ref.invalidate(litigesProvider);
    _ref.invalidate(statistiquesProvider);
  }
}

final adminActionsProvider = Provider<AdminActions>((ref) => AdminActions(ref));
