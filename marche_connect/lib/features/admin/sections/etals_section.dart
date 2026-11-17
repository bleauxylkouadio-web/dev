// =====================================================================
//  etals_section.dart : TOUS LES ÉTALS de la plateforme
//
//  Réutilise CarteEtal (étape 6). Un appui ouvre la vitrine telle que
//  la voient les clients.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/widgets/widgets.dart';
import '../admin_providers.dart';

class EtalsSection extends ConsumerWidget {
  const EtalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etals = ref.watch(tousLesEtalsProvider);

    return etals.when(
      loading: () => const Chargement(),
      error: (_, _) => MessageErreur(onReessayer: () => ref.invalidate(tousLesEtalsProvider)),
      data: (liste) => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.m),
        itemCount: liste.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
        itemBuilder: (context, i) => CarteEtal(
          etal: liste[i],
          onTap: () => context.push(Routes.etal(liste[i].id)),
        ),
      ),
    );
  }
}
