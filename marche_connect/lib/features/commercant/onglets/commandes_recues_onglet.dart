// =====================================================================
//  commandes_recues_onglet.dart : les COMMANDES REÇUES par l'étal
//
//  Commandes rangées par ce que le commerçant doit faire :
//    1. À confirmer   → [Refuser] [Confirmer]    (MAR-01 : sous 10 min)
//    2. À préparer    → [C'est prêt]
//    3. Prêtes        → retrait : [Remise au client]
//                       livraison : « En attente du livreur »
//    4. Terminées     → repliées
//
//  MAR-06 : les commandes sont REGROUPÉES pour ne pas gêner la vente,
//  et la liste se met à jour toute seule toutes les 30 secondes.
// =====================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../commercant_providers.dart';

class CommandesRecuesOnglet extends ConsumerStatefulWidget {
  const CommandesRecuesOnglet({super.key});

  @override
  ConsumerState<CommandesRecuesOnglet> createState() => _CommandesRecuesOngletState();
}

class _CommandesRecuesOngletState extends ConsumerState<CommandesRecuesOnglet> {
  Timer? _actualisation;

  @override
  void initState() {
    super.initState();
    // Avec la vraie API, une notification (WhatsApp, son) préviendra
    // en plus le commerçant (MAR-06).
    _actualisation = Timer.periodic(
      const Duration(seconds: 30),
      (_) => ref.invalidate(commandesRecuesProvider),
    );
  }

