// =====================================================================
//  mock_data.dart : DONNÉES DE DÉMONSTRATION
//
//  En attendant le back-end, l'application lit ces données.
//  Elles reprennent les exemples du cahier des charges (Étal de Mariam,
//  Tomates 1 kg à 500 F, Pagnes wax, Savon karité, ticket N° 482 913…).
//
//  MockDatabase garde les données EN MÉMOIRE : les modifications
//  (produit épuisé, nouvelle commande…) durent jusqu'à la fermeture de
//  l'application, puis tout revient à l'état de départ.
//
//  Comptes de démo (code OTP de démo : 123456) :
//    0701020304  → Awa, client
//    0505050505  → Mariam, commerçante (Étal de Mariam)
//    0102030405  → Ibrahim, livreur
//    0700000000  → Admin
// =====================================================================

import '../models/models.dart';

/// Code OTP accepté en mode démo (aucun SMS n'est envoyé).
const String codeOtpDemo = '123456';

class MockDatabase {
  /// Crée une base remplie. `maintenant` permet aux tests d'utiliser une
  /// date fixe ; dans l'application, c'est l'heure actuelle.
  MockDatabase({DateTime? maintenant}) {
    final now = maintenant ?? DateTime.now();
    utilisateurs = _utilisateurs();
    etals = _etals();
    produits = _produits(now);
    commandes = _commandes(now);
    litiges = _litiges(now);
  }

  // `late` = la variable sera remplie dans le constructeur, juste au-dessus.
  late final List<Utilisateur> utilisateurs;
  late final List<Etal> etals;
  // « final » protège la variable (on ne remplace pas la liste), mais le
  // CONTENU de la liste reste modifiable : on peut ajouter ou remplacer
  // un produit ou une commande.
  late final List<Produit> produits;
  late final List<Commande> commandes;
  late final List<Litige> litiges;

  /// Dernière position du livreur, par commande (suivi en direct).
  final Map<String, PositionLivreur> positions = {};

  // ===================================================================
  //  SIMULATION DU RÉSEAU
  //  Vrai = « coupure » : tous les appels échouent, comme sans connexion.
  //  Sert à tester le mode hors ligne (bouton 📶 en mode développement).
  // ===================================================================
  bool reseauCoupe = false;

  /// Attente réseau simulée, appelée au début de chaque méthode mock.
  Future<void> reseau(Duration latence) async {
    await Future<void>.delayed(latence);
    if (reseauCoupe) throw StateError('Pas de connexion (simulation)');
  }

  // ===================================================================
  //  LITIGES : un litige ouvert depuis 30 h (il reste 18 h, ACH-04)
  // ===================================================================
  static List<Litige> _litiges(DateTime now) => [
        Litige(
          id: 'l-1',
          commandeId: 'c-3',
          numeroCommande: '209377',
          nomEtal: 'Pagnes Akissi',
          nomClient: 'Awa Traoré',
          montantCommande: 9000,
          motif: MotifLitige.nonConforme,
          description: 'Le motif du pagne ne correspond pas à la photo.',
          creeLe: now.subtract(const Duration(hours: 30)),
        ),
      ];

  // ===================================================================
  //  UTILISATEURS
  // ===================================================================
  static List<Utilisateur> _utilisateurs() => [
        const Utilisateur(
          id: 'u-1',
          telephone: '0701020304',
          nom: 'Awa Traoré',
          role: Role.client,
          commune: Commune.cocody,
        ),
        const Utilisateur(
          id: 'u-2',
          telephone: '0505050505',
          nom: 'Mariam Koné',
          role: Role.commercant,
          commune: Commune.adjame,
          etalId: 'e-1',
        ),
        const Utilisateur(
          id: 'u-3',
          telephone: '0102030405',
          nom: 'Ibrahim Ouattara',
          role: Role.livreur,
          commune: Commune.adjame,
        ),
        const Utilisateur(
          id: 'u-4',
          telephone: '0700000000',
          nom: 'Administrateur',
          role: Role.admin,
        ),
      ];

