// =====================================================================
//  widgets_test.dart : tests des widgets communs
//
//  testWidgets construit le widget dans un écran virtuel, puis on peut
//  chercher des textes (find.text) et simuler des appuis (tester.tap).
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marche_connect/core/theme/app_theme.dart';
import 'package:marche_connect/core/widgets/widgets.dart';
import 'package:marche_connect/data/models/models.dart';

/// Enveloppe un widget dans une application minimale avec notre thème.
Widget enveloppe(Widget enfant) => MaterialApp(
      theme: AppTheme.clair,
      home: Scaffold(body: enfant),
    );

void main() {
  final tomates = Produit(
    id: 'p-1',
    etalId: 'e-1',
    nom: 'Tomates',
    prix: 500,
    unite: UniteVente.kg,
    categorie: CategorieProduit.legumes,
    prixMisAJourLe: DateTime.now().subtract(const Duration(hours: 2)),
  );

  testWidgets('Mode client : prix, date, et appui sur Ajouter', (tester) async {
    var appuis = 0;
    await tester.pumpWidget(enveloppe(
      CarteProduit(produit: tomates, onAjouter: () => appuis++),
    ));

    expect(find.text('Tomates'), findsOneWidget);
    expect(find.text('500 F / kg'), findsOneWidget);
    expect(find.text('Prix mis à jour il y a 2 h'), findsOneWidget);

    await tester.tap(find.byTooltip('Ajouter au panier'));
    expect(appuis, 1);
  });

  testWidgets('Mode client : un produit épuisé affiche « Épuisé », sans bouton', (tester) async {
    await tester.pumpWidget(enveloppe(
      CarteProduit(produit: tomates.copyWith(disponible: false), onAjouter: () {}),
    ));
    expect(find.text('Épuisé'), findsOneWidget);
    expect(find.byTooltip('Ajouter au panier'), findsNothing);
  });

  testWidgets('Mode commerçant : interrupteur Disponible/Épuisé (UX-04)', (tester) async {
    var bascules = 0;
    await tester.pumpWidget(enveloppe(
      CarteProduit(produit: tomates, onBasculer: () => bascules++),
    ));
    expect(find.text('Dispo'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    expect(bascules, 1);
  });

  testWidgets('MessageErreur : bouton Réessayer', (tester) async {
    var essais = 0;
    await tester.pumpWidget(enveloppe(MessageErreur(onReessayer: () => essais++)));
    await tester.tap(find.text('Réessayer'));
    expect(essais, 1);
  });
}
