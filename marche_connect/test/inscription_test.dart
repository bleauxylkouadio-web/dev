// =====================================================================
//  inscription_test.dart : un nouveau LIVREUR arrive sur SON interface
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marche_connect/core/widgets/identite.dart';
import 'package:marche_connect/core/router/app_router.dart';
import 'package:marche_connect/core/router/redirection.dart';
import 'package:marche_connect/core/router/routes.dart';
import 'package:marche_connect/data/mock/mock_data.dart';
import 'package:marche_connect/data/models/models.dart';
import 'package:marche_connect/data/repositories/providers.dart';
import 'package:marche_connect/features/auth/session_provider.dart';

import 'helpers.dart';

/// Tape un numéro inconnu et le code : arrive à l'étape « Créer mon compte ».
Future<void> allerJusquaInscription(WidgetTester tester, String numero) async {
  await tester.enterText(find.byType(TextFormField), numero);
  await tester.tap(find.text('Recevoir le code'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField), codeOtpDemo);
  await tester.pumpAndSettle();
  expect(find.text('Vous êtes :'), findsOneWidget);
}

void main() {
  test('Règle de redirection : un livreur ne revient pas sur une page client', () {
    final livreur = Utilisateur(id: 'u', telephone: '0102030405', nom: 'L', role: Role.livreur);
    // Il s'est inscrit en partant du paiement → il va sur /livreur.
    expect(calculerRedirection(livreur, Uri.parse('/connexion?retour=%2Fpaiement')), Routes.livreur);
    // Il voulait ouvrir le scan → il y va.
    expect(calculerRedirection(livreur, Uri.parse('/connexion?retour=%2Flivreur%2Fscan')), Routes.livreurScan);
  });

  testWidgets('Nouveau numéro + profil Livreur → « Mes missions »', (tester) async {
    final c = conteneurDeTest();
    await lancerApp(tester, c);
    c.read(routerProvider).go(Routes.connexion);
    await tester.pumpAndSettle();

    await allerJusquaInscription(tester, '0799999999');

    await tester.tap(find.text('Livreur'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextFormField, 'Votre nom'), 'Ibrahim Koné');

    // Commune obligatoire pour un livreur : message si on l'oublie.
    final bouton = find.text('Créer mon compte livreur');
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pump();
    expect(find.text('Choisissez votre commune'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Abobo'));
    await tester.pump();
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pumpAndSettle();

    // Connecté comme livreur et arrivé sur son interface.
    expect(c.read(sessionProvider)?.role, Role.livreur);
    expect(c.read(mockDatabaseProvider).utilisateurs.last.commune, Commune.abobo);
    expect(find.text('Mes missions'), findsOneWidget);
  });

  testWidgets('Nouveau numéro + profil Client → liste des étals', (tester) async {
    final c = conteneurDeTest();
    await lancerApp(tester, c);
    c.read(routerProvider).go(Routes.connexion);
    await tester.pumpAndSettle();

    await allerJusquaInscription(tester, '0788888888');
    await tester.enterText(find.widgetWithText(TextFormField, 'Votre nom'), 'Fatou');
    final bouton = find.text('Créer mon compte');
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pumpAndSettle();

    expect(c.read(sessionProvider)?.role, Role.client);
    expect(find.byType(LogoMarcheConnect), findsOneWidget); // logo de la barre // accueil client
  });
}
