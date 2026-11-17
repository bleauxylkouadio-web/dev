// =====================================================================
//  mock_repositories.dart : versions SIMULÉES des 4 repositories
//
//  Elles respectent les contrats de lib/data/repositories/ mais lisent
//  et écrivent dans MockDatabase (en mémoire) au lieu d'appeler l'API.
//
//  `latence` simule le temps d'un appel réseau (300 ms par défaut), pour
//  voir les indicateurs de chargement dans les écrans comme en vrai.
//  Les tests passent `Duration.zero` pour aller vite.
// =====================================================================

import 'dart:math';

import '../models/models.dart';
import '../repositories/auth_repository.dart';
import '../repositories/commande_repository.dart';
import '../repositories/etal_repository.dart';
import '../repositories/produit_repository.dart';
import 'mock_data.dart';

/// Délai réseau simulé par défaut.
const Duration latenceParDefaut = Duration(milliseconds: 300);

// =====================================================================
//  CONNEXION
// =====================================================================
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._db, {this.latence = latenceParDefaut});

  final MockDatabase _db;
  final Duration latence;

  @override
  Future<void> envoyerCode(String telephone) async {
    await _db.reseau(latence);
    // En démo, aucun SMS : le code est toujours 123456 (voir mock_data.dart).
  }

  @override
  Future<Utilisateur?> verifierCode(String telephone, String code) async {
    await _db.reseau(latence);
    if (code != codeOtpDemo) return null; // mauvais code

    // Compte existant ? On le renvoie.
    for (final u in _db.utilisateurs) {
      if (u.telephone == telephone) return u;
    }
    // Nouveau numéro : inscription automatique comme client.
    final nouveau = Utilisateur(
      id: 'u-${_db.utilisateurs.length + 1}',
      telephone: telephone,
      nom: 'Nouveau client',
      role: Role.client,
    );
    _db.utilisateurs.add(nouveau);
    return nouveau;
  }

  @override
  Future<void> deconnecter() async {
    await _db.reseau(latence);
  }
}

// =====================================================================
//  ÉTALS
// =====================================================================
class MockEtalRepository implements EtalRepository {
  MockEtalRepository(this._db, {this.latence = latenceParDefaut});

  final MockDatabase _db;
  final Duration latence;

  @override
  Future<List<Etal>> listerEtals({
    Commune? commune,
    CategorieProduit? categorie,
    String? recherche,
  }) async {
    await _db.reseau(latence);

    // On part de tous les étals et on applique chaque filtre demandé.
    var resultat = _db.etals.toList();

    if (commune != null) {
      resultat = resultat.where((e) => e.commune == commune).toList();
    }
    if (categorie != null) {
      resultat = resultat.where((e) => e.categories.contains(categorie)).toList();
    }
    if (recherche != null && recherche.trim().isNotEmpty) {
      final texte = recherche.trim().toLowerCase();
      resultat = resultat
          .where((e) =>
              e.nom.toLowerCase().contains(texte) ||
              e.nomCommercant.toLowerCase().contains(texte) ||
              e.marche.toLowerCase().contains(texte))
          .toList();
    }

    // Tri : mis en avant d'abord, puis ouverts, puis meilleure note.
    resultat.sort((a, b) {
      if (a.misEnAvant != b.misEnAvant) return a.misEnAvant ? -1 : 1;
      if (a.ouvert != b.ouvert) return a.ouvert ? -1 : 1;
      return b.noteMoyenne.compareTo(a.noteMoyenne);
    });
    return resultat;
  }

  @override
  Future<Etal?> trouverEtal(String id) async {
    await _db.reseau(latence);
    return _db.etals.where((e) => e.id == id).firstOrNull;
  }
}

// =====================================================================
//  PRODUITS
// =====================================================================
class MockProduitRepository implements ProduitRepository {
  MockProduitRepository(this._db, {this.latence = latenceParDefaut});

  final MockDatabase _db;
  final Duration latence;

  @override
  Future<List<Produit>> listerProduits(
    String etalId, {
    bool inclureEpuises = false,
  }) async {
    await _db.reseau(latence);
    return _db.produits
        .where((p) => p.etalId == etalId)
        .where((p) => inclureEpuises || p.visibleParClient) // MAR-01
        .toList();
  }

  @override
  Future<Produit?> trouverProduit(String id) async {
    await _db.reseau(latence);
    return _db.produits.where((p) => p.id == id).firstOrNull;
  }

  @override
  Future<Produit> basculerDisponibilite(String produitId) async {
    await _db.reseau(latence);
    return _remplacer(produitId, (p) => p.basculerDisponibilite());
  }

  @override
  Future<Produit> changerPrix(String produitId, int nouveauPrix) async {
    await _db.reseau(latence);
    if (nouveauPrix <= 0) {
      throw ArgumentError('Le prix doit être supérieur à 0 F.');
    }
    return _remplacer(produitId, (p) => p.changerPrix(nouveauPrix));
  }

  @override
  Future<Produit> ajouterProduit({
    required String etalId,
    required String nom,
    required int prix,
    required UniteVente unite,
    required CategorieProduit categorie,
    String? description,
    String? photoUrl,
  }) async {
    await _db.reseau(latence);
    final produit = Produit(
      id: 'p-${DateTime.now().microsecondsSinceEpoch}', // id unique simulé
      etalId: etalId,
      nom: nom,
      prix: prix,
      unite: unite,
      categorie: categorie,
      prixMisAJourLe: DateTime.now(),
      description: description,
      photoUrl: photoUrl,
    );
    _db.produits.add(produit);
    return produit;
  }

