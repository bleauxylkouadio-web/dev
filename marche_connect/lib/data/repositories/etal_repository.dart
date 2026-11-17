// =====================================================================
//  etal_repository.dart : CONTRAT d'accès aux étals
//  (module « Vitrine et recherche »)
// =====================================================================

import '../models/models.dart';

abstract interface class EtalRepository {
  /// Liste des étals, avec filtres facultatifs :
  /// - commune      : Cocody, Abobo, Adjamé, Treichville
  /// - categorie    : Légumes, Pagnes…
  /// - recherche    : texte libre (nom de l'étal, du commerçant ou du marché)
  ///
  /// Les étals mis en avant (mise en avant payante) sont renvoyés en premier.
  Future<List<Etal>> listerEtals({
    Commune? commune,
    CategorieProduit? categorie,
    String? recherche,
  });

  /// Un étal précis (ex. après scan du QR de l'étal). `null` s'il n'existe pas.
  Future<Etal?> trouverEtal(String id);
}
