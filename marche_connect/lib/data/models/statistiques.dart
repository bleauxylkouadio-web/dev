// =====================================================================
//  statistiques.dart : les CHIFFRES CLÉS du back-office
//
//  Calculés par le serveur (ici par le mock) et simplement affichés
//  par le tableau de bord de l'administrateur.
// =====================================================================

import 'enums.dart';

class Statistiques {
  const Statistiques({
    required this.nombreCommandes,
    required this.commandesParStatut,
    required this.chiffreAffaires,
    required this.commissions,
    required this.fraisLivraison,
    required this.nombreEtals,
    required this.nombreClients,
    required this.nombreLivreurs,
    required this.etalsParCommune,
    required this.commandesAssistees,
    required this.litigesOuverts,
  });

  final int nombreCommandes;
  final Map<StatutCommande, int> commandesParStatut;

  /// Montant des produits des commandes livrées (F CFA).
  final int chiffreAffaires;

  /// Commission de la plateforme sur ce chiffre d'affaires (F CFA).
  final int commissions;

  /// Total des frais de livraison des commandes livrées (F CFA).
  final int fraisLivraison;

  final int nombreEtals;
  final int nombreClients;
  final int nombreLivreurs;
  final Map<Commune, int> etalsParCommune;

  /// Commandes saisies en mode assisté (clients sans smartphone) :
  /// indicateur clé du pilote (inclusion).
  final int commandesAssistees;

  final int litigesOuverts;
}
