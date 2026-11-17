// =====================================================================
//  providers.dart : LE POINT DE BRANCHEMENT des données
//
//  Riverpod « fournit » (provide) un objet à tous les écrans qui le
//  demandent. Un écran écrira par exemple :
//
//    final etals = await ref.read(etalRepositoryProvider).listerEtals();
//
//  🔌 Le jour où l'API REST est prête, on ne modifie QUE ce fichier :
//     MockEtalRepository(...)  →  ApiEtalRepository(...)
//  Aucun écran ne change.
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/etat_reseau.dart';
import '../local/repositories_en_cache.dart';
import '../local/stockage_local.dart';
import '../mock/mock_admin_repositories.dart';
import '../mock/mock_data.dart';
import '../mock/mock_repositories.dart';
import 'admin_repository.dart';
import 'auth_repository.dart';
import 'commande_repository.dart';
import 'etal_repository.dart';
import 'litige_repository.dart';
import 'produit_repository.dart';

/// La base de démo, partagée par tous les repositories (une seule instance,
/// sinon une commande créée ne serait pas vue par l'espace commerçant).
final mockDatabaseProvider = Provider<MockDatabase>((ref) => MockDatabase());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(ref.watch(mockDatabaseProvider)),
);

// ---------------------------------------------------------------------
//  MODE HORS LIGNE (étape 15)
//  Étals et produits passent par un CACHE : version « réseau » (mock ou
//  API) enveloppée par la version « en cache » (repositories_en_cache.dart).
// ---------------------------------------------------------------------

/// Stockage sur le téléphone. En mémoire par défaut (tests) ;
/// main.dart le remplace par Hive au démarrage.
final stockageLocalProvider = Provider<StockageLocal>((ref) => StockageMemoire());

/// Fonction donnée aux caches pour signaler « en ligne / hors ligne ».
SignalerReseau _signalerReseau(Ref ref) => ({required bool horsLigne, DateTime? donneesDu}) {
      final etat = ref.read(etatReseauProvider.notifier);
      horsLigne ? etat.horsLigne(donneesDu) : etat.enLigne();
    };

/// Étals : accès réseau direct (mock aujourd'hui, API demain).
final etalReseauProvider = Provider<EtalRepository>(
  (ref) => MockEtalRepository(ref.watch(mockDatabaseProvider)),
);

/// Étals : version utilisée par les écrans (réseau + cache).
final etalRepositoryProvider = Provider<EtalRepository>(
  (ref) => EtalRepositoryEnCache(
    ref.watch(etalReseauProvider),
    ref.watch(stockageLocalProvider),
    _signalerReseau(ref),
  ),
);

final produitReseauProvider = Provider<ProduitRepository>(
  (ref) => MockProduitRepository(ref.watch(mockDatabaseProvider)),
);

final produitRepositoryProvider = Provider<ProduitRepository>(
  (ref) => ProduitRepositoryEnCache(
    ref.watch(produitReseauProvider),
    ref.watch(stockageLocalProvider),
    _signalerReseau(ref),
  ),
);

final commandeRepositoryProvider = Provider<CommandeRepository>(
  (ref) => MockCommandeRepository(ref.watch(mockDatabaseProvider)),
);

final litigeRepositoryProvider = Provider<LitigeRepository>(
  (ref) => MockLitigeRepository(ref.watch(mockDatabaseProvider)),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => MockAdminRepository(ref.watch(mockDatabaseProvider)),
);
