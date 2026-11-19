// =====================================================================
//  mock_suivi_repository.dart : version SIMULÉE du suivi en direct
// =====================================================================

import '../models/models.dart';
import '../repositories/suivi_repository.dart';
import 'mock_data.dart';
import 'mock_repositories.dart' show latenceParDefaut;

class MockSuiviRepository implements SuiviRepository {
  MockSuiviRepository(this._db, {this.latence = latenceParDefaut});

  final MockDatabase _db;
  final Duration latence;

  bool _enLivraison(String commandeId) =>
      _db.commandes.any((c) => c.id == commandeId && c.statut == StatutCommande.enLivraison);

  @override
  Future<void> envoyerPosition(PositionLivreur position) async {
    await _db.reseau(latence);
    if (!_enLivraison(position.commandeId)) {
      throw StateError('La commande ${position.commandeId} n\'est pas en livraison.');
    }
    _db.positions[position.commandeId] = position;
  }

  @override
  Future<PositionLivreur?> positionDuLivreur(String commandeId) async {
    await _db.reseau(latence);
    // Vie privée : rien n'est montré en dehors de la livraison.
    if (!_enLivraison(commandeId)) return null;
    return _db.positions[commandeId];
  }
}