  // ===================================================================
  //  ÉTALS : au moins un par commune pilote
  // ===================================================================
  static List<Etal> _etals() => [
        const Etal(
          id: 'e-1',
          nom: 'Étal de Mariam',
          nomCommercant: 'Mariam Koné',
          telephone: '0505050505',
          marche: "Grand marché d'Adjamé",
          commune: Commune.adjame,
          emplacement: 'Allée C, étal n° 14',
          categories: [CategorieProduit.legumes, CategorieProduit.epicerie],
          noteMoyenne: 4.6,
          nombreAvis: 23,
        ),
        const Etal(
          id: 'e-2',
          nom: 'Chez Tantie Awa',
          nomCommercant: 'Awa Diabaté',
          telephone: '0707070707',
          marche: 'Marché de Cocody',
          commune: Commune.cocody,
          emplacement: 'Espace restauration, n° 3',
          categories: [CategorieProduit.platsCuisines],
          noteMoyenne: 4.8,
          nombreAvis: 41,
          misEnAvant: true, // mise en avant payante : apparaît en premier
        ),
        const Etal(
          id: 'e-3',
          nom: 'Pagnes Akissi',
          nomCommercant: 'Akissi Yao',
          telephone: '0101010101',
          marche: 'Marché de Treichville',
          commune: Commune.treichville,
          emplacement: '1er étage, boutique 22',
          categories: [CategorieProduit.pagnes, CategorieProduit.beaute],
          noteMoyenne: 4.3,
          nombreAvis: 12,
        ),
        const Etal(
          id: 'e-4',
          nom: 'Vivriers Koffi',
          nomCommercant: 'Koffi Kouassi',
          telephone: '0565656565',
          marche: "Grand marché d'Abobo",
          commune: Commune.abobo,
          emplacement: 'Entrée nord, étal n° 7',
          categories: [CategorieProduit.vivriers, CategorieProduit.fruits],
          // Pas encore d'avis : affiché « Nouveau ».
        ),
        const Etal(
          id: 'e-5',
          nom: 'Poissonnerie Yao',
          nomCommercant: 'Yao Brou',
          telephone: '0787878787',
          marche: "Grand marché d'Adjamé",
          commune: Commune.adjame,
          emplacement: 'Halle aux poissons, n° 5',
          categories: [CategorieProduit.poissonViande],
          noteMoyenne: 4.1,
          nombreAvis: 8,
          ouvert: false, // fermé aujourd'hui
        ),
      ];

