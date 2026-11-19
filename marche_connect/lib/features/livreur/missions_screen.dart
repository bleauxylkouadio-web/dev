// =====================================================================
//  missions_screen.dart : ESPACE LIVREUR — mes missions
//
//   ┌ Mes missions                             [⎋] ┐
//   │ ┌ Awa Traoré                      [Prête]   ┐ │
//   │ │ N° 482 913 · 1 produit · 1 500 F           │ │
//   │ │ 🏪 Récupérer : Étal de Mariam, Allée C…    │ │
//   │ │ 🏠 Livrer : Cocody Angré, près de…         │ │
//   │ │ [📞 Client] [🗺 Itinéraire]                │ │
//   │ │ [  J'ai récupéré la commande  ]            │ │
//   │ └────────────────────────────────────────────┘ │
//   │ ── Disponibles à Cocody (2) ──                 │
//   │ ┌ Fatou Bamba · Riviera 3  [Accepter]         ┐ │
//   │ [⌨ Saisir un code]        [📷 Scanner un ticket]│
//   └────────────────────────────────────────────────┘
//
//  « Disponibles » = commandes prêtes SANS livreur, à livrer dans la
//  même commune que les courses en cours (ou la commune du livreur
//  s'il n'a pas encore de course). Il peut en accepter plusieurs.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../auth/session_provider.dart';
import '../vitrine/vitrine_providers.dart';
import 'livreur_providers.dart';
import 'partage_position.dart';
import 'validation_remise.dart';

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missions = ref.watch(missionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes missions'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(sessionProvider.notifier).deconnecter(),
          ),
        ],
      ),
      // Deux gros boutons fixés en bas : scanner (principal) et code (secours).
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => saisirCodeEtValider(context, ref),
                  icon: const Icon(Icons.dialpad),
                  label: const Text('Code'),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => context.push(Routes.livreurScan),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scanner'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Partage automatique de la position pendant les livraisons.
          const PartagePosition(),
          Expanded(
            child: missions.when(
              loading: () => const Chargement(message: 'Chargement des missions…'),
              error: (_, _) => MessageErreur(onReessayer: () => ref.invalidate(missionsProvider)),
              data: (liste) => RefreshIndicator(
                // invalidate(missions) recharge aussi les disponibles
                // (commandesDisponiblesProvider dépend des missions).
                onRefresh: () => ref.refresh(missionsProvider.future),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  children: [
                    // ---------- 1. Mes courses ----------
                    Text('Mes courses (${liste.length})', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.s),
                    if (liste.isEmpty)
                      const EtatVide(
                        titre: 'Aucune mission',
                        message: 'Acceptez une commande disponible ci-dessous.',
                        icone: Icons.delivery_dining,
                      ),
                    for (final c in liste) ...[
                      _CarteMission(commande: c),
                      const SizedBox(height: AppSpacing.l),
                    ],

                    // ---------- 2. Disponibles dans la même commune ----------
                    const _SectionDisponibles(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteMission extends ConsumerStatefulWidget {
  const _CarteMission({required this.commande});

  final Commande commande;

  @override
  ConsumerState<_CarteMission> createState() => _CarteMissionState();
}

class _CarteMissionState extends ConsumerState<_CarteMission> {
  bool _enCours = false;

  Future<void> _recuperer() async {
    setState(() => _enCours = true);
    await ref.read(livreurActionsProvider).recuperer(widget.commande);
    if (mounted) setState(() => _enCours = false);
  }

  /// Appeler le client (tel:).
  Future<void> _appeler() => launchUrl(Uri(scheme: 'tel', path: widget.commande.telephoneClient));

  /// Itinéraire : ouvre Google Maps (ou le navigateur) sur l'adresse.
  Future<void> _itineraire() => launchUrl(
        Uri.https('www.google.com', '/maps/search/', {
          'api': '1',
          'query': '${widget.commande.adresseLivraison ?? ''}, Abidjan',
        }),
        mode: LaunchMode.externalApplication,
      );

  @override
  Widget build(BuildContext context) {
    final c = widget.commande;
    final etal = ref.watch(etalProvider(c.etalId)).value;
    final enPreparation = c.statut == StatutCommande.confirmee;
    final aRecuperer = c.statut == StatutCommande.prete || enPreparation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarteCommande(commande: c, titre: c.nomClient),
        const SizedBox(height: AppSpacing.s),
        _Etape(
          icone: Icons.storefront,
          titre: 'Récupérer',
          texte: etal == null ? c.nomEtal : '${etal.nom} · ${etal.adresseComplete}',
          active: aRecuperer,
        ),
        _Etape(
          icone: Icons.home,
          titre: 'Livrer',
          texte: [
            c.adresseLivraison ?? 'Adresse non précisée',
            if (c.communeLivraison != null) '(${c.communeLivraison!.libelle})',
          ].join(' '),
          active: !aRecuperer,
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _appeler,
                icon: const Icon(Icons.call),
                label: const Text('Client'),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _itineraire,
                icon: const Icon(Icons.map),
                label: const Text('Itinéraire'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        if (enPreparation)
          // Acceptée mais pas encore prête à l'étal : on attend le commerçant.
          const FilledButton(
            onPressed: null,
            child: Text("En préparation à l'étal…"),
          )
        else if (aRecuperer)
          FilledButton.icon(
            onPressed: _enCours ? null : _recuperer,
            icon: const Icon(Icons.inventory_2),
            label: const Text("J'ai récupéré la commande"),
          )
        else
          FilledButton.icon(
            style: AppTheme.boutonOrange,
            onPressed: () => context.push(Routes.livreurScan),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scanner le ticket du client'),
          ),
      ],
    );
  }
}

/// Une étape du trajet (récupérer / livrer), en gras si c'est la prochaine.
class _Etape extends StatelessWidget {
  const _Etape({required this.icone, required this.titre, required this.texte, required this.active});

  final IconData icone;
  final String titre;
  final String texte;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: active ? AppColors.primaire : AppColors.texteSecondaire),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '$titre : ', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: texte),
              ]),
              style: TextStyle(
                fontSize: 16,
                color: active ? AppColors.texte : AppColors.texteSecondaire,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
//  COMMANDES DISPONIBLES DANS LA MÊME COMMUNE
//
//   Disponibles à Cocody (2)
//   Sur le trajet de vos courses : prenez-en plusieurs à la fois.
//   ┌ Fatou Bamba                       [Prête] ┐
//   │ 🏪 Chez Tantie Awa · Marché de Cocody     │
//   │ 🏠 Riviera 3, résidence Les Palmiers      │
//   │ Gain livraison : 500 F                    │
//   │ [        Accepter cette livraison       ] │
//   └───────────────────────────────────────────┘
// =====================================================================
class _SectionDisponibles extends ConsumerWidget {
  const _SectionDisponibles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textes = Theme.of(context).textTheme;
    final missions = ref.watch(missionsProvider).value ?? const [];
    final livreur = ref.watch(sessionProvider);
    final communes = communesDuLivreur(missions, livreur);
    final disponibles = ref.watch(commandesDisponiblesProvider);

    // Aucune commune connue (ancien compte sans commune) : rien à proposer.
    if (communes.isEmpty) return const SizedBox.shrink();

    final noms = communes.map((c) => c.libelle).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: AppSpacing.xl),
        Text(
          'Disponibles à $noms${disponibles.value == null ? '' : ' (${disponibles.value!.length})'}',
          style: textes.titleLarge,
        ),
        Text(
          missions.isEmpty
              ? 'Commandes prêtes à livrer dans votre commune.'
              : 'Sur le trajet de vos courses : prenez-en plusieurs à la fois.',
          style: textes.bodySmall?.copyWith(color: AppColors.texteSecondaire),
        ),
        const SizedBox(height: AppSpacing.s),
        ...disponibles.when(
          loading: () => [const SizedBox(height: 120, child: Chargement())],
          error: (_, _) => [MessageErreur(onReessayer: () => ref.invalidate(commandesDisponiblesProvider))],
          data: (liste) => liste.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                    child: Text('Aucune autre commande pour le moment.', textAlign: TextAlign.center),
                  ),
                ]
              : [
                  for (final c in liste) ...[
                    _CarteDisponible(commande: c),
                    const SizedBox(height: AppSpacing.m),
                  ],
                ],
        ),
      ],
    );
  }
}