  @override
  void dispose() {
    _actualisation?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commandes = ref.watch(commandesRecuesProvider);

    return commandes.when(
      loading: () => const Chargement(message: 'Chargement des commandes…'),
      error: (_, _) => MessageErreur(onReessayer: () => ref.invalidate(commandesRecuesProvider)),
      data: (liste) {
        List<Commande> avec(StatutCommande s) => liste.where((c) => c.statut == s).toList();
        final aConfirmer = avec(StatutCommande.enAttente);
        final aPreparer = avec(StatutCommande.confirmee);
        final pretes = [...avec(StatutCommande.prete), ...avec(StatutCommande.enLivraison)];
        final terminees = liste.where((c) => c.statut.estTerminee).toList();

        return RefreshIndicator(
          onRefresh: () => ref.refresh(commandesRecuesProvider.future),
          child: ListView(
            // Marge du bas : le bouton flottant ne cache pas la dernière carte.
            padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, 96),
            children: [
              _Resume(nbNouvelles: aConfirmer.length),
              const SizedBox(height: AppSpacing.m),
              _Section(titre: 'À confirmer', commandes: aConfirmer),
              _Section(titre: 'À préparer', commandes: aPreparer),
              _Section(titre: 'Prêtes', commandes: pretes),
              if (terminees.isNotEmpty)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Terminées (${terminees.length})'),
                  children: [
                    for (final c in terminees) ...[
                      CarteCommande(
                        commande: c,
                        titre: c.nomClient,
                        onTap: () => context.push(Routes.ticket(c.id)),
                      ),
                      const SizedBox(height: AppSpacing.s),
                    ],
                  ],
                ),
              if (liste.isEmpty)
                const EtatVide(
                  titre: 'Pas encore de commande',
                  message: 'Partagez le QR de votre étal pour recevoir des commandes.',
                  icone: Icons.inbox,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Bandeau du haut : « 3 nouvelles commandes » (maquette).
class _Resume extends StatelessWidget {
  const _Resume({required this.nbNouvelles});

  final int nbNouvelles;

  @override
  Widget build(BuildContext context) {
    final aucune = nbNouvelles == 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: aucune ? AppColors.primaireClair : AppColors.accentClair,
        borderRadius: BorderRadius.circular(AppRadius.moyen),
      ),
      child: Row(
        children: [
          Icon(aucune ? Icons.check_circle : Icons.notifications_active,
              color: aucune ? AppColors.primaire : AppColors.surAccent),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              aucune
                  ? 'Aucune commande à confirmer'
                  : '$nbNouvelles nouvelle${nbNouvelles > 1 ? 's' : ''} commande${nbNouvelles > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un groupe de commandes avec son titre (masqué s'il est vide).
class _Section extends StatelessWidget {
  const _Section({required this.titre, required this.commandes});

  final String titre;
  final List<Commande> commandes;

  @override
  Widget build(BuildContext context) {
    if (commandes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('$titre (${commandes.length})', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.s),
        for (final c in commandes) ...[
          _CarteCommandeRecue(commande: c),
          const SizedBox(height: AppSpacing.m),
        ],
      ],
    );
  }
}

/// Une commande + les boutons de l'étape suivante.
class _CarteCommandeRecue extends ConsumerStatefulWidget {
  const _CarteCommandeRecue({required this.commande});

  final Commande commande;

  @override
  ConsumerState<_CarteCommandeRecue> createState() => _CarteCommandeRecueState();
}

class _CarteCommandeRecueState extends ConsumerState<_CarteCommandeRecue> {
  bool _enCours = false;

  Future<void> _passerA(StatutCommande statut) async {
    setState(() => _enCours = true);
    try {
      await ref.read(commercantActionsProvider).changerStatut(widget.commande, statut);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action impossible. Vérifiez votre connexion.')),
        );
      }
    }
    if (mounted) setState(() => _enCours = false);
  }

  Future<void> _refuser() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la commande ?'),
        content: const Text('Le client sera prévenu et remboursé s\'il a déjà payé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.erreur),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    if (ok == true) await _passerA(StatutCommande.annulee);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.commande;
    final textes = Theme.of(context).textTheme;

    // Les boutons selon le statut.
    final Widget actions = switch (c.statut) {
      StatutCommande.enAttente => Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _enCours ? null : _refuser,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.erreur,
                  side: const BorderSide(color: AppColors.erreur, width: 2),
                ),
                child: const Text('Refuser'),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: FilledButton(
                onPressed: _enCours ? null : () => _passerA(StatutCommande.confirmee),
                child: const Text('Confirmer'),
              ),
            ),
          ],
        ),
      StatutCommande.confirmee => FilledButton.icon(
          onPressed: _enCours ? null : () => _passerA(StatutCommande.prete),
          icon: const Icon(Icons.inventory_2),
          label: const Text("C'est prêt"),
        ),
      StatutCommande.prete when c.modeLivraison == ModeLivraison.retrait => FilledButton.icon(
          onPressed: _enCours ? null : () => _passerA(StatutCommande.livree),
          icon: const Icon(Icons.handshake),
          label: const Text('Remise au client'),
        ),
      _ => Row(
          children: [
            const Icon(Icons.delivery_dining, color: AppColors.texteSecondaire),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Text(
                c.statut == StatutCommande.enLivraison ? 'En route avec le livreur' : 'En attente du livreur',
                style: textes.bodyMedium,
              ),
            ),
          ],
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarteCommande(
          commande: c,
          titre: c.saisieAssistee ? '${c.nomClient} (assistée)' : c.nomClient,
          onTap: () => context.push(Routes.ticket(c.id)),
        ),
        // Détail des produits : le commerçant sait quoi préparer sans ouvrir la commande.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          child: Text(
            [for (final l in c.lignes) '${l.nomProduit} × ${formaterQuantite(l.quantite, l.unite)}'].join(' · '),
            style: textes.bodyMedium,
          ),
        ),
        if (c.statut == StatutCommande.enAttente)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.m, bottom: AppSpacing.s),
            child: Text(
              'À confirmer avant ${formaterHeure(c.limiteConfirmation)}',
              style: textes.bodySmall?.copyWith(color: AppColors.attente, fontWeight: FontWeight.w700),
            ),
          ),
        actions,
      ],
    );
  }
}
