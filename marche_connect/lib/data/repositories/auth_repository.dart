// =====================================================================
//  auth_repository.dart : CONTRAT de la connexion
//
//  Un « repository » est la porte d'entrée vers les données.
//  Ce fichier ne contient que des signatures (abstract) : il dit
//  QUOI faire, pas COMMENT. Deux versions existeront :
//    - MockAuthRepository  (aujourd'hui, données simulées)
//    - ApiAuthRepository   (plus tard, vraie API REST)
//  Les écrans ne connaissent que ce contrat : on pourra changer de
//  version sans toucher à un seul écran.
//
//  `Future<...>` = résultat qui arrive plus tard (appel réseau).
//  On l'utilise avec `await` dans le code des écrans.
// =====================================================================

import '../models/models.dart';

abstract interface class AuthRepository {
  /// Étape 1 de la connexion : envoie un code OTP par SMS au numéro.
  Future<void> envoyerCode(String telephone);

  /// Étape 2 : vérifie le code saisi.
  /// Renvoie l'utilisateur connecté, ou `null` si le code est faux.
  Future<Utilisateur?> verifierCode(String telephone, String code);

  /// Déconnexion.
  Future<void> deconnecter();
}
