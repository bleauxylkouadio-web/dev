// =====================================================================
//  litiges_section.dart : TRAITEMENT DES LITIGES (ACH-04 : sous 48 h)
//
//   [À traiter] [Traités] [Tous]
//   ┌ N° 209 377 · Pagnes Akissi        reste 18 h ┐
//   │ Awa Traoré · Produit non conforme · 9 000 F  │
//   │ « Le motif du pagne ne correspond pas… »     │
//   │ [Rejeter]              [Rembourser le client] │
//   └──────────────────────────────────────────────┘
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../admin_providers.dart';

class LitigesSection extends ConsumerStatefulWidget {
  const LitigesSection({super.key});

  @override
  ConsumerState<LitigesSection> createState() => _LitigesSectionState();
}

class _LitigesSectionState extends ConsumerState<LitigesSection> {
  /// Filtre : ouverts (par défaut), traités (null + filtre local) ou tous.
  String _filtre = 'ouverts';

  @override
  Widget build(BuildContext context) {
    final StatutLitige? statut = _filtre == 'ouverts' ? StatutLitige.ouvert : null;
    final litiges = ref.watch(litigesProvider(statut));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, 0),
          child: Wrap(
            spacing: AppSpacing.s,
            children: [
              for (final (cle, libelle) in [('ouverts', 'À traiter'), ('traites', 'Traités'), ('tous', 'Tous')])
                ChoiceChip(
                  label: Text(libelle),
                  selected: _filtre == cle,
                  onSelected: (_) => setState(() => _filtre = cle),
                ),
            ],
          ),
        ),
        Expanded(
          child: litiges.when(
            loading: () => const Chargement(),
            error: (_, _) => MessageErreur(onReessayer: () => ref.invalidate(litigesProvider)),
            data: (liste) {
              final affiches = _filtre == 'traites' ? liste.where((l) => !l.estOuvert).toList() : liste;
              if (affiches.isEmpty) {
                return const EtatVide(titre: 'Aucun litige', icone: Icons.verified);
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.m),
                itemCount: affiches.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
                itemBuilder: (context, i) => _CarteLitige(litige: affiches[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Fenêtre « message au client ». Widget à part entière pour que son
/// TextEditingController soit libéré au bon moment (dans dispose), et
/// non pendant l'animation de fermeture.
class _DialogueReponse extends StatefulWidget {
  const _DialogueReponse({required this.titre, required this.texteInitial});

  final String titre;
  final String texteInitial;

  @override
  State<_DialogueReponse> createState() => _DialogueReponseState();
}

class _DialogueReponseState extends State<_DialogueReponse> {
  late final _controleur = TextEditingController(text: widget.texteInitial);

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titre),
      content: TextField(
        controller: _controleur,
        maxLines: 4,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Message envoyé au client'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controleur.text),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}

class _CarteLitige extends ConsumerWidget {
  const _CarteLitige({required this.litige});

  final Litige litige;

  /// Demande la réponse au client puis applique la décision.
  Future<void> _decider(BuildContext context, WidgetRef ref, StatutLitige decision) async {
    final rembourser = decision == StatutLitige.rembourse;
    final reponse = await showDialog<String>(
      context: context,
      builder: (context) => _DialogueReponse(
        titre: rembourser ? 'Rembourser le client' : 'Rejeter le litige',
        texteInitial: rembourser
            ? 'Nous sommes désolés. Vous allez être remboursé de ${formaterPrix(litige.montantCommande)}.'
            : '',
      ),
    );
    if (reponse == null || reponse.trim().isEmpty) return;
    await ref.read(adminActionsProvider).traiterLitige(litige, decision: decision, reponse: reponse);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textes = Theme.of(context).textTheme;
    final maintenant = DateTime.now();
    final enRetard = litige.estEnRetard(maintenant);
    final heuresRestantes = litige.limiteTraitement.difference(maintenant).inHours;

    return Card(
      // Bordure rouge si le délai de 48 h est dépassé.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.moyen),
        side: enRetard ? const BorderSide(color: AppColors.erreur, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'N° ${litige.numeroFormate} · ${litige.nomEtal}',
                    style: textes.titleMedium,
                  ),
                ),
                if (litige.estOuvert)
                  Flexible(
                    child: Etiquette(
                      texte: enRetard ? 'En retard' : 'Reste $heuresRestantes h',
                      icone: Icons.timer,
                      couleur: enRetard ? AppColors.erreur : AppColors.attente,
                      fond: enRetard ? AppColors.erreurClair : AppColors.attenteClair,
                    ),
                  )
                else
                  Flexible(
                    child: Etiquette(
                      texte: litige.statut.libelle,
                      icone: Icons.check,
                      couleur: AppColors.succes,
                      fond: AppColors.succesClair,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${litige.nomClient} · ${litige.motif.libelle} · ${formaterPrix(litige.montantCommande)}',
              style: textes.bodyMedium,
            ),
            Text('Signalé ${formaterDepuis(litige.creeLe)}', style: textes.bodySmall),
            if (litige.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s),
              Text('« ${litige.description} »', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            if (litige.reponse != null) ...[
              const SizedBox(height: AppSpacing.s),
              Text('Réponse : ${litige.reponse}', style: textes.bodySmall),
            ],
            if (litige.estOuvert) ...[
              const SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _decider(context, ref, StatutLitige.rejete),
                      child: const Text('Rejeter'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _decider(context, ref, StatutLitige.rembourse),
                      child: const Text('Rembourser'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
