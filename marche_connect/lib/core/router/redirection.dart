// =====================================================================
//  redirection.dart : QUI a le droit d'aller OÙ ?
//
//  Cette fonction est appelée avant CHAQUE changement de page.
//  Elle renvoie :
//    - null         → OK, on affiche la page demandée
//    - une adresse  → on redirige vers cette adresse à la place
//
//  Elle est « pure » (pas de Flutter dedans) : facile à tester.
//
//  Règles :
//   1. Pages publiques : tout le monde (consultation sans compte, UX-01).
//   2. Paiement / Mes commandes : il faut être connecté.
//   3. /commercant, /livreur, /admin : il faut le BON rôle.
//   4. Déjà connecté et on ouvre /connexion → on va à son accueil.
//
//  Après connexion, l'utilisateur revient là où il allait grâce au
//  paramètre « ?retour=… » ajouté à l'adresse de connexion.
// =====================================================================

import '../../data/models/models.dart';
import 'routes.dart';

/// Page d'accueil de chaque rôle, juste après la connexion.
String accueilDuRole(Role role) => switch (role) {
      Role.client => Routes.etals,
      Role.commercant => Routes.commercant,
      Role.livreur => Routes.livreur,
      Role.admin => Routes.admin,
    };

/// Vrai si `chemin` est `prefixe` ou une sous-page de `prefixe`.
/// Ex. : /commercant/produits commence par /commercant.
bool _sousLe(String chemin, String prefixe) =>
    chemin == prefixe || chemin.startsWith('$prefixe/');

/// Calcule la redirection pour `uri` (adresse demandée) et `utilisateur`
/// (null = visiteur non connecté).
String? calculerRedirection(Utilisateur? utilisateur, Uri uri) {
  final chemin = uri.path;
  final connecte = utilisateur != null;

  // Adresse de connexion qui ramènera ensuite à la page demandée.
  String versConnexion() => Uri(
        path: Routes.connexion,
        queryParameters: {'retour': uri.toString()},
      ).toString();

  // ---- Règle 4 : déjà connecté sur /connexion ----
  // (cas juste après une connexion ou une inscription)
  if (chemin == Routes.connexion) {
    if (!connecte) return null;
    final role = utilisateur.role;
    final accueil = accueilDuRole(role);
    final retour = uri.queryParameters['retour'];
    // On revient à la page demandée avant la connexion SEULEMENT si elle
    // concerne ce profil. Ex. : un livreur qui s'inscrit en partant du
    // panier va sur SON interface (/livreur), pas sur le paiement client.
    final retourAdapte = retour != null &&
        (role == Role.client || role == Role.admin || _sousLe(Uri.parse(retour).path, accueil));
    return retourAdapte ? retour : accueil;
  }

  // ---- Règle 2 : pages réservées aux personnes connectées ----
  if (chemin == Routes.paiement || _sousLe(chemin, Routes.mesCommandes)) {
    return connecte ? null : versConnexion();
  }

  // ---- Règle 3 : espaces réservés à un rôle ----
  final espaces = {
    Routes.commercant: Role.commercant,
    Routes.livreur: Role.livreur,
    Routes.admin: Role.admin,
  };
  for (final MapEntry(key: prefixe, value: roleRequis) in espaces.entries) {
    if (_sousLe(chemin, prefixe)) {
      if (!connecte) return versConnexion();
      // Un administrateur peut tout voir ; les autres seulement leur espace.
      if (utilisateur.role == roleRequis || utilisateur.role == Role.admin) {
        return null;
      }
      return accueilDuRole(utilisateur.role);
    }
  }

  // ---- Règle 1 : tout le reste est public ----
  return null;
}
