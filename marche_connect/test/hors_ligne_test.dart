// =====================================================================
//  hors_ligne_test.dart : mode hors ligne (UX-03) et panier conservé (MAR-04)
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marche_connect/core/router/app_router.dart';
import 'package:marche_connect/core/router/routes.dart';
import 'package:marche_connect/data/local/etat_reseau.dart';
import 'package:marche_connect/data/local/stockage_local.dart';
import 'package:marche_connect/data/models/models.dart';
import 'package:marche_connect/data/repositories/providers.dart';
import 'package:marche_connect/features/panier/panier_provider.dart';

import 'helpers.dart';

void main() {
  test('Catalogue : après une coupure, la dernière copie est servie', () async {
    final c = conteneurDeTest();
    final db = c.read(mockDatabaseProvider);
    final repo = c.read(etalRepositoryProvider);

    // 1. En ligne : la liste est chargée (et enregistrée).
    expect((await repo.listerEtals()).length, 5);
    expect(c.read(etatReseauProvider).horsLigne, isFalse);

    // 2. Coupure : la liste vient du téléphone, filtres compris.
    db.reseauCoupe = true;
    final adjame = await repo.listerEtals(commune: Commune.adjame);
    expect(adjame.map((e) => e.nom), containsAll(['Étal de Mariam', 'Poissonnerie Yao']));
    expect(c.read(etatReseauProvider).horsLigne, isTrue);

    // 3. Retour du réseau : le bandeau disparaît.
    db.reseauCoupe = false;
    await repo.listerEtals();
    expect(c.read(etatReseauProvider).horsLigne, isFalse);
  });

  test('Produits : vitrine consultable hors ligne, épuisés toujours masqués', () async {
    final c = conteneurDeTest();
    final db = c.read(mockDatabaseProvider);
    final repo = c.read(produitRepositoryProvider);

    await repo.listerProduits('e-1');
    db.reseauCoupe = true;
    final horsLigne = await repo.listerProduits('e-1');
    expect(horsLigne.any((p) => p.nom == 'Tomates'), isTrue);
    expect(horsLigne.any((p) => p.nom == 'Piment frais'), isFalse); // MAR-01
  });

  test('Coupure sans aucune copie enregistrée : erreur (bouton Réessayer)', () async {
    final c = conteneurDeTest();
    c.read(mockDatabaseProvider).reseauCoupe = true;
    expect(() => c.read(etalRepositoryProvider).listerEtals(), throwsA(isA<StateError>()));
  });

  test('MAR-04 : le panier survit à la fermeture de l\'application', () async {
    // Le même stockage pour deux « lancements » successifs.
    final stockage = StockageMemoire();

    final premier = ProviderContainer(overrides: [stockageLocalProvider.overrideWithValue(stockage)]);
    final db = premier.read(mockDatabaseProvider);
    premier.read(panierProvider.notifier).ajouter(
          db.produits.firstWhere((p) => p.id == 'p-101'),
          db.etals.firstWhere((e) => e.id == 'e-1'),
        );
    premier.dispose(); // l'application est fermée

    final second = ProviderContainer(overrides: [stockageLocalProvider.overrideWithValue(stockage)]);
    addTearDown(second.dispose);
    final panier = second.read(panierProvider);
    expect(panier.nomEtal, 'Étal de Mariam');
    expect(panier.quantiteDe('p-101'), 1);
    expect(panier.sousTotal, 500);
  });

  testWidgets('Écran : bandeau « Hors ligne » sur la liste des étals', (tester) async {
    final c = conteneurDeTest();
    await lancerApp(tester, c); // première visite en ligne : catalogue enregistré
    expect(find.textContaining('Hors ligne'), findsNothing);

    c.read(mockDatabaseProvider).reseauCoupe = true;
    c.read(routerProvider).go(Routes.etal('e-1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hors ligne · données du'), findsOneWidget);
    expect(find.text('Tomates'), findsNothing); // produits jamais chargés pour cet étal
  });
}
