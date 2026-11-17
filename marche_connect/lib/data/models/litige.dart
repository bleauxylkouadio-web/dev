// =====================================================================
//  litige.dart : un PROBLÈME signalé par un client sur une commande
//
//  Exigence ACH-04 : « Signalement d'un produit non conforme ; litige
//  traité sous 48 h ». La bonne qualité est le critère le plus cité
//  par les clients interrogés.
// =====================================================================

/// Raison du signalement (choix rapide, sans avoir à écrire).
enum MotifLitige {
  nonConforme('Produit non conforme'),
  manquant('Produit manquant'),
  qualite('Mauvaise qualité'),
  retard('Livraison en retard'),
  autre('Autre problème');

  const MotifLitige(this.libelle);
  final String libelle;
}

enum StatutLitige {
  ouvert('À traiter'),
  rembourse('Client remboursé'),
  rejete('Rejeté');

  const StatutLitige(this.libelle);
  final String libelle;
}

class Litige {
  /// ACH-04 : délai maximum de traitement.
  static const Duration delaiTraitement = Duration(hours: 48);

  const Litige({
    required this.id,
    required this.commandeId,
    required this.numeroCommande,
    required this.nomEtal,
    required this.nomClient,
    required this.montantCommande,
    required this.motif,
    required this.creeLe,
    this.description = '',
    this.statut = StatutLitige.ouvert,
    this.reponse,
    this.traiteLe,
  });

  final String id;
  final String commandeId;

  /// Copies d'informations de la commande, pour l'affichage.
  final String numeroCommande;
  final String nomEtal;
  final String nomClient;
  final int montantCommande;

  final MotifLitige motif;

  /// Explication libre du client (facultative).
  final String description;

  final DateTime creeLe;
  final StatutLitige statut;

  /// Réponse de l'administrateur, envoyée au client.
  final String? reponse;
  final DateTime? traiteLe;

  /// Date limite de traitement (créé + 48 h).
  DateTime get limiteTraitement => creeLe.add(delaiTraitement);

  bool get estOuvert => statut == StatutLitige.ouvert;

  /// « 209 377 » (même format que Commande.numeroFormate).
  String get numeroFormate => numeroCommande.length == 6
      ? '${numeroCommande.substring(0, 3)} ${numeroCommande.substring(3)}'
      : numeroCommande;

  /// Vrai si le litige est encore ouvert après 48 h.
  bool estEnRetard(DateTime maintenant) => estOuvert && maintenant.isAfter(limiteTraitement);

  Litige copyWith({StatutLitige? statut, String? reponse, DateTime? traiteLe}) {
    return Litige(
      id: id,
      commandeId: commandeId,
      numeroCommande: numeroCommande,
      nomEtal: nomEtal,
      nomClient: nomClient,
      montantCommande: montantCommande,
      motif: motif,
      creeLe: creeLe,
      description: description,
      statut: statut ?? this.statut,
      reponse: reponse ?? this.reponse,
      traiteLe: traiteLe ?? this.traiteLe,
    );
  }
}
