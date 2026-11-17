// =====================================================================
//  enums.dart : les LISTES DE VALEURS FIXES de l'application
//
//  Un « enum » (énumération) est un type qui ne peut prendre QUE
//  certaines valeurs. Exemple : une commune est forcément Cocody, Abobo,
//  Adjamé ou Treichville. Impossible d'écrire « Cocodi » par erreur :
//  le code ne compilerait pas.
//
//  Chaque enum a un `libelle` = le texte affiché à l'écran, en français.
//  Pour le stockage (API, hors ligne), on utilise `.name` (ex. "cocody").
// =====================================================================

/// Les 4 communes du pilote (cahier des charges, diapositive 4).
enum Commune {
  cocody('Cocody'),
  abobo('Abobo'),
  adjame('Adjamé'),
  treichville('Treichville');

  const Commune(this.libelle);

  /// Texte affiché à l'utilisateur.
  final String libelle;
}

/// Les rôles d'un compte (module « Compte » : client, commerçant, livreur
/// + administrateur pour le back-office).
enum Role {
  client('Client'),
  commercant('Commerçant'),
  livreur('Livreur'),
  admin('Administrateur');

  const Role(this.libelle);
  final String libelle;
}

/// Catégories de produits, utilisées pour les filtres de recherche.
enum CategorieProduit {
  legumes('Légumes'),
  fruits('Fruits'),
  vivriers('Vivriers'), // igname, banane plantain, manioc, riz…
  poissonViande('Poisson et viande'),
  platsCuisines('Plats cuisinés'), // attiéké, garba, alloco…
  epicerie('Épicerie'),
  pagnes('Pagnes et tissus'),
  beaute('Beauté et cosmétiques'), // savon, beurre de karité…
  autres('Autres');

  const CategorieProduit(this.libelle);
  final String libelle;
}

/// Façon de vendre un produit (exigence MAR-02 : au poids, au lot ou à la pièce).
enum UniteVente {
  kg('kg', 'au kilo'),
  lot('lot', 'au lot'), // ex. tas de 5 tomates
  piece('pièce', 'à la pièce'),
  portion('portion', 'la portion'); // plats cuisinés

  const UniteVente(this.symbole, this.libelle);

  /// Forme courte, affichée après le prix : « 500 F / kg ».
  final String symbole;

  /// Forme longue : « Vendu au kilo ».
  final String libelle;
}

/// Retrait sur place ou livraison (module « Livraison »).
enum ModeLivraison {
  retrait('Retrait à l\'étal'),
  livraison('Livraison');

  const ModeLivraison(this.libelle);
  final String libelle;
}

/// Moyens de paiement (exigence ACH-02).
enum MoyenPaiement {
  wave('Wave'),
  orangeMoney('Orange Money'),
  mtnMomo('MTN MoMo'),
  moovMoney('Moov Money'),
  aLaLivraison('Paiement à la livraison');

  const MoyenPaiement(this.libelle);
  final String libelle;

  /// Vrai pour les 4 Mobile Money, faux pour le paiement à la livraison.
  bool get estMobileMoney => this != MoyenPaiement.aLaLivraison;
}

/// État du paiement d'une commande.
enum StatutPaiement {
  enAttente('En attente'),
  paye('Payé'),
  echoue('Échoué'),
  rembourse('Remboursé');

  const StatutPaiement(this.libelle);
  final String libelle;
}

/// Les étapes de vie d'une commande, dans l'ordre.
///
/// enAttente → confirmee → prete → enLivraison → livree
///                 ↘ (refus ou délai de 10 min dépassé) annulee
enum StatutCommande {
  enAttente('En attente de confirmation'), // MAR-01 : le commerçant a 10 min
  confirmee('Confirmée'),
  prete('Prête'), // « Prête · à remettre au livreur » (maquette Ticket QR)
  enLivraison('En livraison'),
  livree('Livrée'), // validée par le scan du ticket QR
  annulee('Annulée');

  const StatutCommande(this.libelle);
  final String libelle;

  /// Vrai quand la commande est terminée (plus aucune action possible).
  bool get estTerminee =>
      this == StatutCommande.livree || this == StatutCommande.annulee;
}