  // ===================================================================
  //  PRODUITS
  //  `il(h)` = « il y a h heures » : pour afficher des dates de prix
  //  réalistes (« mis à jour il y a 2 h »).
  // ===================================================================
  static List<Produit> _produits(DateTime now) {
    DateTime il(int heures) => now.subtract(Duration(hours: heures));

    return [
      // ---- e-1 : Étal de Mariam (maquette « Vitrine de l'étal ») ----
      Produit(id: 'p-101', etalId: 'e-1', nom: 'Tomates', prix: 500, unite: UniteVente.kg,
          categorie: CategorieProduit.legumes, prixMisAJourLe: il(2),
          description: 'Tomates fraîches de Bouaflé'),
      Produit(id: 'p-102', etalId: 'e-1', nom: 'Piment frais', prix: 300, unite: UniteVente.lot,
          categorie: CategorieProduit.legumes, prixMisAJourLe: il(5),
          disponible: false), // « Épuisé » sur la maquette
      Produit(id: 'p-103', etalId: 'e-1', nom: 'Oignons', prix: 700, unite: UniteVente.kg,
          categorie: CategorieProduit.legumes, prixMisAJourLe: il(26)),
      Produit(id: 'p-104', etalId: 'e-1', nom: 'Gombo', prix: 200, unite: UniteVente.lot,
          categorie: CategorieProduit.legumes, prixMisAJourLe: il(3),
          description: 'Tas de 10 gombos'),
      Produit(id: 'p-105', etalId: 'e-1', nom: 'Huile rouge 1 L', prix: 1200, unite: UniteVente.piece,
          categorie: CategorieProduit.epicerie, prixMisAJourLe: il(48)),

      // ---- e-2 : Chez Tantie Awa (plats cuisinés, vendus à la portion) ----
      Produit(id: 'p-201', etalId: 'e-2', nom: 'Attiéké poisson', prix: 1500, unite: UniteVente.portion,
          categorie: CategorieProduit.platsCuisines, prixMisAJourLe: il(1)),
      Produit(id: 'p-202', etalId: 'e-2', nom: 'Garba', prix: 1000, unite: UniteVente.portion,
          categorie: CategorieProduit.platsCuisines, prixMisAJourLe: il(1)),
      Produit(id: 'p-203', etalId: 'e-2', nom: 'Alloco', prix: 500, unite: UniteVente.portion,
          categorie: CategorieProduit.platsCuisines, prixMisAJourLe: il(4)),

      // ---- e-3 : Pagnes Akissi (maquette « Espace commerçant ») ----
      Produit(id: 'p-301', etalId: 'e-3', nom: 'Pagnes wax', prix: 8000, unite: UniteVente.piece,
          categorie: CategorieProduit.pagnes, prixMisAJourLe: il(72),
          description: '6 yards, motifs variés'),
      Produit(id: 'p-302', etalId: 'e-3', nom: 'Savon karité', prix: 500, unite: UniteVente.piece,
          categorie: CategorieProduit.beaute, prixMisAJourLe: il(30), disponible: false),
      Produit(id: 'p-303', etalId: 'e-3', nom: 'Beurre de cacao', prix: 1500, unite: UniteVente.piece,
          categorie: CategorieProduit.beaute, prixMisAJourLe: il(30)),

      // ---- e-4 : Vivriers Koffi ----
      Produit(id: 'p-401', etalId: 'e-4', nom: 'Igname', prix: 600, unite: UniteVente.kg,
          categorie: CategorieProduit.vivriers, prixMisAJourLe: il(6)),
      Produit(id: 'p-402', etalId: 'e-4', nom: 'Banane plantain', prix: 1000, unite: UniteVente.lot,
          categorie: CategorieProduit.vivriers, prixMisAJourLe: il(6),
          description: 'Régime de 6 bananes'),
      Produit(id: 'p-403', etalId: 'e-4', nom: 'Mangues', prix: 250, unite: UniteVente.piece,
          categorie: CategorieProduit.fruits, prixMisAJourLe: il(10)),

      // ---- e-5 : Poissonnerie Yao ----
      Produit(id: 'p-501', etalId: 'e-5', nom: 'Carpe fraîche', prix: 2500, unite: UniteVente.kg,
          categorie: CategorieProduit.poissonViande, prixMisAJourLe: il(20)),
    ];
  }

