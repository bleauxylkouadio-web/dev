// =====================================================================
//  mon_etal_onglet.dart : MON ÉTAL et son QR à imprimer
//
//  MAR-05 : « Étal identifiable : nom, marché, emplacement ; QR
//  plastifié résistant ». Ce QR contient l'adresse publique de la
//  vitrine : n'importe quel appareil photo l'ouvre, sans installation.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/config.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/widgets/widgets.dart';
import '../commercant_providers.dart';

class MonEtalOnglet extends ConsumerWidget {
  const MonEtalOnglet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etal = ref.watch(monEtalProvider);
    final textes = Theme.of(context).textTheme;

    return etal.when(
      loading: () => const Chargement(),
      error: (_, _) => MessageErreur(onReessayer: () => ref.invalidate(monEtalProvider)),
      data: (e) {
        if (e == null) return const EtatVide(titre: 'Étal introuvable');
        final lien = lienPublicEtal(e.id);

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.m),
          children: [
            // ---------- Le QR à imprimer ----------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  children: [
                    Text(e.nom, style: textes.headlineSmall, textAlign: TextAlign.center),
                    Text('${e.marche} · ${e.emplacement}', textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.m),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(AppSpacing.s),
                      child: QrImageView(
                        data: lien,
                        size: 220,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                        semanticsLabel: 'QR code de la vitrine ${e.nom}',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text('Scannez pour commander', style: textes.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    SelectableText(lien, style: textes.bodySmall), // copiable
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // ---------- Conseils ----------
            const _Conseil(
              icone: Icons.print,
              texte: "Imprimez ce QR (capture d'écran ou impression), "
                  'plastifiez-le et accrochez-le bien en vue sur votre étal.',
            ),
            const _Conseil(
              icone: Icons.share,
              texte: 'Partagez le lien dans vos statuts WhatsApp, TikTok ou Facebook.',
            ),
            const SizedBox(height: AppSpacing.m),
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.etal(e.id)),
              icon: const Icon(Icons.visibility),
              label: const Text('Voir ma vitrine comme un client'),
            ),
          ],
        );
      },
    );
  }
}

class _Conseil extends StatelessWidget {
  const _Conseil({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: AppColors.primaire),
          const SizedBox(width: AppSpacing.s),
          Expanded(child: Text(texte)),
        ],
      ),
    );
  }
}
