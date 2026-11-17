// =====================================================================
//  connexion_test.dart : tests de la connexion (logique + écran)
//
//  `overrides` : on remplace le vrai repository par un MockAuthRepository
//  SANS latence, pour des tests rapides. C'est aussi comme ça qu'on
//  testera plus tard avec de fausses réponses d'API.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marche_connect/core/router/app_router.dart';
import 'package:marche_connect/core/router/routes.dart';
import 'package:marche_connect/data/mock/mock_data.dart';
import 'package:marche_connect/data/mock/mock_repositories.dart';
import 'package:marche_connect/data/models/models.dart';
import 'package:marche_connect/data/repositories/providers.dart';
import 'package:marche_connect/features/auth/connexion_controller.dart';
import 'package:marche_connect/features/auth/session_provider.dart';
import 'package:marche_connect/main.dart';

/// Conteneur Riverpod de test : base de démo + repository sans latence.
ProviderContainer conteneurDeTest() {
  final db = MockDatabase();
  return ProviderContainer(overrides: [
    mockDatabaseProvider.overrideWithValue(db),
    authRepositoryProvider.overrideWithValue(
      MockAuthRepository(db, latence: Duration.zero),
    ),
  ]);
}

void main() {
  group('ConnexionController (logique seule)', () {
    test('Numéro puis bon code : connecté comme commerçante', () async {
      final c = conteneurDeTest();
      addTearDown(c.dispose);
      // Garde le provider autoDispose en vie pendant le test.
      c.listen(connexionControllerProvider, (_, _) {});
      final controleur = c.read(connexionControllerProvider.notifier);

      await controleur.envoyerCode('+225 05 05 05 05 05');
      expect(c.read(connexionControllerProvider).etape, EtapeConnexion.code);
      expect(c.read(connexionControllerProvider).telephone, '0505050505');

      expect(await controleur.verifierCode(codeOtpDemo), isTrue);
      expect(c.read(sessionProvider)?.role, Role.commercant);
    });

    test('Mauvais code : message d\'erreur et personne de connecté', () async {
      final c = conteneurDeTest();
      addTearDown(c.dispose);
      c.listen(connexionControllerProvider, (_, _) {});
      final controleur = c.read(connexionControllerProvider.notifier);

      await controleur.envoyerCode('0701020304');
      expect(await controleur.verifierCode('000000'), isFalse);
      expect(c.read(connexionControllerProvider).erreur, 'Code incorrect. Réessayez.');
      expect(c.read(sessionProvider), isNull);
    });

    test('Modifier le numéro : retour à l\'étape 1', () async {
      final c = conteneurDeTest();
      addTearDown(c.dispose);
      c.listen(connexionControllerProvider, (_, _) {});
      final controleur = c.read(connexionControllerProvider.notifier);

      await controleur.envoyerCode('0701020304');
      controleur.modifierNumero();
      expect(c.read(connexionControllerProvider).etape, EtapeConnexion.telephone);
    });
  });

  testWidgets('Parcours complet à l\'écran : téléphone → code → accueil commerçant',
      (tester) async {
    final c = conteneurDeTest();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const MarcheConnectApp()),
    );
    await tester.pumpAndSettle();

    // On demande l'espace commerçant → redirigé vers la connexion.
    c.read(routerProvider).go(Routes.commercant);
    await tester.pumpAndSettle();
    expect(find.text('Recevoir le code'), findsOneWidget);

    // Numéro invalide : message sous le champ.
    await tester.enterText(find.byType(TextFormField), '0901');
    await tester.tap(find.text('Recevoir le code'));
    await tester.pump();
    expect(find.text('Le numéro doit avoir 10 chiffres'), findsOneWidget);

    // Bon numéro.
    await tester.enterText(find.byType(TextFormField), '0505050505');
    await tester.tap(find.text('Recevoir le code'));
    await tester.pumpAndSettle();
    expect(find.text('05 05 05 05 05'), findsOneWidget);

    // 6 chiffres : la vérification part toute seule.
    await tester.enterText(find.byType(TextFormField), codeOtpDemo);
    await tester.pumpAndSettle();
    expect(find.text('Étal de Mariam'), findsWidgets); // titre de l'espace commerçant
    expect(c.read(sessionProvider)?.nom, 'Mariam Koné');
  });
}
