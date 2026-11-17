// =====================================================================
//  helpers.dart : outils partagés par les tests
//
//  conteneurDeTest() : un conteneur Riverpod avec une base de démo
//  neuve et des repositories SANS latence (tests rapides).
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marche_connect/data/mock/mock_admin_repositories.dart';
import 'package:marche_connect/data/mock/mock_data.dart';
import 'package:marche_connect/data/mock/mock_repositories.dart';
import 'package:marche_connect/data/repositories/providers.dart';
import 'package:marche_connect/main.dart';

ProviderContainer conteneurDeTest() {
  final db = MockDatabase();
  final container = ProviderContainer(overrides: [
    mockDatabaseProvider.overrideWithValue(db),
    authRepositoryProvider.overrideWithValue(MockAuthRepository(db, latence: Duration.zero)),
    // On remplace la partie « réseau » : le cache hors ligne reste actif.
    etalReseauProvider.overrideWithValue(MockEtalRepository(db, latence: Duration.zero)),
    produitReseauProvider.overrideWithValue(MockProduitRepository(db, latence: Duration.zero)),
    commandeRepositoryProvider.overrideWithValue(MockCommandeRepository(db, latence: Duration.zero)),
    litigeRepositoryProvider.overrideWithValue(MockLitigeRepository(db, latence: Duration.zero)),
    adminRepositoryProvider.overrideWithValue(MockAdminRepository(db, latence: Duration.zero)),
  ]);
  addTearDown(container.dispose);
  return container;
}

/// Lance l'application complète avec ce conteneur, sur un écran de
/// téléphone (400 × 900) plutôt que la fenêtre de test par défaut (800 × 600).
Future<void> lancerApp(WidgetTester tester, ProviderContainer c) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const MarcheConnectApp()));
  await tester.pumpAndSettle();
}
