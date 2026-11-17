// =====================================================================
//  livreur_test.dart : tests de l'espace livreur (Ibrahim, u-3)
//
//  La caméra n'existe pas dans les tests : on teste la saisie du code
//  à 6 chiffres, qui utilise exactement la même validation que le scan.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marche_connect/core/router/app_router.dart';
import 'package:marche_connect/core/router/routes.dart';
import 'package:marche_connect/data/models/models.dart';
import 'package:marche_connect/data/repositories/providers.dart';
import 'package:marche_connect/features/auth/session_provider.dart';

import 'helpers.dart';

Future<ProviderContainer> ouvrirEnTantQuIbrahim(WidgetTester tester) async {
  final c = conteneurDeTest();
  final ibrahim = c.read(mockDatabaseProvider).utilisateurs.firstWhere((u) => u.role == Role.livreur);
  c.read(sessionProvider.notifier).connecter(ibrahim);
  await lancerApp(tester, c);
  c.read(routerProvider).go(Routes.livreur);
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('Mission 482 913 : récupérer à l\'étal → en route', (tester) async {
    final c = await ouvrirEnTantQuIbrahim(tester);
    final db = c.read(mockDatabaseProvider);

    expect(find.text('Awa Traoré'), findsOneWidget);
    expect(find.textContaining('Allée C'), findsOneWidget); // où récupérer

    await tester.tap(find.text("J'ai récupéré la commande"));
    await tester.pumpAndSettle();

    expect(db.commandes.firstWhere((x) => x.id == 'c-1').statut, StatutCommande.enLivraison);
    expect(find.text('Scanner le ticket du client'), findsOneWidget);
  });

  testWidgets('Code à 6 chiffres correct → « Commande remise », mission terminée', (tester) async {
    final c = await ouvrirEnTantQuIbrahim(tester);
    final db = c.read(mockDatabaseProvider);

    await tester.tap(find.text('Code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '482913');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.text('Commande remise'), findsOneWidget);
    expect(db.commandes.firstWhere((x) => x.id == 'c-1').statut, StatutCommande.livree);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune mission'), findsOneWidget);
  });

  testWidgets('Code inconnu → « Code non reconnu »', (tester) async {
    await ouvrirEnTantQuIbrahim(tester);

    await tester.tap(find.text('Code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '000000');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.text('Code non reconnu'), findsOneWidget);
  });
}
