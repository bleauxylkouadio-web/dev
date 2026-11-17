// =====================================================================
//  commande_parcours_test.dart : le parcours de commande complet
//
//    Vitrine → Panier → (Connexion) → Paiement → Ticket
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marche_connect/core/router/app_router.dart';
import 'package:marche_connect/core/router/routes.dart';
import 'package:marche_connect/data/models/models.dart';
import 'package:marche_connect/data/repositories/providers.dart';
import 'package:marche_connect/features/auth/session_provider.dart';
import 'package:marche_connect/features/panier/options_livraison.dart';
import 'package:marche_connect/features/panier/panier_provider.dart';

import 'helpers.dart';

void main() {
  test('Frais de livraison et heure de retrait (ACH-03, MAR-02)', () {
    const retrait = OptionsLivraison();
    expect(retrait.frais, 0);
    expect(retrait.heureRetrait(DateTime(2026, 11, 17, 10)), isNull); // dès que possible

    final dansUneHeure = retrait.copyWith(choixHeure: ChoixHeure.dansUneHeure);
    expect(dansUneHeure.heureRetrait(DateTime(2026, 11, 17, 10)), DateTime(2026, 11, 17, 11));

    const livraison = OptionsLivraison(mode: ModeLivraison.livraison);
    expect(livraison.frais, 500);
    expect(livraison.copyWith(memeCommune: false).frais, 1000);
    expect(livraison.erreur, isNotNull); // adresse manquante
    expect(livraison.copyWith(adresse: 'Angré 8e tranche').erreur, isNull);
  });

  testWidgets('Panier : + et − (pas de 0,5 kg), livraison sans adresse refusée', (tester) async {
    final c = conteneurDeTest();
    final db = c.read(mockDatabaseProvider);
    c.read(panierProvider.notifier).ajouter(
          db.produits.firstWhere((p) => p.id == 'p-101'), // Tomates 500 F/kg
          db.etals.firstWhere((e) => e.id == 'e-1'),
        );
    await lancerApp(tester, c);
    c.read(routerProvider).go(Routes.panier);
    await tester.pumpAndSettle();

    expect(find.text('Continuer · 500 F'), findsOneWidget);

    await tester.tap(find.byTooltip('Plus'));
    await tester.pumpAndSettle();
    expect(find.text('1,5 kg'), findsOneWidget);
    expect(find.text('Continuer · 750 F'), findsOneWidget);

    // Livraison : +500 F, et l'adresse est obligatoire.
    await tester.tap(find.text('Livraison'));
    await tester.pumpAndSettle();
    expect(find.text('Continuer · 1 250 F'), findsOneWidget);

    await tester.tap(find.text('Continuer · 1 250 F'));
    await tester.pumpAndSettle();
    expect(find.text('Indiquez votre adresse ou un point de repère.'), findsOneWidget);
  });

  testWidgets('Paiement Wave : commande créée, panier vidé, ticket ouvert', (tester) async {
    final c = conteneurDeTest();
    final db = c.read(mockDatabaseProvider);
    // Awa est connectée et a 1 kg de tomates dans son panier.
    c.read(sessionProvider.notifier).connecter(db.utilisateurs.first);
    c.read(panierProvider.notifier).ajouter(
          db.produits.firstWhere((p) => p.id == 'p-101'),
          db.etals.firstWhere((e) => e.id == 'e-1'),
        );
    final nbAvant = db.commandes.length;

    await lancerApp(tester, c);
    c.read(routerProvider).go(Routes.paiement);
    await tester.pumpAndSettle();

    expect(find.text('Payer 500 F'), findsOneWidget); // Wave par défaut
    await tester.tap(find.text('Payer 500 F'));
    await tester.pumpAndSettle();

    // Une commande de plus, payée par Wave.
    expect(db.commandes.length, nbAvant + 1);
    final commande = db.commandes.last;
    expect(commande.moyenPaiement, MoyenPaiement.wave);
    expect(commande.total, 500);
    expect(commande.clientId, 'u-1');
    // Panier vidé et ticket ouvert.
    expect(c.read(panierProvider).estVide, isTrue);
    expect(find.text('N° ${commande.numeroFormate}'), findsOneWidget);
  });

  testWidgets('Paiement à la livraison : bouton « Commander »', (tester) async {
    final c = conteneurDeTest();
    final db = c.read(mockDatabaseProvider);
    c.read(sessionProvider.notifier).connecter(db.utilisateurs.first);
    c.read(panierProvider.notifier).ajouter(
          db.produits.firstWhere((p) => p.id == 'p-101'),
          db.etals.firstWhere((e) => e.id == 'e-1'),
        );
    await lancerApp(tester, c);
    c.read(routerProvider).go(Routes.paiement);
    await tester.pumpAndSettle();

    final carte = find.text("Payer au retrait à l'étal");
    await tester.ensureVisible(carte);
    await tester.tap(carte);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Commander · 500 F'), findsOneWidget);
  });
}
