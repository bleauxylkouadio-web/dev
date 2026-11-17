// =====================================================================
//  commande.dart : une commande passée à un étal
//
//  Une commande = plusieurs LIGNES (un produit + une quantité chacune),
//  + le mode de livraison, le paiement et le statut.
//
//  Exigences couvertes :
//  - MAR-01 : le commerçant confirme sous 10 minutes
//  - MAR-02 : heure de retrait choisie
//  - MAR-03 : le prix de la commande est GARANTI (copié dans la ligne)
//  - ACH-03 : frais de livraison affichés avant validation
//  - Ticket QR + code à 6 chiffres (parcours QR, diapositive 7)
//  - Mode assisté : commande saisie par le commerçant ou un relais
// =====================================================================

import 'enums.dart';
import 'produit.dart';

// =====================================================================
//  LIGNE DE COMMANDE
// =====================================================================

/// Une ligne du panier ou de la commande : « Tomates x2 · 1 000 F ».
class LigneCommande {
  const LigneCommande({
    required this.produitId,
    required this.nomProduit,
    required this.prixUnitaire,
    required this.unite,
    required this.quantite,
  });

  /// Crée une ligne à partir d'un produit.
  ///
  /// MAR-03 : on COPIE le nom et le prix au moment de la commande.
  /// Si le commerçant change son prix ensuite, cette ligne ne bouge pas :
  /// le client paie le prix qu'il a vu.
  factory LigneCommande.depuisProduit(Produit produit, {double quantite = 1}) {
    return LigneCommande(
      produitId: produit.id,
      nomProduit: produit.nom,
      prixUnitaire: produit.prix,
      unite: produit.unite,
      quantite: quantite,
    );
  }

  final String produitId;

  /// Copie du nom (si le produit est renommé, le ticket reste juste).
  final String nomProduit;

  /// Prix d'UNE unité, figé au moment de la commande (MAR-03).
  final int prixUnitaire;

  final UniteVente unite;

  /// Quantité. `double` car on peut vendre au poids : 1,5 kg.
  final double quantite;

  /// Total de la ligne en F CFA, arrondi au franc près.
  int get total => (prixUnitaire * quantite).round();

  LigneCommande copyWith({double? quantite}) {
    return LigneCommande(
      produitId: produitId,
      nomProduit: nomProduit,
      prixUnitaire: prixUnitaire,
      unite: unite,
      quantite: quantite ?? this.quantite,
    );
  }

