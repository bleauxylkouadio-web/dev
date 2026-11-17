// =====================================================================
//  entete_etal.dart : le haut de la vitrine d'un étal
//
//  ACH-01 : AVANT de commander, le client voit la photo, les avis,
//  le numéro d'appel et l'emplacement de l'étal.
//  MAR-05 : étal identifiable (nom, marché, emplacement).
// =====================================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/icones.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';

class EnteteEtal extends StatelessWidget {
  const EnteteEtal({super.key, required this.etal});

  final Etal etal;

  /// Ouvre le composeur de numéro du téléphone (lien « tel: »).
  Future<void> _appeler(BuildContext context) async {
    final ok = await launchUrl(Uri(scheme: 'tel', path: etal.telephone));
    // `context.mounted` : l'écran existe-t-il encore après l'attente ?
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appelez le ${formaterTelephone(etal.telephone)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    final secondaire = textes.bodyMedium?.copyWith(color: AppColors.texteSecondaire);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PhotoProduit(
                  url: etal.photoUrl,
                  iconeRemplacement: iconeCategorie(etal.categories.first),
                  taille: 88,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(etal.nom, style: textes.titleLarge),
                      Text('Tenu par ${etal.nomCommercant}', style: secondaire),
                      const SizedBox(height: AppSpacing.s),
                      BadgeNote(note: etal.noteMoyenne, nombreAvis: etal.nombreAvis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),

            // ---------- Où trouver l'étal (MAR-05) ----------
            _LigneInfo(icone: Icons.storefront, texte: etal.marche),
            _LigneInfo(icone: Icons.signpost, texte: etal.emplacement),
            _LigneInfo(icone: Icons.place, texte: etal.commune.libelle),

            // ---------- Étal fermé ----------
            if (!etal.ouvert) ...[
              const SizedBox(height: AppSpacing.s),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s),
                decoration: BoxDecoration(
                  color: AppColors.erreurClair,
                  borderRadius: BorderRadius.circular(AppRadius.petit),
                ),
                child: const Text(
                  "Fermé aujourd'hui : vous pouvez consulter, mais pas commander.",
                  style: TextStyle(color: AppColors.erreur, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.m),

            // ---------- Appeler (ACH-01) ----------
            OutlinedButton.icon(
              onPressed: () => _appeler(context),
              icon: const Icon(Icons.call),
              label: Text('Appeler · ${formaterTelephone(etal.telephone)}'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une ligne « icône + texte ».
class _LigneInfo extends StatelessWidget {
  const _LigneInfo({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icone, size: 20, color: AppColors.primaire),
          const SizedBox(width: AppSpacing.s),
          Expanded(child: Text(texte, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
