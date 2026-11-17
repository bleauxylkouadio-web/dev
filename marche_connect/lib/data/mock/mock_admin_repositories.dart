// =====================================================================
//  mock_admin_repositories.dart : versions SIMULÉES des repositories
//  Litiges et Admin (même principe que mock_repositories.dart).
// =====================================================================

import '../../core/config.dart';
import '../models/models.dart';
import '../repositories/admin_repository.dart';
import '../repositories/litige_repository.dart';
import 'mock_data.dart';
import 'mock_repositories.dart' show latenceParDefaut;

// =====================================================================
//  LITIGES
// =====================================================================
class MockLitigeRepository implements LitigeRepository {
  MockLitigeRepository(this._db, {this.latence = latenceParDefaut});

  final MockDatabase _db;
  final Duration latence;

  @override
  Future<Litige> signaler({
    required Commande commande,
    required MotifLitige motif,
    String description = '',
  }) async {
    await _db.reseau(latence);
    if (commande.statut != StatutCommande.livree) {
      throw StateError('Seule une commande livrée peut faire l\'objet d\'un litige.');
    }
    final litige = Litige(
      id: 'l-${_db.litiges.length + 1}',
      commandeId: commande.id,
      numeroCommande: commande.numero,
      nomEtal: commande.nomEtal,
      nomClient: commande.nomClient,
      montantCommande: commande.total,
      motif: motif,
      description: description.trim(),
      creeLe: DateTime.now(),
    );
    _db.litiges.add(litige);
    return litige;
  }

  @override
  Future<Litige?> litigeDeLaCommande(String commandeId) async {
    await _db.reseau(latence);
    return _db.litiges.where((l) => l.commandeId == commandeId).firstOrNull;
  }

  @override
  Future<List<Litige>> listerLitiges({StatutLitige? statut}) async {
    await _db.reseau(latence);
    final liste = _db.litiges.where((l) => statut == null || l.statut == statut).toList()
      // Ouverts d'abord, puis du plus ancien au plus récent (urgence).
      ..sort((a, b) {
        if (a.estOuvert != b.estOuvert) return a.estOuvert ? -1 : 1;
        return a.creeLe.compareTo(b.creeLe);
      });
    return liste;
  }

  @override
  Future<Litige> traiter(String litigeId, {required StatutLitige decision, required String reponse}) async {
    await _db.reseau(latence);
    if (decision == StatutLitige.ouvert) throw ArgumentError('Décision invalide.');
    final i = _db.litiges.indexWhere((l) => l.id == litigeId);
    if (i == -1) throw StateError('Litige introuvable : $litigeId');

    final traite = _db.litiges[i].copyWith(statut: decision, reponse: reponse.trim(), traiteLe: DateTime.now());
    _db.litiges[i] = traite;

    // Remboursement : la commande passe « Remboursé » côté paiement.
    if (decision == StatutLitige.rembourse) {
      final j = _db.commandes.indexWhere((c) => c.id == traite.commandeId);
      if (j != -1) {
        _db.commandes[j] = _db.commandes[j].copyWith(statutPaiement: StatutPaiement.rembourse);
      }
    }
    return traite;
  }
}

// =====================================================================
//  ADMIN : statistiques et comptes
// =====================================================================
class MockAdminRepository implements AdminRepository {
  MockAdminRepository(this._db, {this.latence = latenceParDefaut});

  final MockDatabase _db;
  final Duration latence;

  @override
  Future<Statistiques> statistiques() async {
    await _db.reseau(latence);
    final commandes = _db.commandes;
    // Le chiffre d'affaires ne compte que les commandes LIVRÉES et non remboursées.
    final livrees = commandes.where(
      (c) => c.statut == StatutCommande.livree && c.statutPaiement != StatutPaiement.rembourse,
    );
    final ca = livrees.fold<int>(0, (s, c) => s + c.sousTotal);

    return Statistiques(
      nombreCommandes: commandes.length,
      commandesParStatut: {
        for (final s in StatutCommande.values) s: commandes.where((c) => c.statut == s).length,
      },
      chiffreAffaires: ca,
      commissions: (ca * tauxCommission).round(),
      fraisLivraison: livrees.fold<int>(0, (s, c) => s + c.fraisLivraison),
      nombreEtals: _db.etals.length,
      nombreClients: _db.utilisateurs.where((u) => u.role == Role.client).length,
      nombreLivreurs: _db.utilisateurs.where((u) => u.role == Role.livreur).length,
      etalsParCommune: {
        for (final commune in Commune.values) commune: _db.etals.where((e) => e.commune == commune).length,
      },
      commandesAssistees: commandes.where((c) => c.saisieAssistee).length,
      litigesOuverts: _db.litiges.where((l) => l.estOuvert).length,
    );
  }

  @override
  Future<List<Utilisateur>> listerUtilisateurs({Role? role}) async {
    await _db.reseau(latence);
    return _db.utilisateurs.where((u) => role == null || u.role == role).toList();
  }
}
