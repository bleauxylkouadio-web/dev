// =====================================================================
//  admin_test.dart : back-office et litiges (ACH-04)
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

Future<ProviderContainer> ouvrirEnTantQue(WidgetTester tester, Role role, String adresse) async {
  final c = conteneurDeTest();
  final u = c.read(mockDatabaseProvider).utilisateurs.firstWhere((u) => u.role == role);
  c.read(sessionProvider.notifier).connecter(u);
  await lancerApp(tester, c);
  c.read(routerProvider).go(adresse);
  await tester.pumpAndSettle();
  return c;
}

void main() {
  test('Statistiques : commission calculée sur les commandes livrées', () async {
    final c = conteneurDeTest();
    final s = await c.read(adminRepositoryProvider).statistiques();
    // Seule c-3 (pagne 8 000 F) est livrée dans les données de démo.
    expect(s.chiffreAffaires, 8000);
    expect(s.commissions, 400); // 5 % (hypothèse)
    expect(s.commandesAssistees, 1);
    expect(s.litigesOuverts, 1);
  });

  testWidgets('Tableau de bord : chiffres clés affichés', (tester) async {
    await ouvrirEnTantQue(tester, Role.admin, Routes.admin);
    expect(find.text('Back-office · Tableau de bord'), findsOneWidget);
    expect(find.text('8 000 F'), findsOneWidget);
  });

  testWidgets('Litige : remboursement → litige fermé, commande remboursée', (tester) async {
    final c = await ouvrirEnTantQue(tester, Role.admin, Routes.admin);
    final db = c.read(mockDatabaseProvider);

    await tester.tap(find.text('Litiges').last);
    await tester.pumpAndSettle();
    expect(find.text('N° 209 377 · Pagnes Akissi'), findsOneWidget);
    expect(find.text('Reste 17 h'), findsOneWidget); // 48 h − 30 h (arrondi inférieur)

    await tester.tap(find.text('Rembourser'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(db.litiges.first.statut, StatutLitige.rembourse);
    expect(db.commandes.firstWhere((x) => x.id == 'c-3').statutPaiement, StatutPaiement.rembourse);
    expect(find.text('Aucun litige'), findsOneWidget); // plus rien « À traiter »
  });

  testWidgets('Client : « Signaler un problème » sur une commande livrée', (tester) async {
    final c = conteneurDeTest();
    final db = c.read(mockDatabaseProvider);
    // La commande c-1 est livrée (remise validée par le livreur).
    // runAsync : dans un testWidgets, le temps est simulé ; un appel
    // asynchrone fait AVANT de lancer l'écran doit passer par runAsync,
    // sinon il ne se termine jamais.
    await tester.runAsync(() => c.read(commandeRepositoryProvider).validerRemise('482913'));
    c.read(sessionProvider.notifier).connecter(db.utilisateurs.first);
    await lancerApp(tester, c);
    c.read(routerProvider).go(Routes.ticket('c-1'));
    await tester.pumpAndSettle();

    // Le bouton est en bas du ticket : une ListView ne construit que ce qui
    // est à l'écran, il faut donc FAIRE DÉFILER jusqu'à lui.
    final bouton = find.text('Signaler un problème');
    await tester.scrollUntilVisible(bouton, 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(bouton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mauvaise qualité'));
    await tester.pump();
    await tester.tap(find.text('Envoyer le signalement'));
    await tester.pumpAndSettle();

    expect(db.litiges.length, 2);
    expect(db.litiges.last.motif, MotifLitige.qualite);
    expect(find.text('Problème signalé : Mauvaise qualité'), findsOneWidget);
  });

  testWidgets('Comptes : filtre par rôle', (tester) async {
    await ouvrirEnTantQue(tester, Role.admin, Routes.admin);
    await tester.tap(find.text('Comptes').last);
    await tester.pumpAndSettle();
    final puce = find.widgetWithText(ChoiceChip, 'Livreur');
    await tester.ensureVisible(puce); // la ligne de puces défile horizontalement
    await tester.pumpAndSettle();
    await tester.tap(puce);
    await tester.pumpAndSettle();
    expect(find.text('Ibrahim Ouattara'), findsOneWidget);
    expect(find.text('Awa Traoré'), findsNothing);
  });
}
