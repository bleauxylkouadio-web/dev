// =====================================================================
//  routes.dart : TOUTES LES ADRESSES de l'application
//
//  Chaque écran a une adresse, comme une page web. Sur la PWA, elle
//  s'affiche dans la barre du navigateur : https://…/etal/e-1
//
//  On écrit les adresses UNE seule fois ici, puis on les utilise ainsi :
//    context.go(Routes.etals);
//    context.push(Routes.etal('e-1'));
//  Une faute de frappe devient une erreur de compilation au lieu d'une
//  page blanche.
// =====================================================================

abstract final class Routes {
  // ---------------- Publiques (sans compte, UX-01) ----------------

  /// Connexion par téléphone + code OTP.
  static const connexion = '/connexion';

  /// Accueil client : liste des étals avec filtres.
  static const etals = '/etals';

  /// Vitrine d'un étal. ⭐ C'est l'adresse encodée dans le QR plastifié
  /// de l'étal : scanner le QR ouvre directement cette page, sans
  /// installation (parcours QR, diapositive 7).
  static const etalModele = '/etal/:id';
  static String etal(String id) => '/etal/$id';

  /// Panier (consultable sans compte).
  static const panier = '/panier';

  /// Ticket QR d'une commande (peut être ouvert par un proche ou un relais).
  static const ticketModele = '/ticket/:id';
  static String ticket(String id) => '/ticket/$id';

  // ---------------- Client connecté ----------------

  /// Choix du paiement et validation de la commande.
  static const paiement = '/paiement';

  /// Historique et suivi des commandes.
  static const mesCommandes = '/commandes';

  // ---------------- Par rôle ----------------

  /// Espace commerçant : mes produits, commandes reçues, mode assisté.
  static const commercant = '/commercant';

  /// Mode assisté : saisir la commande d'un client sans smartphone.
  static const commercantAssiste = '/commercant/assiste';

  /// Formulaire « + Photo et prix » : nouveau produit.
  static const commercantNouveauProduit = '/commercant/produit/nouveau';

  /// Espace livreur : missions et scan du ticket QR.
  static const livreur = '/livreur';

  /// Scan du ticket QR avec la caméra.
  static const livreurScan = '/livreur/scan';

  /// Back-office administrateur.
  static const admin = '/admin';
}
