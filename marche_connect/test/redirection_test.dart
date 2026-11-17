// =====================================================================
//  redirection_test.dart : tests des règles d'accès aux pages
// =====================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:marche_connect/core/router/redirection.dart';
import 'package:marche_connect/core/router/routes.dart';
import 'package:marche_connect/data/models/models.dart';

/// Crée un utilisateur de test avec le rôle demandé.
Utilisateur avecRole(Role role) =>
    Utilisateur(id: 'u', telephone: '0701020304', nom: 'Test', role: role);

/// Raccourci : redirection pour une adresse texte.
String? r(Utilisateur? u, String adresse) => calculerRedirection(u, Uri.parse(adresse));

void main() {
  final client = avecRole(Role.client);
  final commercant = avecRole(Role.commercant);
  final admin = avecRole(Role.admin);

  test('UX-01 : un visiteur consulte les étals et une vitrine sans compte', () {
    expect(r(null, Routes.etals), isNull);
    expect(r(null, Routes.etal('e-1')), isNull); // scan du QR de l'étal
    expect(r(null, Routes.panier), isNull);
    expect(r(null, Routes.ticket('c-1')), isNull);
  });

  test('Payer demande une connexion, avec retour au paiement ensuite', () {
    expect(r(null, Routes.paiement), '/connexion?retour=%2Fpaiement');
    expect(r(client, Routes.paiement), isNull);
  });

  test('Après connexion, on revient à la page demandée', () {
    expect(r(client, '/connexion?retour=%2Fpaiement'), Routes.paiement);
  });

  test('Déjà connecté sur /connexion → accueil du rôle', () {
    expect(r(client, Routes.connexion), Routes.etals);
    expect(r(commercant, Routes.connexion), Routes.commercant);
  });

  test("Un client ne peut pas ouvrir l'espace commerçant", () {
    expect(r(client, Routes.commercant), Routes.etals);
    expect(r(commercant, Routes.commercant), isNull);
    expect(r(commercant, '/commercant/produits'), isNull); // sous-page
  });

  test("L'administrateur a accès à tous les espaces", () {
    expect(r(admin, Routes.commercant), isNull);
    expect(r(admin, Routes.livreur), isNull);
    expect(r(admin, Routes.admin), isNull);
  });

  test('Un commerçant ne peut pas ouvrir le back-office', () {
    expect(r(commercant, Routes.admin), Routes.commercant);
  });
}
