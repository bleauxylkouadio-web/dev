// =====================================================================
//  choix_moyen_paiement.dart : la liste des moyens de paiement
//
//  ACH-02 : Wave, Orange Money, MTN MoMo, Moov Money et paiement à la
//  livraison. Grandes cartes faciles à toucher plutôt que de petits
//  boutons radio (UX-06).
//
//  Remarque : on n'affiche pas les logos officiels des opérateurs
//  (marques déposées) tant que les partenariats ne sont pas signés ;
//  chaque moyen a une pastille de couleur neutre et son nom.
// =====================================================================

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/icones.dart';
import '../../../data/models/models.dart';

class ChoixMoyenPaiement extends StatelessWidget {
  const ChoixMoyenPaiement({
    super.key,
    required this.choisi,
    required this.onChoisir,
    required this.avecLivraison,
    this.actif = true,
  });

  final MoyenPaiement choisi;
  final ValueChanged<MoyenPaiement> onChoisir;

  /// Pour un retrait, « à la livraison » devient « au retrait ».
  final bool avecLivraison;

  /// Faux pendant le paiement (on ne change plus d'avis).
  final bool actif;

  String _libelle(MoyenPaiement m) {
    if (m == MoyenPaiement.aLaLivraison) {
      return avecLivraison ? 'Payer à la livraison' : "Payer au retrait à l'étal";
    }
    return m.libelle;
  }

  String _detail(MoyenPaiement m) => m.estMobileMoney
      ? 'Validation sur votre téléphone'
      : 'En espèces ou Mobile Money, à la remise';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final moyen in MoyenPaiement.values) ...[
          _CarteMoyen(
            libelle: _libelle(moyen),
            detail: _detail(moyen),
            icone: iconePaiement(moyen),
            choisi: moyen == choisi,
            onTap: actif ? () => onChoisir(moyen) : null,
          ),
          const SizedBox(height: AppSpacing.s),
        ],
      ],
    );
  }
}

class _CarteMoyen extends StatelessWidget {
  const _CarteMoyen({
    required this.libelle,
    required this.detail,
    required this.icone,
    required this.choisi,
    required this.onTap,
  });

  final String libelle;
  final String detail;
  final IconData icone;
  final bool choisi;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;

    // Semantics : annonce « sélectionné » aux lecteurs d'écran.
    return Semantics(
      selected: choisi,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.moyen),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          decoration: BoxDecoration(
            color: choisi ? AppColors.primaireClair : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.moyen),
            border: Border.all(
              color: choisi ? AppColors.primaire : AppColors.bordure,
              width: choisi ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: choisi ? AppColors.primaire : AppColors.primaireClair,
                foregroundColor: choisi ? Colors.white : AppColors.primaire,
                child: Icon(icone),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(libelle, style: textes.titleMedium),
                    Text(
                      detail,
                      style: textes.bodySmall?.copyWith(color: AppColors.texteSecondaire),
                    ),
                  ],
                ),
              ),
              Icon(
                choisi ? Icons.check_circle : Icons.circle_outlined,
                color: choisi ? AppColors.primaire : AppColors.bordure,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
