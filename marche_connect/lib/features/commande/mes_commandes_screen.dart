// =====================================================================
//  mes_commandes_screen.dart : historique et suivi des commandes
//
//   [ En cours (1) | Terminées (1) ]     ← onglets
//   ┌ Étal de Mariam         [Prête] ┐
//   │ N° 482 913 · 17 nov. à 14 h 25 │
//   └ 1 produit · Livraison  1 500 F ┘
//
//  Accessible seulement connecté (règle 2 de redirection.dart).
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../auth/session_provider.dart';
import 'commande_providers.dart';

class MesCommandesScreen extends ConsumerWidget {
  const MesCommandesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandes = ref.watch(mesCommandesProvider);

    // DefaultTabController : gère l'onglet sélectionné pour TabBar et TabBarView.
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes commandes'),
          actions: [
            IconButton(
              tooltip: 'Se déconnecter',
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(sessionProvider.notifier).deconnecter(),
            ),
          ],
          // Couleurs des onglets : thème (texte blanc, trait orange).
          bottom: TabBar(
            indicatorWeight: 4,
            tabs: [
              Tab(text: _titreOnglet('En cours', commandes.value, terminees: false)),
              Tab(text: _titreOnglet('Terminées', commandes.value, terminees: true)),
            ],
          ),
        ),
        body: commandes.when(
          loading: () => const Chargement(message: 'Chargement des commandes…'),
          error: (_, _) => MessageErreur(onReessayer: () => ref.invalidate(mesCommandesProvider)),
          data: (liste) => TabBarView(
            children: [
              _ListeCommandes(
                commandes: liste.where((c) => !c.statut.estTerminee).toList(),
                messageVide: "Aucune commande en cours pour l'instant.",
              ),
              _ListeCommandes(
                commandes: liste.where((c) => c.statut.estTerminee).toList(),
                messageVide: 'Vos commandes passées apparaîtront ici.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// « En cours (2) » quand la liste est chargée, « En cours » sinon.
  static String _titreOnglet(String libelle, List<Commande>? liste, {required bool terminees}) {
    if (liste == null) return libelle;
    final n = liste.where((c) => c.statut.estTerminee == terminees).length;
    return '$libelle ($n)';
  }
}

class _ListeCommandes extends ConsumerWidget {
  const _ListeCommandes({required this.commandes, required this.messageVide});

  final List<Commande> commandes;
  final String messageVide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (commandes.isEmpty) {
      return EtatVide(
        titre: 'Rien ici',
        message: messageVide,
        icone: Icons.receipt_long,
        libelleAction: 'Voir les étals',
        onAction: () => context.go(Routes.etals),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.refresh(mesCommandesProvider.future),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.m),
        itemCount: commandes.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
        itemBuilder: (context, i) => CarteCommande(
          commande: commandes[i],
          onTap: () => context.push(Routes.ticket(commandes[i].id)),
        ),
      ),
    );
  }
}
