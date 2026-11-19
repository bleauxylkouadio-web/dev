// =====================================================================
//  suivi_livreur_test.dart : suivi du livreur en direct
//
//  Le GPS n'existe pas dans les tests : on remplace la source de
//  position par une « fausse source » que le test pilote lui-même.
// =====================================================================

import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marche_connect/core/router/app_router.dart';
import 'package:marche_connect/core/router/routes.dart';
import 'package:marche_connect/data/models/models.dart';
import 'package:marche_connect/data/repositories/providers.dart';
import 'package:marche_connect/features/auth/session_provider.dart';
import 'package:marche_connect/features/livreur/source_position.dart';

import 'helpers.dart';

/// Fausse source : le test envoie les positions à la main.
class FausseSource implements SourcePosition {
  final controleur = StreamController<Coordonnees>.broadcast();

  @override
  Stream<Coordonnees> suivre() => controleur.stream;
}

void main() {
  test('Vie privée : aucune position avant ni après la livraison', () async {
    final c = conteneurDeTest();
    final suivi = c.read(suiviRepositoryProvider);
    final position = PositionLivreur(
      commandeId: 'c-1',
      livreurId: 'u-3',
      latitude: 5.36,
      longitude: -4.02,
      misAJourLe: DateTime.now(),
    );

    // c-1 est « Prête » : le livreur n'a pas encore le colis → refusé.
    expect(() => suivi.envoyerPosition(position), throwsA(isA<StateError>()));

    // Le livreur récupère le colis → la position est acceptée et visible.
    await c.read(commandeRepositoryProvider).changerStatut('c-1', StatutCommande.enLivraison);
    await suivi.envoyerPosition(position);
    expect((await suivi.positionDuLivreur('c-1'))?.latitude, 5.36);

    // Remise validée → la position disparaît.
    await c.read(commandeRepositoryProvider).validerRemise('482913');
    expect(await suivi.positionDuLivreur('c-1'), isNull);
  });

  testWidgets('Livreur : le partage démarre dès « J\'ai récupéré la commande »', (tester) async {
    final source = FausseSource();
    // Le GPS est remplacé par la fausse source.
    final c = conteneurDeTest(autres: [sourcePositionProvider.overrideWithValue(source)]);
    final db = c.read(mockDatabaseProvider);
    c.read(sessionProvider.notifier).connecter(db.utilisateurs.firstWhere((u) => u.role == Role.livreur));
    await lancerApp(tester, c);
    c.read(routerProvider).go(Routes.livreur);
    await tester.pumpAndSettle();

    // Avant : pas de partage.
    expect(find.textContaining('Position partagée'), findsNothing);

    await tester.tap(find.text("J'ai récupéré la commande"));
    await tester.pumpAndSettle();
    expect(find.textContaining('Position partagée avec 1 client'), findsOneWidget);

    // Le « GPS » envoie une position → elle est enregistrée pour c-1.
    source.controleur.add(const Coordonnees(5.37, -4.01, precisionMetres: 8));
    await tester.pumpAndSettle();
    expect(db.positions['c-1']?.longitude, -4.01);
    expect(find.textContaining('envoyée à l\'instant'), findsOneWidget);
  });

  testWidgets('Client : la carte du livreur apparaît sur le ticket en livraison', (tester) async {
    final c = conteneurDeTest();
    final db = c.read(mockDatabaseProvider);
    // Le livreur a récupéré c-1 et a envoyé sa position.
    await tester.runAsync(() async {
      await c.read(commandeRepositoryProvider).changerStatut('c-1', StatutCommande.enLivraison);
      await c.read(suiviRepositoryProvider).envoyerPosition(PositionLivreur(
            commandeId: 'c-1',
            livreurId: 'u-3',
            latitude: 5.38,
            longitude: -4.00,
            misAJourLe: DateTime.now(),
          ));
    });
    c.read(sessionProvider.notifier).connecter(db.utilisateurs.first);
    await lancerApp(tester, c);
    c.read(routerProvider).go(Routes.ticket('c-1'));
    await tester.pumpAndSettle();

    expect(find.text('Votre livreur arrive'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Ouvrir dans Google Maps'), findsOneWidget);
  });

  testWidgets('Client : pas de carte tant que le livreur n\'a pas le colis', (tester) async {
    final c = conteneurDeTest();
    await lancerApp(tester, c);
    c.read(routerProvider).go(Routes.ticket('c-1')); // « Prête »
    await tester.pumpAndSettle();
    expect(find.text('Votre livreur arrive'), findsNothing);
    expect(find.byType(FlutterMap), findsNothing);
  });
}
