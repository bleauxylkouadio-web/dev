// =====================================================================
//  validators.dart : vérifier ce que l'utilisateur tape
//
//  Chaque fonction renvoie :
//    - null           → la saisie est correcte
//    - un message     → affiché en rouge sous le champ
//
//  C'est exactement le format attendu par `TextFormField(validator: ...)`
//  de Flutter : on pourra écrire `validator: validerTelephone`.
//  Messages courts et sans jargon (UX-02).
// =====================================================================

import 'formatters.dart';

/// Numéro ivoirien : 10 chiffres, commençant par 01 (Moov), 05 (MTN)
/// ou 07 (Orange). « +225 » et les espaces sont acceptés.
String? validerTelephone(String? saisie) {
  if (saisie == null || saisie.trim().isEmpty) {
    return 'Entrez votre numéro de téléphone';
  }
  final chiffres = nettoyerTelephone(saisie);
  if (chiffres.length != 10) {
    return 'Le numéro doit avoir 10 chiffres';
  }
  if (!RegExp(r'^(01|05|07)').hasMatch(chiffres)) {
    return 'Le numéro doit commencer par 01, 05 ou 07';
  }
  return null;
}

/// Code OTP : exactement 6 chiffres.
String? validerCodeOtp(String? saisie) {
  final code = saisie?.trim() ?? '';
  if (code.isEmpty) return 'Entrez le code reçu par SMS';
  if (!RegExp(r'^\d{6}$').hasMatch(code)) return 'Le code a 6 chiffres';
  return null;
}

/// Prix saisi par le commerçant : nombre entier, entre 25 F et 10 000 000 F.
String? validerPrix(String? saisie) {
  final texte = saisie?.replaceAll(RegExp(r'\s'), '') ?? '';
  if (texte.isEmpty) return 'Entrez un prix';
  final prix = int.tryParse(texte);
  if (prix == null) return 'Chiffres uniquement, sans virgule';
  if (prix < 25) return 'Le prix minimum est 25 F';
  if (prix > 10000000) return 'Prix trop élevé';
  return null;
}

/// Champ texte obligatoire (nom du produit, nom du client…).
String? validerObligatoire(String? saisie, {String champ = 'ce champ'}) {
  if (saisie == null || saisie.trim().isEmpty) return 'Remplissez $champ';
  return null;
}
