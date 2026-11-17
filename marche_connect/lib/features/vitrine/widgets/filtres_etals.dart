// =====================================================================
//  filtres_etals.dart : barre de recherche + puces de filtre
//
//   ┌ 🔍 Rechercher un étal, un marché… ┐
//   [Toutes] [Cocody] [Abobo] [Adjamé] [Treichville]   ← défile →
//   [🥬 Légumes] [🍎 Fruits] [🍽 Plats cuisinés] …     ← défile →
// =====================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/icones.dart';
import '../../../data/models/models.dart';
import '../vitrine_providers.dart';

class FiltresEtalsBarre extends ConsumerStatefulWidget {
  const FiltresEtalsBarre({super.key});

  @override
  ConsumerState<FiltresEtalsBarre> createState() => _FiltresEtalsBarreState();
}

class _FiltresEtalsBarreState extends ConsumerState<FiltresEtalsBarre> {
  final _recherche = TextEditingController();

  /// « Anti-rebond » (debounce) : on attend 400 ms sans frappe avant de
  /// lancer la recherche. Sans ça, « tomate » ferait 6 appels réseau.
  Timer? _antiRebond;

  @override
  void dispose() {
    _antiRebond?.cancel();
    _recherche.dispose();
    super.dispose();
  }

  void _surSaisie(String texte) {
    _antiRebond?.cancel();
    _antiRebond = Timer(const Duration(milliseconds: 400), () {
      ref.read(filtresEtalsProvider.notifier).rechercher(texte);
    });
    setState(() {}); // pour afficher/masquer la croix d'effacement
  }

  @override
  Widget build(BuildContext context) {
    final filtres = ref.watch(filtresEtalsProvider);
    final actions = ref.read(filtresEtalsProvider.notifier);

    // Si les filtres sont effacés ailleurs (« Effacer les filtres »),
    // on vide aussi le champ texte.
    if (filtres.recherche.isEmpty && _recherche.text.isNotEmpty && _antiRebond?.isActive != true) {
      _recherche.clear();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------- Recherche ----------
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, AppSpacing.s),
          child: TextField(
            controller: _recherche,
            onChanged: _surSaisie,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Rechercher un étal, un marché…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _recherche.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Effacer la recherche',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _recherche.clear();
                        _surSaisie('');
                      },
                    ),
            ),
          ),
        ),

        // ---------- Communes ----------
        _LignePuces(
          children: [
            ChoiceChip(
              label: const Text('Toutes'),
              selected: filtres.commune == null,
              onSelected: (_) => actions.choisirCommune(null),
            ),
            for (final commune in Commune.values)
              ChoiceChip(
                label: Text(commune.libelle),
                selected: filtres.commune == commune,
                onSelected: (_) => actions.choisirCommune(commune),
              ),
          ],
        ),

        // ---------- Catégories (avec icônes, UX-02) ----------
        _LignePuces(
          children: [
            for (final categorie in CategorieProduit.values)
              if (categorie != CategorieProduit.autres)
                FilterChip(
                  avatar: Icon(iconeCategorie(categorie), size: 18),
                  label: Text(categorie.libelle),
                  selected: filtres.categorie == categorie,
                  showCheckmark: false,
                  onSelected: (_) => actions.choisirCategorie(categorie),
                ),
          ],
        ),
      ],
    );
  }
}

/// Une ligne de puces qui défile horizontalement (pas de retour à la
/// ligne : on garde de la place pour la liste des étals).
class _LignePuces extends StatelessWidget {
  const _LignePuces({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
      child: Row(
        children: [
          for (final puce in children) ...[puce, const SizedBox(width: AppSpacing.s)],
        ],
      ),
    );
  }
}
