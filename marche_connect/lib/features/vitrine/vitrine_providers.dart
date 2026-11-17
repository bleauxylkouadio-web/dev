// =====================================================================
//  vitrine_providers.dart : les DONNÉES des écrans de la vitrine
//
//  Deux sortes de providers :
//
//  1. NotifierProvider  → un état que l'écran MODIFIE (les filtres).
//  2. FutureProvider    → des données CHARGÉES (liste d'étals, produits).
//     Il donne un AsyncValue, qui vaut à tout moment :
//       - loading (chargement)  → Chargement()
//       - error   (échec)       → MessageErreur(onReessayer)
//       - data    (résultat)    → la liste
//
//  `.family` : un provider « à paramètre ». etalProvider('e-1') et
//  etalProvider('e-2') sont deux chargements distincts.
//  `.autoDispose` : les données sont libérées quand plus aucun écran
//  ne les affiche (économie de mémoire).
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';

// ---------------------------------------------------------------------
//  FILTRES de la liste des étals
// ---------------------------------------------------------------------

class FiltresEtals {
  const FiltresEtals({this.commune, this.categorie, this.recherche = ''});

  final Commune? commune; // null = toutes les communes
  final CategorieProduit? categorie; // null = toutes les catégories
  final String recherche;

  bool get actifs => commune != null || categorie != null || recherche.isNotEmpty;
}

class FiltresEtalsNotifier extends Notifier<FiltresEtals> {
  @override
  FiltresEtals build() => const FiltresEtals();

  /// Appuyer sur la puce déjà choisie la désélectionne.
  void choisirCommune(Commune? commune) => state = FiltresEtals(
        commune: commune == state.commune ? null : commune,
        categorie: state.categorie,
        recherche: state.recherche,
      );

  void choisirCategorie(CategorieProduit? categorie) => state = FiltresEtals(
        commune: state.commune,
        categorie: categorie == state.categorie ? null : categorie,
        recherche: state.recherche,
      );

  void rechercher(String texte) => state = FiltresEtals(
        commune: state.commune,
        categorie: state.categorie,
        recherche: texte.trim(),
      );

  void effacer() => state = const FiltresEtals();
}

final filtresEtalsProvider =
    NotifierProvider<FiltresEtalsNotifier, FiltresEtals>(FiltresEtalsNotifier.new);

// ---------------------------------------------------------------------
//  DONNÉES CHARGÉES
// ---------------------------------------------------------------------

/// Étals correspondant aux filtres. Recalculé AUTOMATIQUEMENT à chaque
/// changement de filtre, grâce à `ref.watch(filtresEtalsProvider)`.
final etalsFiltresProvider = FutureProvider.autoDispose<List<Etal>>((ref) {
  final filtres = ref.watch(filtresEtalsProvider);
  return ref.watch(etalRepositoryProvider).listerEtals(
        commune: filtres.commune,
        categorie: filtres.categorie,
        recherche: filtres.recherche,
      );
});

/// Un étal par son identifiant (vitrine, QR de l'étal).
final etalProvider = FutureProvider.autoDispose.family<Etal?, String>((ref, id) {
  return ref.watch(etalRepositoryProvider).trouverEtal(id);
});

/// Produits visibles par le client (épuisés masqués, MAR-01).
final produitsEtalProvider =
    FutureProvider.autoDispose.family<List<Produit>, String>((ref, etalId) {
  return ref.watch(produitRepositoryProvider).listerProduits(etalId);
});