  // ===================================================================
  //  COMMANDES
  // ===================================================================
  static List<Commande> _commandes(DateTime now) {
    DateTime ilYa(int minutes) => now.subtract(Duration(minutes: minutes));

    return [
      // La commande de la maquette « Ticket QR » : N° 482 913, prête.
      Commande(
        id: 'c-1',
        numero: '482913',
        etalId: 'e-1',
        nomEtal: 'Étal de Mariam',
        clientId: 'u-1',
        nomClient: 'Awa Traoré',
        telephoneClient: '0701020304',
        lignes: const [
          LigneCommande(produitId: 'p-101', nomProduit: 'Tomates', prixUnitaire: 500,
              unite: UniteVente.kg, quantite: 2),
        ],
        modeLivraison: ModeLivraison.livraison,
        fraisLivraison: 500,
        adresseLivraison: 'Cocody Angré, près de la pharmacie du 8e tranche',
        communeLivraison: Commune.cocody,
        moyenPaiement: MoyenPaiement.wave,
        statut: StatutCommande.prete,
        statutPaiement: StatutPaiement.paye,
        creeLe: ilYa(45),
        confirmeeLe: ilYa(42),
        livreurId: 'u-3',
      ),
      // Commande en MODE ASSISTÉ, saisie par Mariam pour une cliente
      // sans smartphone, en attente de confirmation (il reste 7 min).
      Commande(
        id: 'c-2',
        numero: '731054',
        etalId: 'e-1',
        nomEtal: 'Étal de Mariam',
        nomClient: 'Maman Adjoua',
        telephoneClient: '0708091011',
        lignes: const [
          LigneCommande(produitId: 'p-103', nomProduit: 'Oignons', prixUnitaire: 700,
              unite: UniteVente.kg, quantite: 1.5),
          LigneCommande(produitId: 'p-104', nomProduit: 'Gombo', prixUnitaire: 200,
              unite: UniteVente.lot, quantite: 2),
        ],
        modeLivraison: ModeLivraison.retrait,
        heureRetrait: now.add(const Duration(hours: 1)),
        moyenPaiement: MoyenPaiement.aLaLivraison,
        creeLe: ilYa(3),
        saisieAssistee: true,
      ),
      // Une commande ancienne, déjà livrée (historique d'Awa).
      Commande(
        id: 'c-3',
        numero: '209377',
        etalId: 'e-3',
        nomEtal: 'Pagnes Akissi',
        clientId: 'u-1',
        nomClient: 'Awa Traoré',
        telephoneClient: '0701020304',
        lignes: const [
          LigneCommande(produitId: 'p-301', nomProduit: 'Pagnes wax', prixUnitaire: 8000,
              unite: UniteVente.piece, quantite: 1),
        ],
        modeLivraison: ModeLivraison.livraison,
        fraisLivraison: 1000,
        adresseLivraison: 'Cocody Riviera 2',
        communeLivraison: Commune.cocody,
        moyenPaiement: MoyenPaiement.orangeMoney,
        statut: StatutCommande.livree,
        statutPaiement: StatutPaiement.paye,
        creeLe: now.subtract(const Duration(days: 3)),
        confirmeeLe: now.subtract(const Duration(days: 3)),
        livreurId: 'u-3',
      ),

      // ---- Commandes DISPONIBLES (prêtes, sans livreur) ----
      // Deux à livrer à Cocody, comme la course d'Ibrahim (c-1) :
      // il peut les prendre sur le même trajet.
      Commande(
        id: 'c-4',
        numero: '615208',
        etalId: 'e-2',
        nomEtal: 'Chez Tantie Awa',
        nomClient: 'Fatou Bamba',
        telephoneClient: '0711223344',
        lignes: const [
          LigneCommande(produitId: 'p-201', nomProduit: 'Attiéké poisson', prixUnitaire: 1500,
              unite: UniteVente.portion, quantite: 2),
        ],
        modeLivraison: ModeLivraison.livraison,
        fraisLivraison: 500,
        adresseLivraison: 'Riviera 3, résidence Les Palmiers',
        communeLivraison: Commune.cocody,
        moyenPaiement: MoyenPaiement.wave,
        statut: StatutCommande.prete,
        statutPaiement: StatutPaiement.paye,
        creeLe: ilYa(30),
        confirmeeLe: ilYa(28),
      ),
      Commande(
        id: 'c-5',
        numero: '904731',
        etalId: 'e-1',
        nomEtal: 'Étal de Mariam',
        nomClient: 'Serge Kouamé',
        telephoneClient: '0544556677',
        lignes: const [
          LigneCommande(produitId: 'p-101', nomProduit: 'Tomates', prixUnitaire: 500,
              unite: UniteVente.kg, quantite: 3),
        ],
        modeLivraison: ModeLivraison.livraison,
        fraisLivraison: 1000,
        adresseLivraison: '2 Plateaux Vallons, rue des Jardins',
        communeLivraison: Commune.cocody,
        moyenPaiement: MoyenPaiement.aLaLivraison,
        statut: StatutCommande.prete,
        creeLe: ilYa(20),
        confirmeeLe: ilYa(18),
      ),
      // Une à livrer à Abobo : un livreur de Cocody ne la voit pas.
      Commande(
        id: 'c-6',
        numero: '337460',
        etalId: 'e-4',
        nomEtal: 'Vivriers Koffi',
        nomClient: 'Aminata Coulibaly',
        telephoneClient: '0122334455',
        lignes: const [
          LigneCommande(produitId: 'p-401', nomProduit: 'Igname', prixUnitaire: 600,
              unite: UniteVente.kg, quantite: 5),
        ],
        modeLivraison: ModeLivraison.livraison,
        fraisLivraison: 500,
        adresseLivraison: 'Abobo Gare, derrière la mairie',
        communeLivraison: Commune.abobo,
        moyenPaiement: MoyenPaiement.mtnMomo,
        statut: StatutCommande.prete,
        statutPaiement: StatutPaiement.paye,
        creeLe: ilYa(15),
        confirmeeLe: ilYa(12),
      ),
    ];
  }
}
