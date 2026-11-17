// =====================================================================
//  repositories_en_cache.dart : le CATALOGUE HORS LIGNE (UX-03)
//
//  Principe du « décorateur » : on enveloppe un repository existant
//  (mock aujourd'hui, API demain) sans le modifier.
//
//   listerEtals()
//     ├─ réseau OK      → on renvoie le résultat ET on l'enregistre
//     └─ réseau coupé   → on relit la dernière copie enregistrée
//                         (et on applique les filtres sur le téléphone)
//
//  Les écrans ne voient aucune différence : ils reçoivent une liste.
//  Seul le bandeau « Hors ligne » (etat_reseau.dart) les prévient.
// =====================================================================

import 'dart:convert';

import '../models/models.dart';
import '../repositories/etal_repository.dart';
import '../repositories/produit_repository.dart';
import 'stockage_local.dart';

/// Ce que le cache doit signaler (branché sur EtatReseauNotifier).
typedef SignalerReseau = void Function({required bool horsLigne, DateTime? donneesDu});

// ---------------------------------------------------------------------
//  Outils communs : enregistrer / relire une liste JSON avec sa date
// ---------------------------------------------------------------------
class _Cache {
  _Cache(this._stockage);

  final StockageLocal _stockage;

  Future<void> enregistrer(String cle, List<Map<String, dynamic>> elements) {
    return _stockage.ecrire(
      cle,
      jsonEncode({'date': DateTime.now().toIso8601String(), 'elements': elements}),
    );
  }

  /// (date, éléments) ou null si rien n'a jamais été enregistré.
  (DateTime, List<Map<String, dynamic>>)? relire(String cle) {
    final texte = _stockage.lire(cle);
    if (texte == null) return null;
    final json = jsonDecode(texte) as Map<String, dynamic>;
    return (
      DateTime.parse(json['date'] as String),
      (json['elements'] as List).cast<Map<String, dynamic>>(),
    );
  }
}

// =====================================================================
//  ÉTALS
// =====================================================================
class EtalRepositoryEnCache implements EtalRepository {
  EtalRepositoryEnCache(this._reseau, StockageLocal stockage, this._signaler) : _cache = _Cache(stockage);

  static const _cle = 'cache_etals';

  final EtalRepository _reseau;
  final _Cache _cache;
  final SignalerReseau _signaler;

  @override
  Future<List<Etal>> listerEtals({Commune? commune, CategorieProduit? categorie, String? recherche}) async {
    var reseauCoupe = false;
    try {
      // 1. On demande TOUS les étals au réseau et on les enregistre…
      final tous = await _reseau.listerEtals();
      await _cache.enregistrer(_cle, [for (final e in tous) e.toJson()]);
      _signaler(horsLigne: false);
    } catch (_) {
      // Réseau coupé : on continue avec la copie enregistrée (plus bas).
      reseauCoupe = true;
    }
    // 2. … puis on filtre sur le téléphone. En ligne comme hors ligne,
    //    c'est le même code : le résultat est toujours cohérent.
    final copie = _cache.relire(_cle);
    if (copie == null) throw StateError('Hors ligne et aucun catalogue enregistré.');
    final (date, elements) = copie;
    if (reseauCoupe) _signaler(horsLigne: true, donneesDu: date);

    final texte = recherche?.trim().toLowerCase() ?? '';
    final etals = elements.map(Etal.fromJson).where((e) {
      if (commune != null && e.commune != commune) return false;
      if (categorie != null && !e.categories.contains(categorie)) return false;
      if (texte.isNotEmpty &&
          !e.nom.toLowerCase().contains(texte) &&
          !e.nomCommercant.toLowerCase().contains(texte) &&
          !e.marche.toLowerCase().contains(texte)) {
        return false;
      }
      return true;
    }).toList();
    // On garde l'ordre renvoyé par le serveur (mis en avant d'abord).
    return etals;
  }

  @override
  Future<Etal?> trouverEtal(String id) async {
    try {
      final etal = await _reseau.trouverEtal(id);
      _signaler(horsLigne: false);
      return etal;
    } catch (_) {
      final copie = _cache.relire(_cle);
      if (copie == null) rethrow;
      _signaler(horsLigne: true, donneesDu: copie.$1);
      return copie.$2.map(Etal.fromJson).where((e) => e.id == id).firstOrNull;
    }
  }
}

// =====================================================================
//  PRODUITS (lecture en cache ; les modifications exigent le réseau)
// =====================================================================
class ProduitRepositoryEnCache implements ProduitRepository {
  ProduitRepositoryEnCache(this._reseau, StockageLocal stockage, this._signaler) : _cache = _Cache(stockage);

  final ProduitRepository _reseau;
  final _Cache _cache;
  final SignalerReseau _signaler;

  static String _cle(String etalId) => 'cache_produits_$etalId';

  @override
  Future<List<Produit>> listerProduits(String etalId, {bool inclureEpuises = false}) async {
    try {
      // On enregistre TOUT (épuisés compris), puis on filtre au besoin.
      final tous = await _reseau.listerProduits(etalId, inclureEpuises: true);
      await _cache.enregistrer(_cle(etalId), [for (final p in tous) p.toJson()]);
      _signaler(horsLigne: false);
      return tous.where((p) => inclureEpuises || p.visibleParClient).toList();
    } catch (_) {
      final copie = _cache.relire(_cle(etalId));
      if (copie == null) rethrow;
      _signaler(horsLigne: true, donneesDu: copie.$1);
      return copie.$2.map(Produit.fromJson).where((p) => inclureEpuises || p.visibleParClient).toList();
    }
  }

  // Les autres méthodes passent directement au réseau.
  @override
  Future<Produit?> trouverProduit(String id) => _reseau.trouverProduit(id);

  @override
  Future<Produit> basculerDisponibilite(String produitId) => _reseau.basculerDisponibilite(produitId);

  @override
  Future<Produit> changerPrix(String produitId, int nouveauPrix) => _reseau.changerPrix(produitId, nouveauPrix);

  @override
  Future<Produit> ajouterProduit({
    required String etalId,
    required String nom,
    required int prix,
    required UniteVente unite,
    required CategorieProduit categorie,
    String? description,
    String? photoUrl,
  }) =>
      _reseau.ajouterProduit(
        etalId: etalId,
        nom: nom,
        prix: prix,
        unite: unite,
        categorie: categorie,
        description: description,
        photoUrl: photoUrl,
      );
}
