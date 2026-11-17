// =====================================================================
//  commercant_test.dart : tests de l'espace commerçant (Mariam, e-1)
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

/// Connecte Mariam (commerçante) et ouvre l'adresse demandée.
Future<ProviderContainer> ouvrirEnTantQueMariam(WidgetTester tester, String adresse) async {
  final c = conteneurDeTest();
  final mariam = c.read(mockDatabaseProvider).utilisateurs.firstWhere((u) => u.role == Role.commercant);
  c.read(sessionProvider.notifier).connecter(mariam);
  await lancerApp(tester, c);
  c.read(routerProvider).go(adresse);
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('Commandes reçues : « 1 nouvelle commande », puis Confirmer', (tester) async {
    final c = await ouvrirEnTantQueMariam(tester, Routes.commercant);
    final db = c.read(mockDatabaseProvider);

    expect(find.text('1 nouvelle commande'), findsOneWidget);
    expect(find.text('Maman Adjoua (assistée)'), findsOneWidget);

    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();

    expect(db.commandes.firstWhere((x) => x.id == 'c-2').statut, StatutCommande.confirmee);
    expect(find.text('Aucune commande à confirmer'), findsOneWidget);
    expect(find.text("C'est prêt"), findsOneWidget);
  });

  testWidgets('Produits : le piment épuisé repasse « Dispo » en un geste', (tester) async {
    final c = await ouvrirEnTantQueMariam(tester, Routes.commercant);
    final db = c.read(mockDatabaseProvider);

    await tester.tap(find.text('Produits'));
    await tester.pumpAndSettle();
    expect(find.text('Piment frais'), findsOneWidget); // visible côté commerçant

    // Le 2e interrupteur est celui du piment (ordre de la base de démo).
    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();
    expect(db.produits.firstWhere((p) => p.id == 'p-102').disponible, isTrue);
  });

  testWidgets('Nouveau produit publié en quelques gestes (UX-04)', (tester) async {
    final c = await ouvrirEnTantQueMariam(tester, Routes.commercantNouveauProduit);
    final db = c.read(mockDatabaseProvider);
    final avant = db.produits.length;

    await tester.enterText(find.widgetWithText(TextFormField, 'Nom du produit'), 'Aubergines');
    await tester.enterText(find.widgetWithText(TextFormField, 'Prix'), '400');
    await tester.tap(find.text('au kilo'));
    await tester.tap(find.text('Publier le produit'));
    await tester.pumpAndSettle();

    expect(db.produits.length, avant + 1);
    final nouveau = db.produits.last;
    expect(nouveau.nom, 'Aubergines');
    expect(nouveau.prix, 400);
    expect(nouveau.unite, UniteVente.kg);
    expect(nouveau.categorie, CategorieProduit.legumes); // catégorie de l'étal par défaut
    expect(nouveau.etalId, 'e-1');
  });

  testWidgets('Mode assisté : commande confirmée et ticket affiché (ACH-06)', (tester) async {
    final c = await ouvrirEnTantQueMariam(tester, Routes.commercantAssiste);
    final db = c.read(mockDatabaseProvider);
    final avant = db.commandes.length;

    await tester.tap(find.byTooltip('Plus de Tomates'));
    await tester.tap(find.byTooltip('Plus de Tomates')); // 2 × 0,5 kg = 1 kg
    await tester.pump();
    expect(find.text('Créer le ticket · 500 F'), findsOneWidget);

    await tester.tap(find.text('Créer le ticket · 500 F'));
    await tester.pumpAndSettle();

    expect(db.commandes.length, avant + 1);
    final commande = db.commandes.last;
    expect(commande.saisieAssistee, isTrue);
    expect(commande.statut, StatutCommande.confirmee);
    expect(commande.nomClient, 'Client au comptoir');
    expect(find.text('Code de secours : ${commande.numeroFormate}'), findsOneWidget);
  });
}
