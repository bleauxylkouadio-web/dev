// =====================================================================
//  commande_repository.dart : CONTRAT d'accès aux commandes
//  (modules Commande, Livraison, QR et mode assisté)
// =====================================================================

import '../models/models.dart';

abstract interface class CommandeRepository {
  /// Crée une commande (par le client, ou par le commerçant en mode assisté).
  /// Le serveur attribue l'identifiant et le numéro à 6 chiffres.
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
    Commune? communeLivraison,
    DateTime? heureRetrait,
    bool saisieAssistee = false,
  });

  /// Une commande par son identifiant.
  Future<Commande?> trouverCommande(String id);

  /// Une commande par son numéro à 6 chiffres (client sans smartphone
  /// qui donne son code au livreur ou au commerçant).
  Future<Commande?> trouverParNumero(String numero);

  /// Historique d'un client (le plus récent en premier).
  Future<List<Commande>> commandesDuClient(String clientId);

  /// Commandes reçues par un étal (« 3 nouvelles commandes »).
  Future<List<Commande>> commandesDeLEtal(String etalId);

  /// Commandes « Prête » ou « En livraison » d'un livreur.
  Future<List<Commande>> missionsDuLivreur(String livreurId);

  /// Commandes DISPONIBLES à livrer dans une commune : prêtes (ou
  /// confirmées, en préparation), à livrer, et sans livreur.
  /// Un livreur qui a déjà une course dans cette commune peut ainsi en
  /// prendre d'autres sur le même trajet (tournée).
  Future<List<Commande>> commandesDisponibles(Commune commune);

  /// Le livreur prend une commande disponible. Renvoie la commande
  /// (avec livreurId rempli), ou null si un autre livreur l'a prise avant.
  Future<Commande?> accepterLivraison(String commandeId, String livreurId);

  /// Fait avancer une commande : confirmer, prête, en livraison, annuler…
  Future<Commande> changerStatut(String commandeId, StatutCommande statut);

  /// Le livreur scanne le ticket QR (ou saisit le code à 6 chiffres).
  /// Renvoie la commande passée à « Livrée », ou `null` si le QR
  /// ne correspond à aucune commande remettable.
  Future<Commande?> validerRemise(String contenuQrOuNumero);
}
