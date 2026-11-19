// =====================================================================
//  livreur_tournee_test.dart : inscription d'un livreur et commandes
//  disponibles dans la même commune (tournées)
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marche_connect/core/router/app_router.dart';
import 'package:marche_connect/core/router/routes.dart';
import 'package:marche_connect/data/mock/mock_data.dart';
import 'package:marche_connect/data/models/models.dart';
import 'package:marche_connect/data/repositories/providers.dart';
import 'package:marche_connect/features/auth/session_provider.dart';

import 'helpers.dart';

/// Fait défiler la liste jusqu'au texte, l'amène en HAUT de l'écran
/// (sinon il peut rester caché sous la barre fixée en bas), puis le touche.
Future<void> toucher(WidgetTester tester, Finder cible) async {
  await tester.scrollUntilVisible(cible, 200, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  test('Disponibles : seulement la commune demandée, sans livreur', () async {
    final c = conteneurDeTest();
    final repo = c.read(commandeRepositoryProvider);

    final cocody = await repo.commandesDisponibles(Commune.cocody);
    expect(cocody.map((x) => x.id), unorderedEquals(['c-4', 'c-5'])); // pas c-1 (déjà pris)
    final abobo = await repo.commandesDisponibles(Commune.abobo);
    expect(abobo.single.id, 'c-6');
  });

  test('Une commande ne peut être acceptée que par UN livreur', () async {
    final c = conteneurDeTest();
    final repo = c.read(commandeRepositoryProvider);

    expect((await repo.accepterLivraison('c-4', 'u-3'))?.livreurId, 'u-3');
    expect(await repo.accepterLivraison('c-4', 'u-99'), isNull); // trop tard
    expect(await repo.commandesDisponibles(Commune.cocody), hasLength(1));
  });

  testWidgets('Ibrahim (course à Cocody) voit et accepte les autres commandes de Cocody', (tester) async {
    final c = conteneurDeTest();
    final db = c.read(mockDatabaseProvider);
    c.read(sessionProvider.notifier).connecter(db.utilisateurs.firstWhere((u) => u.role == Role.livreur));
    await lancerApp(tester, c);
    c.read(routerProvider).go(Routes.livreur);
    await tester.pumpAndSettle();

    expect(find.text('Mes courses (1)'), findsOneWidget);
    // Ibrahim travaille à Adjamé, mais sa course va à Cocody : on lui
    // propose les commandes de COCODY (même trajet).
    await tester.scrollUntilVisible(find.text('Disponibles à Cocody (2)'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Fatou Bamba'), findsOneWidget);
    expect(find.text('Aminata Coulibaly'), findsNothing); // Abobo

    await toucher(tester, find.text('Accepter cette livraison').first);

    expect(db.commandes.firstWhere((x) => x.id == 'c-4').livreurId, 'u-3');
    await tester.scrollUntilVisible(find.text('Mes courses (2)'), -200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Mes courses (2)'), findsOneWidget);
  });

  testWidgets("Inscription d'un livreur : il arrive sur SON interface", (tester) async {
    final c = conteneurDeTest();
    await lancerApp(tester, c);

    // Il part du panier (parcours client) puis se connecte.
    c.read(routerProvider).go('${Routes.connexion}?retour=${Uri.encodeComponent(Routes.panier)}');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '0788888888'); // nouveau numéro
    await tester.tap(find.text('Recevoir le code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), codeOtpDemo);
    await tester.pumpAndSettle();

    // Étape inscription : profil Livreur, nom, commune.
    await toucher(tester, find.text('Livreur'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Votre nom'), 'Moussa Diallo');
    await toucher(tester, find.widgetWithText(ChoiceChip, 'Cocody'));
    await toucher(tester, find.text('Créer mon compte livreur'));

    // Arrivé sur l'espace livreur (et non sur le panier client).
    expect(c.read(sessionProvider)?.role, Role.livreur);
    expect(find.text('Mes missions'), findsOneWidget);
    expect(find.text('Mes courses (0)'), findsOneWidget);
    // Pas encore de course : on lui propose les commandes de SA commune.
    await tester.scrollUntilVisible(find.text('Disponibles à Cocody (2)'), 200,
        scrollable: find.byType(Scrollable).first);
  });
}
