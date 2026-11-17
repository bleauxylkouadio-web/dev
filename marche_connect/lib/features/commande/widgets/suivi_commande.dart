// =====================================================================
//  suivi_commande.dart : les ÉTAPES d'une commande, en frise verticale
//
//   ✔ Commande envoyée            14 h 25
//   ✔ Confirmée par le commerçant 14 h 28
//   ● Prête                       ← étape actuelle (en gras)
//   ○ En livraison
//   ○ Livrée
//
//  Module « Livraison » : suivi du statut (ACH-03).
//  Pour un RETRAIT, l'étape « En livraison » n'existe pas et
//  « Livrée » devient « Récupérée ».
// =====================================================================

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';

class SuiviCommande extends StatelessWidget {
  const SuiviCommande({super.key, required this.commande});

  final Commande commande;

  /// Les étapes à afficher, avec leur libellé adapté au mode.
  List<(StatutCommande, String)> get _etapes {
    final livraison = commande.modeLivraison == ModeLivraison.livraison;
    return [
      (StatutCommande.enAttente, 'Commande envoyée'),
      (StatutCommande.confirmee, 'Confirmée par le commerçant'),
      (StatutCommande.prete, livraison ? 'Prête, en attente du livreur' : 'Prête, à récupérer'),
      if (livraison) (StatutCommande.enLivraison, 'En route'),
      (StatutCommande.livree, livraison ? 'Livrée' : 'Récupérée'),
    ];
  }

  /// Heure connue de certaines étapes.
  String? _heureDe(StatutCommande statut) => switch (statut) {
        StatutCommande.enAttente => formaterHeure(commande.creeLe),
        StatutCommande.confirmee =>
          commande.confirmeeLe == null ? null : formaterHeure(commande.confirmeeLe!),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    // Commande annulée : un seul message, pas de frise.
    if (commande.statut == StatutCommande.annulee) {
      return const ListTile(
        leading: Icon(Icons.cancel, color: AppColors.erreur, size: 32),
        title: Text('Commande annulée'),
        subtitle: Text('Si vous avez payé, vous serez remboursé.'),
      );
    }

    final etapes = _etapes;
    // Position de l'étape actuelle dans la frise.
    final actuelle = etapes.indexWhere((e) => e.$1 == commande.statut);

    return Column(
      children: [
        for (var i = 0; i < etapes.length; i++)
          _LigneEtape(
            libelle: etapes[i].$2,
            heure: _heureDe(etapes[i].$1),
            faite: i < actuelle || commande.statut == StatutCommande.livree,
            actuelle: i == actuelle && commande.statut != StatutCommande.livree,
            derniere: i == etapes.length - 1,
          ),
      ],
    );
  }
}

class _LigneEtape extends StatelessWidget {
  const _LigneEtape({
    required this.libelle,
    required this.faite,
    required this.actuelle,
    required this.derniere,
    this.heure,
  });

  final String libelle;
  final String? heure;
  final bool faite;
  final bool actuelle;
  final bool derniere;

  @override
  Widget build(BuildContext context) {
    final couleur = faite || actuelle ? AppColors.primaire : AppColors.bordure;
    final icone = faite
        ? Icons.check_circle
        : actuelle
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked;

    // IntrinsicHeight : la ligne verticale prend la hauteur du texte.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------- Pastille + trait vertical ----------
          Column(
            children: [
              Icon(icone, color: couleur, size: 28),
              if (!derniere)
                Expanded(
                  child: Container(width: 3, color: faite ? AppColors.primaire : AppColors.bordure),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.m),
          // ---------- Texte ----------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: AppSpacing.m),
              child: Text(
                libelle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: actuelle ? FontWeight.w800 : FontWeight.w500,
                  color: faite || actuelle ? AppColors.texte : AppColors.texteSecondaire,
                ),
              ),
            ),
          ),
          if (heure != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(heure!, style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}
