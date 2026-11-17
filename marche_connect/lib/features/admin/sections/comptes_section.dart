// =====================================================================
//  comptes_section.dart : GESTION DES COMPTES
//
//  Liste des comptes avec filtre par rôle. Avec la vraie API, on
//  ajoutera ici la suspension d'un compte et la validation des
//  nouveaux commerçants.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../admin_providers.dart';

class ComptesSection extends ConsumerStatefulWidget {
  const ComptesSection({super.key});

  @override
  ConsumerState<ComptesSection> createState() => _ComptesSectionState();
}

class _ComptesSectionState extends ConsumerState<ComptesSection> {
  Role? _role; // null = tous

  static IconData _icone(Role role) => switch (role) {
        Role.client => Icons.person,
        Role.commercant => Icons.storefront,
        Role.livreur => Icons.delivery_dining,
        Role.admin => Icons.admin_panel_settings,
      };

  @override
  Widget build(BuildContext context) {
    final comptes = ref.watch(utilisateursProvider(_role));

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, 0),
          child: Row(
            children: [
              ChoiceChip(label: const Text('Tous'), selected: _role == null, onSelected: (_) => setState(() => _role = null)),
              for (final r in Role.values) ...[
                const SizedBox(width: AppSpacing.s),
                ChoiceChip(label: Text(r.libelle), selected: _role == r, onSelected: (_) => setState(() => _role = r)),
              ],
            ],
          ),
        ),
        Expanded(
          child: comptes.when(
            loading: () => const Chargement(),
            error: (_, _) => MessageErreur(onReessayer: () => ref.invalidate(utilisateursProvider)),
            data: (liste) => liste.isEmpty
                ? const EtatVide(titre: 'Aucun compte', icone: Icons.people)
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: liste.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
                    itemBuilder: (context, i) {
                      final u = liste[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaireClair,
                            foregroundColor: AppColors.primaire,
                            child: Icon(_icone(u.role)),
                          ),
                          title: Text(u.nom),
                          subtitle: Text(
                            [formaterTelephone(u.telephone), if (u.commune != null) u.commune!.libelle].join(' · '),
                          ),
                          trailing: Text(u.role.libelle, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