class _CarteDisponible extends ConsumerStatefulWidget {
  const _CarteDisponible({required this.commande});

  final Commande commande;

  @override
  ConsumerState<_CarteDisponible> createState() => _CarteDisponibleState();
}

class _CarteDisponibleState extends ConsumerState<_CarteDisponible> {
  bool _enCours = false;

  Future<void> _accepter() async {
    setState(() => _enCours = true);
    final ok = await ref.read(livreurActionsProvider).accepter(widget.commande);
    if (!mounted) return;
    setState(() => _enCours = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Livraison N° ${widget.commande.numeroFormate} ajoutée à vos courses'
          : 'Trop tard : un autre livreur a pris cette commande.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.commande;
    final etal = ref.watch(etalProvider(c.etalId)).value;

    return Card(
      // Bordure verte : on la distingue des courses déjà acceptées.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.moyen),
        side: const BorderSide(color: AppColors.primaire, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(c.nomClient, style: Theme.of(context).textTheme.titleMedium)),
                Flexible(child: BadgeStatutCommande(statut: c.statut)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            _Etape(
              icone: Icons.storefront,
              titre: 'Récupérer',
              texte: etal == null ? c.nomEtal : '${etal.nom} · ${etal.marche}',
              active: true,
            ),
            _Etape(
              icone: Icons.home,
              titre: 'Livrer',
              texte: c.adresseLivraison ?? 'Adresse non précisée',
              active: true,
            ),
            Text(
              'Frais de livraison : ${formaterPrix(c.fraisLivraison)}'
              '${c.moyenPaiement == MoyenPaiement.aLaLivraison ? ' · à encaisser : ${formaterPrix(c.total)}' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.s),
            FilledButton.icon(
              onPressed: _enCours ? null : _accepter,
              icon: const Icon(Icons.add_task),
              label: const Text('Accepter cette livraison'),
            ),
          ],
        ),
      ),
    );
  }
}
