// =====================================================================
//  ticket_test.dart : tests du Ticket QR et de Mes commandes
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:marche_connect/core/router/app_router.dart';
import 'package:marche_connect/core/router/routes.dart';
import 'package:marche_connect/data/repositories/providers.dart';
import 'package:marche_connect/features/auth/session_provider.dart';

import 'helpers.dart';

void main() {
  testWidgets('Ticket 482 913 : QR, statut « Prête », code de secours', (tester) async {
    final c = conteneurDeTest();
    await lancerApp(tester, c);

    c.read(routerProvider).go(Routes.ticket('c-1'));
    await tester.pumpAndSettle();

    expect(find.text('N° 482 913'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Prête · à remettre au livreur'), findsOneWidget);
    expect(find.text('Code de secours : 482 913'), findsOneWidget);
    // Le QR contient bien le texte attendu par le scanner du livreur.
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr.semanticsLabel, contains('482 913'));
  });

  testWidgets('Commande en attente : délai de confirmation affiché (MAR-01)', (tester) async {
    final c = conteneurDeTest();
    await lancerApp(tester, c);

    c.read(routerProvider).go(Routes.ticket('c-2')); // mode assisté, en attente
    await tester.pumpAndSettle();

    expect(find.textContaining('Le commerçant confirme avant'), findsOneWidget);
    expect(find.text("Prête, à récupérer"), findsOneWidget); // retrait : pas d'étape « En route »
    expect(find.text('En route'), findsNothing);
  });

  testWidgets('Ticket inconnu → « Commande introuvable »', (tester) async {
    final c = conteneurDeTest();
    await lancerApp(tester, c);

    c.read(routerProvider).go(Routes.ticket('xyz'));
    await tester.pumpAndSettle();
    expect(find.text('Commande introuvable'), findsOneWidget);
  });

  testWidgets("Mes commandes d'Awa : 1 en cours, 1 terminée", (tester) async {
    final c = conteneurDeTest();
    final awa = c.read(mockDatabaseProvider).utilisateurs.first;
    c.read(sessionProvider.notifier).connecter(awa);
    await lancerApp(tester, c);

    c.read(routerProvider).go(Routes.mesCommandes);
    await tester.pumpAndSettle();

    expect(find.text('En cours (1)'), findsOneWidget);
    expect(find.text('Terminées (1)'), findsOneWidget);
    expect(find.text('Étal de Mariam'), findsOneWidget);

    // Onglet « Terminées » : la commande de pagne livrée.
    await tester.tap(find.text('Terminées (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Pagnes Akissi'), findsOneWidget);

    // Appui sur la carte → ticket.
    await tester.tap(find.text('Pagnes Akissi'));
    await tester.pumpAndSettle();
    expect(find.text('N° 209 377'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsWidgets);
  });
}