  /// Remplace un produit de la liste par sa version modifiée.
  Produit _remplacer(String id, Produit Function(Produit) modification) {
    final index = _db.produits.indexWhere((p) => p.id == id);
    if (index == -1) throw StateError('Produit introuvable : $id');
    final modifie = modification(_db.produits[index]);
    _db.produits[index] = modifie;
    return modifie;
  }
}

// =====================================================================
//  COMMANDES
// =====================================================================
class MockCommandeRepository implements CommandeRepository {
  MockCommandeRepository(this._db, {this.latence = latenceParDefaut});

  final MockDatabase _db;
  final Duration latence;
  final Random _hasard = Random();

  @override
  Future<Commande> creerCommande({
    required String etalId,
    required String nomClient,
    required String telephoneClient,
    required List<LigneCommande> lignes,
    required ModeLivraison modeLivraison,
    required MoyenPaiement moyenPaiement,
    String? clientId,
    int fraisLivraison = 0,
    String? adresseLivraison,
    DateTime? heureRetrait,
    bool saisieAssistee = false,
  }) async {
    await _db.reseau(latence);
    if (lignes.isEmpty) {
      throw ArgumentError('Une commande doit contenir au moins un produit.');
    }
    final etal = _db.etals.firstWhere((e) => e.id == etalId);

    final commande = Commande(
      id: 'c-${_db.commandes.length + 1}',
      numero: _nouveauNumero(),
      etalId: etalId,
      nomEtal: etal.nom,
      clientId: clientId,
      nomClient: nomClient,
      telephoneClient: telephoneClient,
      lignes: lignes,
      modeLivraison: modeLivraison,
      fraisLivraison: modeLivraison == ModeLivraison.retrait ? 0 : fraisLivraison,
      adresseLivraison: adresseLivraison,
      heureRetrait: heureRetrait,
      moyenPaiement: moyenPaiement,
      // Simulation : un paiement Mobile Money réussit toujours en démo.
      statutPaiement: moyenPaiement.estMobileMoney
          ? StatutPaiement.paye
          : StatutPaiement.enAttente,
      creeLe: DateTime.now(),
      saisieAssistee: saisieAssistee,
    );
    _db.commandes.add(commande);
    return commande;
  }

  @override
  Future<Commande?> trouverCommande(String id) async {
    await _db.reseau(latence);
    return _db.commandes.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<Commande?> trouverParNumero(String numero) async {
    await _db.reseau(latence);
    final chiffres = numero.replaceAll(' ', ''); // accepte « 482 913 »
    return _db.commandes.where((c) => c.numero == chiffres).firstOrNull;
  }

  @override
  Future<List<Commande>> commandesDuClient(String clientId) async {
    await _db.reseau(latence);
    return _plusRecentesDabord(_db.commandes.where((c) => c.clientId == clientId));
  }

  @override
  Future<List<Commande>> commandesDeLEtal(String etalId) async {
    await _db.reseau(latence);
    return _plusRecentesDabord(_db.commandes.where((c) => c.etalId == etalId));
  }

  @override
  Future<List<Commande>> missionsDuLivreur(String livreurId) async {
    await _db.reseau(latence);
    return _plusRecentesDabord(_db.commandes.where((c) =>
        c.livreurId == livreurId &&
        (c.statut == StatutCommande.prete || c.statut == StatutCommande.enLivraison)));
  }

  @override
  Future<Commande> changerStatut(String commandeId, StatutCommande statut) async {
    await _db.reseau(latence);
    final index = _db.commandes.indexWhere((c) => c.id == commandeId);
    if (index == -1) throw StateError('Commande introuvable : $commandeId');

    final modifiee = _db.commandes[index].copyWith(
      statut: statut,
      // On note l'heure de confirmation (MAR-01).
      confirmeeLe: statut == StatutCommande.confirmee ? DateTime.now() : null,
    );
    _db.commandes[index] = modifiee;
    return modifiee;
  }

  @override
  Future<Commande?> validerRemise(String contenuQrOuNumero) async {
    await _db.reseau(latence);

    // Deux formats acceptés :
    //  - le contenu du ticket QR : « MC:CMD:c-1:482913 »
    //  - le code à 6 chiffres tapé à la main : « 482913 » ou « 482 913 »
    final texte = contenuQrOuNumero.trim();
    final numero = texte.startsWith('MC:CMD:')
        ? texte.split(':').last
        : texte.replaceAll(' ', '');

    final index = _db.commandes.indexWhere((c) => c.numero == numero);
    if (index == -1) return null; // QR inconnu

    final commande = _db.commandes[index];
    // On ne remet qu'une commande prête ou en cours de livraison.
    if (commande.statut != StatutCommande.prete &&
        commande.statut != StatutCommande.enLivraison) {
      return null;
    }
    final livree = commande.copyWith(
      statut: StatutCommande.livree,
      // Paiement à la livraison : encaissé au moment de la remise.
      statutPaiement: StatutPaiement.paye,
    );
    _db.commandes[index] = livree;
    return livree;
  }

  /// Numéro à 6 chiffres qui n'existe pas encore (100000 à 999999).
  String _nouveauNumero() {
    String numero;
    do {
      numero = (100000 + _hasard.nextInt(900000)).toString();
    } while (_db.commandes.any((c) => c.numero == numero));
    return numero;
  }

  /// Trie une liste de commandes de la plus récente à la plus ancienne.
  List<Commande> _plusRecentesDabord(Iterable<Commande> commandes) =>
      commandes.toList()..sort((a, b) => b.creeLe.compareTo(a.creeLe));
}
