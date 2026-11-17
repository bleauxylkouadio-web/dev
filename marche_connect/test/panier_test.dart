// =====================================================================
//  panier_test.dart : tests de la logique du panier
// =====================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:marche_connect/data/mock/mock_data.dart';
import 'package:marche_connect/features/panier/panier_provider.dart';

import 'helpers.dart';

void main() {
  final db = MockDatabase();
  final mariam = db.etals.firstWhere((e) => e.id == 'e-1');
  final akissi = db.etals.firstWhere((e) => e.id == 'e-3');
  final tomates = db.produits.firstWhere((p) => p.id == 'p-101'); // 500 F / kg
  final oignons = db.produits.firstWhere((p) => p.id == 'p-103'); // 700 F / kg
  final pagne = db.produits.firstWhere((p) => p.id == 'p-301');

  test('Ajouter deux fois le même produit augmente la quantité', () {
    final c = conteneurDeTest();
    final panier = c.read(panierProvider.notifier);

    panier.ajouter(tomates, mariam);
    panier.ajouter(tomates, mariam);
    panier.ajouter(oignons, mariam);

    final etat = c.read(panierProvider);
    expect(etat.nombreLignes, 2);
    expect(etat.quantiteDe('p-101'), 2);
    expect(etat.sousTotal, 2 * 500 + 700);
    expect(etat.nomEtal, 'Étal de Mariam');
  });

  test('Un panier = un seul étal : ajout d\'un autre étal refusé', () {
    final c = conteneurDeTest();
    final panier = c.read(panierProvider.notifier);

    panier.ajouter(tomates, mariam);
    expect(panier.ajouter(pagne, akissi), ResultatAjout.autreEtal);
    expect(c.read(panierProvider).etalId, 'e-1'); // inchangé

    panier.viderEtAjouter(pagne, akissi);
    expect(c.read(panierProvider).etalId, 'e-3');
    expect(c.read(panierProvider).nombreLignes, 1);
  });

  test('Quantité à 0 : la ligne est retirée, le panier redevient vide', () {
    final c = conteneurDeTest();
    final panier = c.read(panierProvider.notifier);

    panier.ajouter(tomates, mariam);
    panier.changerQuantite('p-101', 0);
    expect(c.read(panierProvider).estVide, isTrue);
    expect(c.read(panierProvider).etalId, isNull);
  });
}
