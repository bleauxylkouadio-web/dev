// =====================================================================
//  commande_providers.dart : les DONNÉES des écrans Ticket et Mes commandes
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';
import '../auth/session_provider.dart';

/// Une commande par son identifiant (écran Ticket, /ticket/:id).
final commandeProvider = FutureProvider.autoDispose.family<Commande?, String>((ref, id) {
  return ref.watch(commandeRepositoryProvider).trouverCommande(id);
});

/// Le litige d'une commande, s'il y en a un (ACH-04).
final litigeDeCommandeProvider = FutureProvider.autoDispose.family<Litige?, String>((ref, commandeId) {
  return ref.watch(litigeRepositoryProvider).litigeDeLaCommande(commandeId);
});

/// Les commandes du client connecté, la plus récente en premier.
/// Liste vide si personne n'est connecté.
final mesCommandesProvider = FutureProvider.autoDispose<List<Commande>>((ref) async {
  final client = ref.watch(sessionProvider);
  if (client == null) return [];
  return ref.watch(commandeRepositoryProvider).commandesDuClient(client.id);
});
