// =====================================================================
//  models_test.dart : tests des règles métier des modèles
//
//  Lancer :  flutter test
//  Chaque test() vérifie UNE règle du cahier des charges.
// =====================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:marche_connect/data/models/models.dart';

void main() {
  // Un produit de test, réutilisé par plusieurs tests.
  final tomates = Produit(
    id: 'p-1',
    etalId: 'e-1',
    nom: 'Tomates',
    prix: 500,
    unite: UniteVente.kg,
    categorie: CategorieProduit.legumes,
    prixMisAJourLe: DateTime(2026, 11, 17, 8),
  );

  // Une commande de test : 2 kg de tomates + 500 F de livraison.
  Commande commandeDeTest({DateTime? creeLe}) => Commande(
        id: 'c-1',
        numero: '482913',
        etalId: 'e-1',
        nomEtal: 'Étal de Mariam',
        nomClient: 'Awa',
        telephoneClient: '0701020304',
        lignes: [LigneCommande.depuisProduit(tomates, quantite: 2)],
        modeLivraison: ModeLivraison.livraison,
        fraisLivraison: 500,
        moyenPaiement: MoyenPaiement.wave,
        creeLe: creeLe ?? DateTime(2026, 11, 17, 10),
      );

  test('Total = lignes + livraison (maquette : 1 000 + 500 = 1 500 F)', () {
    final commande = commandeDeTest();
    expect(commande.sousTotal, 1000);
    expect(commande.total, 1500);
  });

  test('MAR-02 : vente au poids, 1,5 kg à 500 F = 750 F', () {
    final ligne = LigneCommande.depuisProduit(tomates, quantite: 1.5);
    expect(ligne.total, 750);
  });

  test('MAR-03 : le prix de la commande est garanti', () {
    final ligne = LigneCommande.depuisProduit(tomates, quantite: 2);
    // Le commerçant augmente son prix APRÈS la commande…
    final tomatesPlusCheres = tomates.changerPrix(700);
    expect(tomatesPlusCheres.prix, 700);
    // … mais la ligne garde l'ancien prix.
    expect(ligne.prixUnitaire, 500);
    expect(ligne.total, 1000);
  });

  test('UX-04 / MAR-01 : épuisé en un geste, puis masqué au client', () {
    final epuise = tomates.basculerDisponibilite();
    expect(epuise.disponible, isFalse);
    expect(epuise.visibleParClient, isFalse);
    // Un deuxième geste le remet en vente.
    expect(epuise.basculerDisponibilite().disponible, isTrue);
  });

  test('MAR-01 : retard de confirmation après 10 minutes', () {
    final commande = commandeDeTest(creeLe: DateTime(2026, 11, 17, 10, 0));
    expect(commande.estEnRetardDeConfirmation(DateTime(2026, 11, 17, 10, 9)), isFalse);
    expect(commande.estEnRetardDeConfirmation(DateTime(2026, 11, 17, 10, 11)), isTrue);
  });

  test('Ticket : numéro formaté et contenu du QR', () {
    final commande = commandeDeTest();
    expect(commande.numeroFormate, '482 913');
    expect(commande.contenuQr, 'MC:CMD:c-1:482913');
  });

  test('JSON : une commande envoyée puis relue reste identique', () {
    final origine = commandeDeTest();
    final relue = Commande.fromJson(origine.toJson());
    expect(relue.toJson(), origine.toJson());
  });

  test('Téléphone affiché par paires : 07 01 02 03 04', () {
    const awa = Utilisateur(
      id: 'u-1',
      telephone: '0701020304',
      nom: 'Awa',
      role: Role.client,
    );
    expect(awa.telephoneFormate, '07 01 02 03 04');
  });
}
