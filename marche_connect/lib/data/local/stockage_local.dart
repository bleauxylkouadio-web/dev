// =====================================================================
//  stockage_local.dart : enregistrer des données SUR LE TÉLÉPHONE
//
//  Sert au mode hors ligne :
//   - UX-03 : catalogue consultable hors ligne (étals, produits) ;
//   - MAR-04 : panier conservé après une coupure ou une fermeture.
//
//  Les données sont rangées comme dans un dictionnaire :
//    clé (texte)  →  valeur (texte JSON)
//
//  Deux versions du même contrat :
//   - StockageHive    : la vraie, sur le téléphone (Hive ; dans le
//                       navigateur, Hive utilise IndexedDB) ;
//   - StockageMemoire : en mémoire seulement, pour les tests.
// =====================================================================

import 'package:hive_flutter/hive_flutter.dart';

abstract interface class StockageLocal {
  /// La valeur enregistrée sous `cle`, ou null.
  String? lire(String cle);

  Future<void> ecrire(String cle, String valeur);

  Future<void> effacer(String cle);
}

/// Version réelle : une « boîte » Hive qui contient des textes.
class StockageHive implements StockageLocal {
  StockageHive(this._boite);

  /// Nom de la boîte (comme un nom de fichier).
  static const nomBoite = 'marche_connect';

  /// À appeler UNE fois au démarrage (main.dart), avant runApp.
  static Future<StockageHive> ouvrir() async {
    await Hive.initFlutter();
    return StockageHive(await Hive.openBox<String>(nomBoite));
  }

  final Box<String> _boite;

  @override
  String? lire(String cle) => _boite.get(cle);

  @override
  Future<void> ecrire(String cle, String valeur) => _boite.put(cle, valeur);

  @override
  Future<void> effacer(String cle) => _boite.delete(cle);
}

/// Version de test : un simple dictionnaire en mémoire.
class StockageMemoire implements StockageLocal {
  final Map<String, String> _donnees = {};

  @override
  String? lire(String cle) => _donnees[cle];

  @override
  Future<void> ecrire(String cle, String valeur) async => _donnees[cle] = valeur;

  @override
  Future<void> effacer(String cle) async => _donnees.remove(cle);
}
