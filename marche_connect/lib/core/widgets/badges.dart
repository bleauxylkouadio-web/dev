// =====================================================================
//  badges.dart : petites étiquettes colorées
//
//  Toujours COULEUR + ICÔNE + TEXTE : compréhensible par une personne
//  daltonienne, en plein soleil, ou qui lit difficilement.
// =====================================================================

import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../utils/icones.dart';

/// Étiquette de base, réutilisée par tous les badges ci-dessous.
/// (On ne l'appelle pas « Badge » : ce nom existe déjà dans Flutter.)
class Etiquette extends StatelessWidget {
  const Etiquette({
    super.key,
    required this.texte,
    required this.icone,
    required this.couleur,
    required this.fond,
  });

  final String texte;
  final IconData icone;
  final Color couleur; // couleur du texte et de l'icône
  final Color fond; // couleur de fond, plus claire

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(AppRadius.petit),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // juste la largeur du contenu
        children: [
          Icon(icone, size: 18, color: couleur),
          const SizedBox(width: AppSpacing.xs),
          // Flexible : un texte long (« En attente de confirmation ») passe
          // à la ligne au lieu de déborder sur un petit écran.
          Flexible(
            child: Text(
              texte,
              style: TextStyle(
                color: couleur,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// « Disponible » (vert) ou « Épuisé » (rouge) — maquettes Vitrine et Espace commerçant.
class BadgeDisponibilite extends StatelessWidget {
  const BadgeDisponibilite({super.key, required this.disponible});

  final bool disponible;

  @override
  Widget build(BuildContext context) {
    return disponible
        ? const Etiquette(
            texte: 'Disponible',
            icone: Icons.check_circle,
            couleur: AppColors.succes,
            fond: AppColors.succesClair,
          )
        : const Etiquette(
            texte: 'Épuisé',
            icone: Icons.cancel,
            couleur: AppColors.erreur,
            fond: AppColors.erreurClair,
          );
  }
}

/// Statut d'une commande : « En attente », « Prête », « Livrée »…
class BadgeStatutCommande extends StatelessWidget {
  const BadgeStatutCommande({super.key, required this.statut});

  final StatutCommande statut;

  @override
  Widget build(BuildContext context) {
    // Choix des couleurs selon le statut.
    final (couleur, fond) = switch (statut) {
      StatutCommande.enAttente => (AppColors.attente, AppColors.attenteClair),
      StatutCommande.annulee => (AppColors.erreur, AppColors.erreurClair),
      StatutCommande.livree => (AppColors.succes, AppColors.succesClair),
      _ => (AppColors.primaireFonce, AppColors.primaireClair), // en cours
    };

    return Etiquette(
      texte: statut.libelle,
      icone: iconeStatut(statut),
      couleur: couleur,
      fond: fond,
    );
  }
}

/// Note d'un étal : « ★ 4,6 (23 avis) », ou « Nouveau » sans avis.
class BadgeNote extends StatelessWidget {
  const BadgeNote({super.key, required this.note, required this.nombreAvis});

  final double note;
  final int nombreAvis;

  @override
  Widget build(BuildContext context) {
    if (nombreAvis == 0) {
      return const Etiquette(
        texte: 'Nouveau',
        icone: Icons.fiber_new,
        couleur: AppColors.primaireFonce,
        fond: AppColors.primaireClair,
      );
    }
    return Etiquette(
      texte: '${note.toStringAsFixed(1).replaceAll('.', ',')} ($nombreAvis avis)',
      icone: Icons.star,
      couleur: AppColors.attente,
      fond: AppColors.attenteClair,
    );
  }
}
