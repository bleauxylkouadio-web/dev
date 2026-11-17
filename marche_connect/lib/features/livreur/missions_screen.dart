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
//   │ [⌨ Saisir un code]        [📷 Scanner un ticket]│
//   └────────────────────────────────────────────────┘
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../auth/session_provider.dart';
import '../vitrine/vitrine_providers.dart';
import 'livreur_providers.dart';
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
      body: missions.when(
        loading: () => const Chargement(message: 'Chargement des missions…'),
        error: (_, _) => MessageErreur(onReessayer: () => ref.invalidate(missionsProvider)),
        data: (liste) => liste.isEmpty
            ? EtatVide(
                titre: 'Aucune mission',
                message: 'Les commandes prêtes à livrer apparaîtront ici.',
                icone: Icons.delivery_dining,
                libelleAction: 'Actualiser',
                onAction: () => ref.invalidate(missionsProvider),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(missionsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  itemCount: liste.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.l),
                  itemBuilder: (context, i) => _CarteMission(commande: liste[i]),
                ),
              ),
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
    final aRecuperer = c.statut == StatutCommande.prete;

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
          texte: c.adresseLivraison ?? 'Adresse non précisée',
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
        if (aRecuperer)
          FilledButton.icon(
            onPressed: _enCours ? null : _recuperer,
            icon: const Icon(Icons.inventory_2),
            label: const Text("J'ai récupéré la commande"),
          )
        else
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.surAccent,
            ),
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
