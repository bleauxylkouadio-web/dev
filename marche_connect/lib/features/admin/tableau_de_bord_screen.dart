// =====================================================================
//  tableau_de_bord_screen.dart : BACK-OFFICE ADMINISTRATEUR
//
//  « Back-office sur navigateur » (besoins non fonctionnels) : l'écran
//  s'adapte à la largeur disponible (responsive) :
//
//   Ordinateur (≥ 840 px)                Téléphone
//   ┌────┬──────────────────────┐        ┌──────────────────┐
//   │ 📊 │                      │        │                  │
//   │ ⚖ │   section choisie    │        │ section choisie  │
//   │ 👥 │                      │        │                  │
//   │ 🏪 │                      │        ├──────────────────┤
//   └────┴──────────────────────┘        │ 📊  ⚖  👥  🏪    │
//    NavigationRail (à gauche)           └──────────────────┘
//                                         NavigationBar (en bas)
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../auth/session_provider.dart';
import 'admin_providers.dart';
import 'sections/comptes_section.dart';
import 'sections/etals_section.dart';
import 'sections/litiges_section.dart';
import 'sections/statistiques_section.dart';

/// Les 4 sections : (icône, libellé).
const _sections = [
  (Icons.insights, 'Tableau de bord'),
  (Icons.gavel, 'Litiges'),
  (Icons.people, 'Comptes'),
  (Icons.storefront, 'Étals'),
];

class TableauDeBordScreen extends ConsumerStatefulWidget {
  const TableauDeBordScreen({super.key});

  @override
  ConsumerState<TableauDeBordScreen> createState() => _TableauDeBordScreenState();
}

class _TableauDeBordScreenState extends ConsumerState<TableauDeBordScreen> {
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    // Nombre de litiges à traiter (pastille rouge).
    final nbLitiges = (ref.watch(litigesProvider(StatutLitige.ouvert)).value ?? []).length;

    Widget icone(int i) {
      final ic = Icon(_sections[i].$1);
      return i == 1 ? Badge(isLabelVisible: nbLitiges > 0, label: Text('$nbLitiges'), child: ic) : ic;
    }

    final contenu = switch (_section) {
      0 => const StatistiquesSection(),
      1 => const LitigesSection(),
      2 => const ComptesSection(),
      _ => const EtalsSection(),
    };

    // LayoutBuilder donne la largeur disponible pour choisir la mise en page.
    return LayoutBuilder(
      builder: (context, contraintes) {
        final large = contraintes.maxWidth >= 840;

        return Scaffold(
          appBar: AppBar(
            title: Text('Back-office · ${_sections[_section].$2}'),
            actions: [
              IconButton(
                tooltip: 'Se déconnecter',
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(sessionProvider.notifier).deconnecter(),
              ),
            ],
          ),
          bottomNavigationBar: large
              ? null
              : NavigationBar(
                  selectedIndex: _section,
                  onDestinationSelected: (i) => setState(() => _section = i),
                  destinations: [
                    for (var i = 0; i < _sections.length; i++)
                      NavigationDestination(icon: icone(i), label: _sections[i].$2),
                  ],
                ),
          body: large
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _section,
                      onDestinationSelected: (i) => setState(() => _section = i),
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (var i = 0; i < _sections.length; i++)
                          NavigationRailDestination(icon: icone(i), label: Text(_sections[i].$2)),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    // Sur grand écran, le contenu ne dépasse pas 960 px de large.
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: contenu,
                        ),
                      ),
                    ),
                  ],
                )
              : contenu,
        );
      },
    );
  }
}
