// =====================================================================
//  formatters.dart : transformer des données en TEXTE LISIBLE
//
//  Tous les écrans affichent les prix, quantités et dates de la même
//  façon parce qu'ils passent tous par ces fonctions.
//
//  Ces fonctions sont « pures » : même entrée → même sortie, sans
//  effet de bord. C'est ce qui les rend faciles à tester.
// =====================================================================

import '../../data/models/models.dart';

/// Espace insécable : empêche « 1 500 » et « F » d'être coupés sur deux
/// lignes quand l'écran est étroit.
const String _insecable = ' ';

/// Mois abrégés en français.
const List<String> _mois = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

// ---------------------------------------------------------------------
//  PRIX
// ---------------------------------------------------------------------

/// 1500 → « 1 500 F » (avec espaces insécables).
String formaterPrix(int montant) {
  final negatif = montant < 0;
  final chiffres = montant.abs().toString();

  // On parcourt les chiffres de droite à gauche et on insère un espace
  // tous les 3 chiffres : 1500000 → 1 500 000.
  final buffer = StringBuffer();
  for (var i = 0; i < chiffres.length; i++) {
    final resteADroite = chiffres.length - i;
    if (i > 0 && resteADroite % 3 == 0) buffer.write(_insecable);
    buffer.write(chiffres[i]);
  }
  return '${negatif ? '-' : ''}$buffer${_insecable}F';
}

/// Prix avec son unité : « 500 F / kg ».
String formaterPrixUnitaire(int prix, UniteVente unite) =>
    '${formaterPrix(prix)} / ${unite.symbole}';

// ---------------------------------------------------------------------
//  QUANTITÉS (MAR-02 : au poids, au lot, à la pièce)
// ---------------------------------------------------------------------

/// Nombre à la française : 1.5 → « 1,5 » ; 2.0 → « 2 ».
String formaterNombre(double valeur) {
  if (valeur == valeur.roundToDouble()) return valeur.toInt().toString();
  return valeur.toString().replaceAll('.', ',');
}

/// 2, kg → « 2 kg » ; 1.5, kg → « 1,5 kg » ; 3, lot → « 3 lots ».
String formaterQuantite(double quantite, UniteVente unite) {
  final nombre = formaterNombre(quantite);
  // Le kilo ne prend jamais de « s » ; les autres unités oui, au-delà de 1.
  final pluriel = unite != UniteVente.kg && quantite > 1 ? 's' : '';
  return '$nombre$_insecable${unite.symbole}$pluriel';
}

// ---------------------------------------------------------------------
//  DATES ET HEURES
// ---------------------------------------------------------------------

/// 14:05 → « 14 h 05 ».
String formaterHeure(DateTime date) =>
    '${date.hour} h ${date.minute.toString().padLeft(2, '0')}';

/// « 17 nov. »
String formaterDateCourte(DateTime date) => '${date.day} ${_mois[date.month - 1]}';

/// UX-05 : âge d'un prix, en texte court et rassurant.
///
///   moins d'1 min  → « à l'instant »
///   moins d'1 h    → « il y a 12 min »
///   aujourd'hui    → « il y a 3 h »
///   hier           → « hier à 18 h 30 »
///   plus ancien    → « le 14 nov. »
///
/// `maintenant` est un paramètre pour que les tests utilisent une heure fixe.
String formaterDepuis(DateTime date, {DateTime? maintenant}) {
  final now = maintenant ?? DateTime.now();
  final ecart = now.difference(date);

  if (ecart.inMinutes < 1) return "à l'instant";
  if (ecart.inMinutes < 60) return 'il y a ${ecart.inMinutes} min';

  final aujourdhui = DateTime(now.year, now.month, now.day);
  final jourDeLaDate = DateTime(date.year, date.month, date.day);
  final joursEcart = aujourdhui.difference(jourDeLaDate).inDays;

  if (joursEcart == 0) return 'il y a ${ecart.inHours} h';
  if (joursEcart == 1) return 'hier à ${formaterHeure(date)}';
  return 'le ${formaterDateCourte(date)}';
}

/// Phrase complète affichée sous un prix : « Prix mis à jour il y a 2 h ».
String formaterMiseAJourPrix(DateTime date, {DateTime? maintenant}) =>
    'Prix mis à jour ${formaterDepuis(date, maintenant: maintenant)}';

// ---------------------------------------------------------------------
//  TÉLÉPHONE
// ---------------------------------------------------------------------

/// « 0701020304 » → « 07 01 02 03 04 ». Les espaces et « +225 » saisis
/// par l'utilisateur sont ignorés.
String formaterTelephone(String telephone) {
  final chiffres = nettoyerTelephone(telephone);
  final buffer = StringBuffer();
  for (var i = 0; i < chiffres.length; i++) {
    if (i > 0 && i.isEven) buffer.write(' ');
    buffer.write(chiffres[i]);
  }
  return buffer.toString();
}

/// Garde seulement les 10 chiffres utiles : « +225 07 01 02 03 04 » → « 0701020304 ».
String nettoyerTelephone(String saisie) {
  var chiffres = saisie.replaceAll(RegExp(r'[^0-9]'), '');
  if (chiffres.length == 13 && chiffres.startsWith('225')) {
    chiffres = chiffres.substring(3);
  }
  return chiffres;
}
