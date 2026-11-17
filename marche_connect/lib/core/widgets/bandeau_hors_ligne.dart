// =====================================================================
//  bandeau_hors_ligne.dart : « Hors ligne · données du 17 nov. à 14 h 05 »
//
//  Affiché en haut des écrans de consultation quand le réseau est
//  coupé et que les données viennent du stockage du téléphone (UX-03).
//  Invisible (taille zéro) quand tout va bien.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/etat_reseau.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../utils/formatters.dart';

class BandeauHorsLigne extends ConsumerWidget {
  const BandeauHorsLigne({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(etatReseauProvider);
    if (!etat.horsLigne) return const SizedBox.shrink();

    final date = etat.donneesDu;
    return Container(
      width: double.infinity,
      color: AppColors.texte,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              date == null
                  ? 'Hors ligne'
                  : 'Hors ligne · données du ${formaterDateCourte(date)} à ${formaterHeure(date)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
