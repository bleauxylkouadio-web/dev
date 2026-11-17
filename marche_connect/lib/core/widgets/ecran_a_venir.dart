// =====================================================================
//  ecran_a_venir.dart : écran PROVISOIRE (« en construction »)
//
//  À l'étape 7, on pose toute la navigation avant de construire les
//  écrans. Chaque adresse affiche donc ce gabarit :
//    - le nom de l'écran et l'étape où il sera construit ;
//    - des liens pour tester la navigation ;
//    - un bouton « Se déconnecter » si quelqu'un est connecté.
//  Chaque écran remplacera ce gabarit le moment venu.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/session_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

/// Un lien de test : un texte + l'adresse où il mène.
class LienDemo {
  const LienDemo(this.libelle, this.adresse);
  final String libelle;
  final String adresse;
}

/// ConsumerWidget = StatelessWidget qui peut lire des providers Riverpod
/// grâce au paramètre `ref`.
class EcranAVenir extends ConsumerWidget {
  const EcranAVenir({
    super.key,
    required this.titre,
    required this.etape,
    required this.description,
    this.icone = Icons.construction,
    this.liens = const [],
  });

  final String titre;
  final String etape; // ex. « Étape 9 »
  final String description;
  final IconData icone;
  final List<LienDemo> liens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textes = Theme.of(context).textTheme;
    // ref.watch : l'écran se redessine si la session change.
    final utilisateur = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(titre),
        actions: [
          if (utilisateur != null)
            IconButton(
              tooltip: 'Se déconnecter',
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(sessionProvider.notifier).deconnecter(),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          Icon(icone, size: 72, color: AppColors.primaire),
          const SizedBox(height: AppSpacing.m),
          Text(titre, style: textes.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.s),
          Text(
            '$etape : $description',
            style: textes.bodyMedium?.copyWith(color: AppColors.texteSecondaire),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.m),
          // Qui est connecté ? Utile pour tester les redirections.
          Text(
            utilisateur == null
                ? 'Non connecté (visiteur)'
                : 'Connecté : ${utilisateur.nom} (${utilisateur.role.libelle})',
            style: textes.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.l),
          for (final lien in liens) ...[
            OutlinedButton(
              // context.push : empile la page (bouton retour disponible).
              onPressed: () => context.push(lien.adresse),
              child: Text(lien.libelle),
            ),
            const SizedBox(height: AppSpacing.s),
          ],
        ],
      ),
    );
  }
}
