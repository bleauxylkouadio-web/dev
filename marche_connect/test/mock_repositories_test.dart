// =====================================================================
//  mock_repositories_test.dart : tests des repositories simulés
//
//  Chaque test crée une base neuve (setUp) : les tests ne se gênent pas.
//  `latence: Duration.zero` = pas d'attente réseau simulée.
// =====================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:marche_connect/data/mock/mock_data.dart';
import 'package:marche_connect/data/mock/mock_repositories.dart';
import 'package:marche_connect/data/models/models.dart';

void main() {
  late MockDatabase db;
  late MockAuthRepository auth;
  late MockEtalRepository etals;
  late MockProduitRepository produits;
  late MockCommandeRepository commandes;

  // setUp est exécuté AVANT chaque test.
  setUp(() {
    db = MockDatabase();
    auth = MockAuthRepository(db, latence: Duration.zero);
    etals = MockEtalRepository(db, latence: Duration.zero);
    produits = MockProduitRepository(db, latence: Duration.zero);
    commandes = MockCommandeRepository(db, latence: Duration.zero);
  });

  group('Connexion', () {
    test('Bon code OTP : on récupère le compte de Mariam (commerçante)', () async {
      final u = await auth.verifierCode('0505050505', codeOtpDemo);
      expect(u?.role, Role.commercant);
      expect(u?.etalId, 'e-1');
    });

    test('Mauvais code OTP : connexion refusée', () async {
      expect(await auth.verifierCode('0505050505', '000000'), isNull);
    });

    test('Nouveau numéro : inscription automatique comme client', () async {
      final u = await auth.verifierCode('0799999999', codeOtpDemo);
      expect(u?.role, Role.client);
    });
  });

  group('Étals', () {
    test('Filtre par commune : Adjamé', () async {
      final liste = await etals.listerEtals(commune: Commune.adjame);
      expect(liste.every((e) => e.commune == Commune.adjame), isTrue);
      expect(liste, isNotEmpty);
    });

    test("L'étal mis en avant apparaît en premier", () async {
      final liste = await etals.listerEtals();
      expect(liste.first.misEnAvant, isTrue);
    });

    test('Recherche par nom de marché', () async {
      final liste = await etals.listerEtals(recherche: 'treichville');
      expect(liste.single.nom, 'Pagnes Akissi');
    });
  });

  group('Produits', () {
    test('MAR-01 : le client ne voit pas le piment épuisé, le commerçant si', () async {
      final client = await produits.listerProduits('e-1');
      final commercant = await produits.listerProduits('e-1', inclureEpuises: true);
      expect(client.any((p) => p.nom == 'Piment frais'), isFalse);
      expect(commercant.any((p) => p.nom == 'Piment frais'), isTrue);
    });

    test('UX-04 : marquer les tomates épuisées les masque au client', () async {
      await produits.basculerDisponibilite('p-101');
      final client = await produits.listerProduits('e-1');
      expect(client.any((p) => p.id == 'p-101'), isFalse);
    });
  });

  group('Commandes', () {
    test('Création : numéro à 6 chiffres et frais de livraison', () async {
      final tomates = (await produits.trouverProduit('p-101'))!;
      final c = await commandes.creerCommande(
        etalId: 'e-1',
        nomClient: 'Awa',
        telephoneClient: '0701020304',
        lignes: [LigneCommande.depuisProduit(tomates, quantite: 2)],
        modeLivraison: ModeLivraison.livraison,
        fraisLivraison: 500,
        moyenPaiement: MoyenPaiement.wave,
      );
      expect(c.numero.length, 6);
      expect(c.total, 1500);
      expect(c.statut, StatutCommande.enAttente);
    });

    test('Retrait à l\'étal : pas de frais de livraison', () async {
      final tomates = (await produits.trouverProduit('p-101'))!;
      final c = await commandes.creerCommande(
        etalId: 'e-1',
        nomClient: 'Awa',
        telephoneClient: '0701020304',
        lignes: [LigneCommande.depuisProduit(tomates)],
        modeLivraison: ModeLivraison.retrait,
        fraisLivraison: 500, // ignoré pour un retrait
        moyenPaiement: MoyenPaiement.aLaLivraison,
      );
      expect(c.fraisLivraison, 0);
    });

    test('Scan du ticket QR par le livreur : la commande passe à Livrée', () async {
      final c = await commandes.validerRemise('MC:CMD:c-1:482913');
      expect(c?.statut, StatutCommande.livree);
    });

    test('Code à 6 chiffres tapé à la main (client sans smartphone)', () async {
      final c = await commandes.validerRemise('482 913');
      expect(c?.statut, StatutCommande.livree);
    });

    test('Un QR inconnu est refusé', () async {
      expect(await commandes.validerRemise('MC:CMD:x:000000'), isNull);
    });

    test('Commandes de l\'étal : la plus récente en premier', () async {
      final liste = await commandes.commandesDeLEtal('e-1');
      expect(liste.first.id, 'c-2'); // passée il y a 3 min
    });
  });
}
