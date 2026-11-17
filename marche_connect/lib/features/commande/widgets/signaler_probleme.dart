// =====================================================================
//  signaler_probleme.dart : « Signaler un problème » (ACH-04)
//
//  Affiché sur le ticket d'une commande LIVRÉE :
//   - pas encore de litige → bouton « Signaler un problème »
//     → feuille : motif (puces) + précision facultative
//   - litige existant      → son état et la réponse de l'équipe
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/providers.dart';
import '../commande_providers.dart';

class SignalerProbleme extends ConsumerWidget {
  const SignalerProbleme({super.key, required this.commande});

  final Commande commande;

  Future<void> _ouvrir(BuildContext context, WidgetRef ref) async {
    final envoye = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FeuilleSignalement(commande: commande),
    );
    if (envoye == true && context.mounted) {
      ref.invalidate(litigeDeCommandeProvider(commande.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signalement envoyé. Réponse sous 48 h.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final litige = ref.watch(litigeDeCommandeProvider(commande.id));

    return litige.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (l) => l == null
          ? OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.erreur,
                side: const BorderSide(color: AppColors.erreur, width: 2),
              ),
              onPressed: () => _ouvrir(context, ref),
              icon: const Icon(Icons.report_problem),
              label: const Text('Signaler un problème'),
            )
          : _EtatLitige(litige: l),
    );
  }
}

/// Carte « Problème signalé » avec l'état du traitement.
class _EtatLitige extends StatelessWidget {
  const _EtatLitige({required this.litige});

  final Litige litige;

  @override
  Widget build(BuildContext context) {
    final ouvert = litige.estOuvert;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: ouvert ? AppColors.attenteClair : AppColors.primaireClair,
        borderRadius: BorderRadius.circular(AppRadius.moyen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Problème signalé : ${litige.motif.libelle}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            ouvert
                ? 'En cours de traitement · réponse avant le '
                    '${formaterDateCourte(litige.limiteTraitement)} à ${formaterHeure(litige.limiteTraitement)}'
                : litige.statut.libelle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (litige.reponse != null && litige.reponse!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            Text('Réponse : ${litige.reponse}'),
          ],
        ],
      ),
    );
  }
}

/// Feuille de signalement : motif + précision.
class _FeuilleSignalement extends ConsumerStatefulWidget {
  const _FeuilleSignalement({required this.commande});

  final Commande commande;

  @override
  ConsumerState<_FeuilleSignalement> createState() => _FeuilleSignalementState();
}

class _FeuilleSignalementState extends ConsumerState<_FeuilleSignalement> {
  MotifLitige? _motif;
  final _description = TextEditingController();
  bool _enCours = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() => _enCours = true);
    try {
      await ref.read(litigeRepositoryProvider).signaler(
            commande: widget.commande,
            motif: _motif!,
            description: _description.text,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _enCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'envoi a échoué. Réessayez.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l, AppSpacing.l, AppSpacing.l,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.l,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Quel est le problème ?', style: textes.titleLarge),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final m in MotifLitige.values)
                ChoiceChip(
                  label: Text(m.libelle),
                  selected: _motif == m,
                  onSelected: (_) => setState(() => _motif = m),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: _description,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Précisez (facultatif)'),
          ),
          const SizedBox(height: AppSpacing.s),
          Text('Notre équipe vous répond sous 48 h.', style: textes.bodySmall),
          const SizedBox(height: AppSpacing.m),
          FilledButton(
            // Bouton grisé tant qu'aucun motif n'est choisi.
            onPressed: _motif == null || _enCours ? null : _envoyer,
            child: const Text('Envoyer le signalement'),
          ),
        ],
      ),
    );
  }
}
