// =====================================================================
//  auth_repository.dart : CONTRAT de la connexion et de l'inscription
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
//
//  Parcours :
//    1. envoyerCode(téléphone)
//    2. verifierCode(téléphone, code) → 3 résultats possibles :
//         CodeIncorrect   → message d'erreur
//         CompteExistant  → connecté directement
//         NouveauCompte   → 3. inscrire(nom, rôle…) puis connecté
// =====================================================================

import '../models/models.dart';

// ---------------------------------------------------------------------
//  Résultat de la vérification du code
//
//  `sealed` = liste FERMÉE de cas. Avec un `switch`, Dart vérifie qu'on
//  a bien traité les 3 cas : impossible d'en oublier un.
// ---------------------------------------------------------------------
sealed class ResultatCode {
  const ResultatCode();
}

/// Le code tapé est faux.
class CodeIncorrect extends ResultatCode {
  const CodeIncorrect();
}

/// Bon code, et ce numéro a déjà un compte.
class CompteExistant extends ResultatCode {
  const CompteExistant(this.utilisateur);
  final Utilisateur utilisateur;
}

/// Bon code, mais numéro inconnu : il faut créer le compte.
class NouveauCompte extends ResultatCode {
  const NouveauCompte();
}

/// Rôles qu'une personne peut choisir elle-même à l'inscription.
/// Commerçants et administrateurs sont créés par l'équipe (vérification
/// de l'étal, accès au back-office).
const rolesInscriptionLibre = [Role.client, Role.livreur];

abstract interface class AuthRepository {
  /// Étape 1 de la connexion : envoie un code OTP par SMS au numéro.
  Future<void> envoyerCode(String telephone);

  /// Étape 2 : vérifie le code saisi (voir ResultatCode).
  Future<ResultatCode> verifierCode(String telephone, String code);

  /// Étape 3 (nouveau numéro seulement) : crée le compte.
  /// `role` doit faire partie de [rolesInscriptionLibre].
  Future<Utilisateur> inscrire({
    required String telephone,
    required String nom,
    required Role role,
    Commune? commune,
  });

  /// Déconnexion.
  Future<void> deconnecter();
}
