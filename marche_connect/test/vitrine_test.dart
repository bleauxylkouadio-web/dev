// =====================================================================
//  vitrine_test.dart : tests des écrans Liste des étals et Vitrine
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marche_connect/core/router/app_router.dart';
import 'package:marche_connect/core/router/routes.dart';
import 'package:marche_connect/features/panier/panier_provider.dart';

import 'helpers.dart';

void main() {
  testWidgets('Filtre par commune : Treichville → seulement Pagnes Akissi', (tester) async {
    final c = conteneurDeTest();
    await lancerApp(tester, c);

    // La puce est hors de l'écran (ligne qui défile) : on la fait apparaître.
    final puce = find.widgetWithText(ChoiceChip, 'Treichville');
    await tester.ensureVisible(puce);
    await tester.pumpAndSettle();
    await tester.tap(puce);
    await tester.pumpAndSettle();

    expect(find.text('1 étal'), findsOneWidget);
    expect(find.text('Pagnes Akissi'), findsOneWidget);
    expect(find.text('Étal de Mariam'), findsNothing);
  });

  testWidgets('Recherche sans résultat → « Effacer les filtres »', (tester) async {
    final c = conteneurDeTest();
    await lancerApp(tester, c);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 500)); // anti-rebond
    await tester.pumpAndSettle();
    expect(find.text('Aucun étal trouvé'), findsOneWidget);

    await tester.tap(find.text('Effacer les filtres'));
    await tester.pumpAndSettle();
    expect(find.text('5 étals'), findsOneWidget);
  });

  testWidgets('Vitrine (scan du QR) : épuisé masqué, ajout au panier', (tester) async {
    final c = conteneurDeTest();
    await lancerApp(tester, c);

    c.read(routerProvider).push(Routes.etal('e-1'));
    await tester.pumpAndSettle();

    expect(find.text('Étal de Mariam'), findsWidgets);
    expect(find.text('Tomates'), findsOneWidget);
    expect(find.text('Piment frais'), findsNothing); // MAR-01

    await tester.tap(find.byTooltip('Ajouter au panier').first);
    await tester.pumpAndSettle();

    expect(find.text('Tomates ajouté au panier'), findsOneWidget);
    expect(find.text('Voir le panier'), findsOneWidget);
    expect(find.text('500 F'), findsOneWidget); // total dans la barre
    expect(c.read(panierProvider).quantiteDe('p-101'), 1);
  });

  testWidgets('QR inconnu → « Étal introuvable »', (tester) async {
    final c = conteneurDeTest();
    await lancerApp(tester, c);

    c.read(routerProvider).go(Routes.etal('xyz'));
    await tester.pumpAndSettle();
    expect(find.text('Étal introuvable'), findsOneWidget);
  });
}