  factory LigneCommande.fromJson(Map<String, dynamic> json) {
    return LigneCommande(
      produitId: json['produitId'] as String,
      nomProduit: json['nomProduit'] as String,
      prixUnitaire: json['prixUnitaire'] as int,
      unite: UniteVente.values.byName(json['unite'] as String),
      quantite: (json['quantite'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'produitId': produitId,
        'nomProduit': nomProduit,
        'prixUnitaire': prixUnitaire,
        'unite': unite.name,
        'quantite': quantite,
      };
}

// =====================================================================
//  COMMANDE
// =====================================================================

class Commande {
  /// MAR-01 : délai laissé au commerçant pour confirmer.
  static const Duration delaiConfirmation = Duration(minutes: 10);

  const Commande({
    required this.id,
    required this.numero,
    required this.etalId,
    required this.nomEtal,
    required this.nomClient,
    required this.telephoneClient,
    required this.lignes,
    required this.modeLivraison,
    required this.moyenPaiement,
    required this.creeLe,
    this.clientId,
    this.fraisLivraison = 0,
    this.adresseLivraison,
    this.heureRetrait,
    this.statut = StatutCommande.enAttente,
    this.statutPaiement = StatutPaiement.enAttente,
    this.confirmeeLe,
    this.livreurId,
    this.saisieAssistee = false,
  });

  /// Identifiant technique unique (ex. "c-0001").
  final String id;

  /// Numéro à 6 chiffres, lisible par un humain : "482913".
  /// Il sert aussi de CODE pour les clients sans smartphone :
  /// ils le donnent au livreur si le ticket QR est abîmé.
  final String numero;

  final String etalId;

  /// Copie du nom de l'étal, pour afficher le ticket même hors ligne.
  final String nomEtal;

  /// Vide pour une commande en mode assisté (client sans compte).
  final String? clientId;

  final String nomClient;
  final String telephoneClient;

  /// Les produits commandés.
  final List<LigneCommande> lignes;

  final ModeLivraison modeLivraison;

  /// 0 pour un retrait ; 500 à 1 000 F pour une livraison (ACH-03).
  final int fraisLivraison;

  /// Adresse ou point de repère (« Derrière la pharmacie… »), si livraison.
  final String? adresseLivraison;

  /// MAR-02 : heure à laquelle le client passe chercher sa commande.
  final DateTime? heureRetrait;

  final MoyenPaiement moyenPaiement;
  final StatutCommande statut;
  final StatutPaiement statutPaiement;

  final DateTime creeLe;

  /// Moment où le commerçant a accepté la commande.
  final DateTime? confirmeeLe;

  /// Le livreur à qui la commande est confiée.
  final String? livreurId;

  /// Vrai si la commande a été saisie par le commerçant ou un relais
  /// pour un client sans smartphone (mode assisté).
  final bool saisieAssistee;

  // -------------------------------------------------------------------
  //  Calculs (getters) : jamais stockés, toujours recalculés
  // -------------------------------------------------------------------

  /// Somme des lignes, sans la livraison.
  int get sousTotal => lignes.fold(0, (somme, ligne) => somme + ligne.total);

  /// Montant à payer : « Payer 1 500 F ».
  int get total => sousTotal + fraisLivraison;

  /// Nombre de produits différents.
  int get nombreLignes => lignes.length;

  /// Numéro affiché sur le ticket : "482 913".
  String get numeroFormate =>
      numero.length == 6 ? '${numero.substring(0, 3)} ${numero.substring(3)}' : numero;

  /// Texte encodé dans le ticket QR, lu par le scanner du livreur.
  /// Le préfixe « MC » permet de rejeter tout QR qui ne vient pas de chez nous.
  String get contenuQr => 'MC:CMD:$id:$numero';

  /// Heure limite de confirmation par le commerçant (MAR-01).
  DateTime get limiteConfirmation => creeLe.add(delaiConfirmation);

  /// Vrai si la commande attend encore et que les 10 minutes sont passées.
  bool estEnRetardDeConfirmation(DateTime maintenant) =>
      statut == StatutCommande.enAttente && maintenant.isAfter(limiteConfirmation);

  Commande copyWith({
    StatutCommande? statut,
    StatutPaiement? statutPaiement,
    DateTime? confirmeeLe,
    String? livreurId,
  }) {
    return Commande(
      id: id,
      numero: numero,
      etalId: etalId,
      nomEtal: nomEtal,
      clientId: clientId,
      nomClient: nomClient,
      telephoneClient: telephoneClient,
      lignes: lignes,
      modeLivraison: modeLivraison,
      fraisLivraison: fraisLivraison,
      adresseLivraison: adresseLivraison,
      heureRetrait: heureRetrait,
      moyenPaiement: moyenPaiement,
      statut: statut ?? this.statut,
      statutPaiement: statutPaiement ?? this.statutPaiement,
      creeLe: creeLe,
      confirmeeLe: confirmeeLe ?? this.confirmeeLe,
      livreurId: livreurId ?? this.livreurId,
      saisieAssistee: saisieAssistee,
    );
  }

  factory Commande.fromJson(Map<String, dynamic> json) {
    // Petite fonction locale : lit une date qui peut être absente.
    DateTime? lireDate(String cle) =>
        json[cle] == null ? null : DateTime.parse(json[cle] as String);

    return Commande(
      id: json['id'] as String,
      numero: json['numero'] as String,
      etalId: json['etalId'] as String,
      nomEtal: json['nomEtal'] as String,
      clientId: json['clientId'] as String?,
      nomClient: json['nomClient'] as String,
      telephoneClient: json['telephoneClient'] as String,
      lignes: (json['lignes'] as List)
          .map((l) => LigneCommande.fromJson(l as Map<String, dynamic>))
          .toList(),
      modeLivraison: ModeLivraison.values.byName(json['modeLivraison'] as String),
      fraisLivraison: json['fraisLivraison'] as int? ?? 0,
      adresseLivraison: json['adresseLivraison'] as String?,
      heureRetrait: lireDate('heureRetrait'),
      moyenPaiement: MoyenPaiement.values.byName(json['moyenPaiement'] as String),
      statut: StatutCommande.values.byName(json['statut'] as String),
      statutPaiement: StatutPaiement.values.byName(json['statutPaiement'] as String),
      creeLe: DateTime.parse(json['creeLe'] as String),
      confirmeeLe: lireDate('confirmeeLe'),
      livreurId: json['livreurId'] as String?,
      saisieAssistee: json['saisieAssistee'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'numero': numero,
        'etalId': etalId,
        'nomEtal': nomEtal,
        'clientId': clientId,
        'nomClient': nomClient,
        'telephoneClient': telephoneClient,
        'lignes': lignes.map((l) => l.toJson()).toList(),
        'modeLivraison': modeLivraison.name,
        'fraisLivraison': fraisLivraison,
        'adresseLivraison': adresseLivraison,
        'heureRetrait': heureRetrait?.toIso8601String(),
        'moyenPaiement': moyenPaiement.name,
        'statut': statut.name,
        'statutPaiement': statutPaiement.name,
        'creeLe': creeLe.toIso8601String(),
        'confirmeeLe': confirmeeLe?.toIso8601String(),
        'livreurId': livreurId,
        'saisieAssistee': saisieAssistee,
      };
}
