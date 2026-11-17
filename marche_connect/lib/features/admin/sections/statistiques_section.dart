// =====================================================================
//  statistiques_section.dart : les CHIFFRES CLÉS de la plateforme
//
//  Activité · Argent (chiffre d'affaires, commissions) · Inclusion
//  (commandes assistées) · Commandes par statut · Étals par commune.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../admin_providers.dart';

class StatistiquesSection extends ConsumerWidget {
  const StatistiquesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statistiquesProvider);

    return stats.when(
      loading: () => const Chargement(message: 'Calcul des statistiques…'),
      error: (_, _) => MessageErreur(onReessayer: () => ref.invalidate(statistiquesProvider)),
      data: (s) => RefreshIndicator(
        onRefresh: () => ref.refresh(statistiquesProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.m),
          children: [
            _Bloc(titre: 'Activité', lignes: [
              _Ligne(Icons.receipt_long, 'Commandes', '${s.nombreCommandes}'),
              _Ligne(Icons.storefront, 'Étals', '${s.nombreEtals}'),
              _Ligne(Icons.person, 'Clients', '${s.nombreClients}'),
              _Ligne(Icons.delivery_dining, 'Livreurs', '${s.nombreLivreurs}'),
            ]),
            _Bloc(titre: 'Argent (commandes livrées)', lignes: [
              _Ligne(Icons.payments, "Chiffre d'affaires des étals", formaterPrix(s.chiffreAffaires)),
              _Ligne(
                Icons.account_balance,
                'Commissions (${(tauxCommission * 100).round()} %, à confirmer)',
                formaterPrix(s.commissions),
              ),
              _Ligne(Icons.local_shipping, 'Frais de livraison', formaterPrix(s.fraisLivraison)),
            ]),
            _Bloc(titre: 'Inclusion et qualité', lignes: [
              _Ligne(Icons.support_agent, 'Commandes assistées (sans smartphone)', '${s.commandesAssistees}'),
              _Ligne(
                Icons.gavel,
                'Litiges à traiter',
                '${s.litigesOuverts}',
                alerte: s.litigesOuverts > 0,
              ),
            ]),

            // ---------- Commandes par statut ----------
            _Bloc(titre: 'Commandes par statut', lignes: [
              for (final statut in StatutCommande.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(child: Align(alignment: Alignment.centerLeft, child: BadgeStatutCommande(statut: statut))),
                      Text('${s.commandesParStatut[statut] ?? 0}', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
            ]),

            // ---------- Étals par commune pilote ----------
            _Bloc(titre: 'Étals par commune pilote', lignes: [
              for (final commune in Commune.values)
                _Ligne(Icons.place, commune.libelle, '${s.etalsParCommune[commune] ?? 0}'),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Une carte avec un titre et des lignes.
class _Bloc extends StatelessWidget {
  const _Bloc({required this.titre, required this.lignes});

  final String titre;
  final List<Widget> lignes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(titre, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.s),
              ...lignes,
            ],
          ),
        ),
      ),
    );
  }
}

/// Une ligne « icône · libellé ........ valeur ».
class _Ligne extends StatelessWidget {
  const _Ligne(this.icone, this.libelle, this.valeur, {this.alerte = false});

  final IconData icone;
  final String libelle;
  final String valeur;
  final bool alerte;

  @override
  Widget build(BuildContext context) {
    final couleur = alerte ? AppColors.erreur : AppColors.texte;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icone, color: alerte ? AppColors.erreur : AppColors.primaire),
          const SizedBox(width: AppSpacing.s),
          Expanded(child: Text(libelle, style: TextStyle(color: couleur))),
          const SizedBox(width: AppSpacing.s),
          Text(
            valeur,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: couleur),
          ),
        ],
      ),
    );
  }
}
