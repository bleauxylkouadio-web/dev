// =====================================================================
//  choix_livraison.dart : « Retrait à l'étal » ou « Livraison »
//
//   [ 🏪 Retrait à l'étal | 🛵 Livraison ]     ← SegmentedButton
//
//   Retrait   → heure : [Dès que possible] [Dans 1 h] [Dans 2 h] [Autre…]
//   Livraison → adresse / point de repère
//               commune : (●) Adjamé 500 F  ( ) Cocody 1 000 F …
//               Délai estimé : 30 à 60 min
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../options_livraison.dart';

class ChoixLivraison extends ConsumerWidget {
  const ChoixLivraison({super.key, required this.communeEtal, this.afficherErreur = false});

  /// Commune de l'étal : livrer dans cette commune coûte 500 F, ailleurs 1 000 F.
  final Commune? communeEtal;

  /// Vrai après un appui sur « Continuer » avec un choix incomplet.
  final bool afficherErreur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(optionsLivraisonProvider);
    final actions = ref.read(optionsLivraisonProvider.notifier);
    final textes = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Comment récupérer la commande ?', style: textes.titleMedium),
            const SizedBox(height: AppSpacing.s),

            // SegmentedButton : 2 choix côte à côte, un seul sélectionné.
            SegmentedButton<ModeLivraison>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ModeLivraison.retrait,
                  icon: Icon(Icons.storefront),
                  label: Text('Retrait'),
                ),
                ButtonSegment(
                  value: ModeLivraison.livraison,
                  icon: Icon(Icons.delivery_dining),
                  label: Text('Livraison'),
                ),
              ],
              selected: {options.mode},
              onSelectionChanged: (choix) => actions.choisirMode(choix.first),
            ),
            const SizedBox(height: AppSpacing.m),

            if (options.mode == ModeLivraison.retrait)
              _ChoixHeure(options: options, actions: actions)
            else
              _ChoixAdresse(
                options: options,
                actions: actions,
                communeEtal: communeEtal,
                afficherErreur: afficherErreur,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  RETRAIT : heure (MAR-02)
// ---------------------------------------------------------------------
class _ChoixHeure extends StatelessWidget {
  const _ChoixHeure({required this.options, required this.actions});

  final OptionsLivraison options;
  final OptionsLivraisonNotifier actions;

  /// Ouvre l'horloge de Flutter pour choisir une heure précise.
  Future<void> _autreHeure(BuildContext context) async {
    final heure = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))),
      helpText: 'Heure de retrait',
    );
    if (heure == null) return; // annulé
    final now = DateTime.now();
    actions.choisirHeurePerso(DateTime(now.year, now.month, now.day, heure.hour, heure.minute));
  }

  @override
  Widget build(BuildContext context) {
    final choix = options.choixHeure;
    final perso = options.heurePerso;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quand passez-vous à l'étal ?", style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            ChoiceChip(
              label: const Text('Dès que possible'),
              selected: choix == ChoixHeure.desQuePossible,
              onSelected: (_) => actions.choisirHeure(ChoixHeure.desQuePossible),
            ),
            ChoiceChip(
              label: const Text('Dans 1 h'),
              selected: choix == ChoixHeure.dansUneHeure,
              onSelected: (_) => actions.choisirHeure(ChoixHeure.dansUneHeure),
            ),
            ChoiceChip(
              label: const Text('Dans 2 h'),
              selected: choix == ChoixHeure.dansDeuxHeures,
              onSelected: (_) => actions.choisirHeure(ChoixHeure.dansDeuxHeures),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.schedule, size: 18),
              label: Text(
                choix == ChoixHeure.autre && perso != null ? formaterHeure(perso) : 'Autre heure',
              ),
              selected: choix == ChoixHeure.autre,
              onSelected: (_) => _autreHeure(context),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
//  LIVRAISON : adresse, zone, frais et délai (ACH-03)
// ---------------------------------------------------------------------
class _ChoixAdresse extends StatelessWidget {
  const _ChoixAdresse({
    required this.options,
    required this.actions,
    required this.communeEtal,
    required this.afficherErreur,
  });

  final OptionsLivraison options;
  final OptionsLivraisonNotifier actions;
  final Commune? communeEtal;
  final bool afficherErreur;

  @override
  Widget build(BuildContext context) {
    // Messages rouges seulement après un essai de validation.
    final erreurCommune = afficherErreur && options.commune == null;
    final erreurAdresse = afficherErreur && options.adresse.trim().length < 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------- Commune (fixe les frais) ----------
        Text('Commune de livraison', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.s),
        for (final c in Commune.values) ...[
          _OptionZone(
            titre: c == communeEtal ? '${c.libelle} (commune de l\'étal)' : c.libelle,
            prix: c == communeEtal ? TarifsLivraison.memeCommune : TarifsLivraison.autreCommune,
            choisi: options.commune == c,
            onTap: () => actions.choisirCommune(c, communeEtal: communeEtal),
          ),
          const SizedBox(height: AppSpacing.s),
        ],
        if (erreurCommune)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.s),
            child: Text('Choisissez la commune de livraison.', style: TextStyle(color: AppColors.erreur)),
          ),
        const SizedBox(height: AppSpacing.s),

        // ---------- Adresse ----------
        TextFormField(
          initialValue: options.adresse,
          onChanged: actions.saisirAdresse,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Adresse ou point de repère',
            hintText: 'Ex. : Angré 8e tranche, derrière la pharmacie',
            prefixIcon: const Icon(Icons.home),
            errorText: erreurAdresse ? 'Indiquez votre adresse ou un point de repère.' : null,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          children: [
            const Icon(Icons.timer, size: 20, color: AppColors.texteSecondaire),
            const SizedBox(width: AppSpacing.xs),
            // Expanded : le texte passe à la ligne au lieu de déborder.
            Expanded(
              child: Text(
                'Délai estimé : ${TarifsLivraison.delaiAnnonce}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Carte sélectionnable « zone + prix » (plus grosse qu'un bouton radio).
class _OptionZone extends StatelessWidget {
  const _OptionZone({
    required this.titre,
    required this.prix,
    required this.choisi,
    required this.onTap,
  });

  final String titre;
  final int prix;
  final bool choisi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.moyen),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: choisi ? AppColors.primaireClair : null,
          borderRadius: BorderRadius.circular(AppRadius.moyen),
          border: Border.all(
            color: choisi ? AppColors.primaire : AppColors.bordure,
            width: choisi ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              choisi ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: AppColors.primaire,
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(child: Text(titre)),
            Text(formaterPrix(prix), style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
