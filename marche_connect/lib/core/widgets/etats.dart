// =====================================================================
//  etats.dart : les 3 écrans « d'attente » qu'on retrouve partout
//
//  Chaque écran qui charge des données passe par 3 états possibles :
//    1. Chargement      → Chargement()
//    2. Erreur réseau   → MessageErreur(onReessayer: ...)
//    3. Liste vide      → EtatVide(...)
//  (puis 4. les données, propres à chaque écran)
//
//  Connexion irrégulière (MAR-04) : le bouton « Réessayer » est
//  indispensable, l'utilisateur ne doit jamais rester bloqué.
// =====================================================================

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

/// Rond qui tourne + message court.
class Chargement extends StatelessWidget {
  const Chargement({super.key, this.message = 'Chargement…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.m),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Bloc commun aux erreurs et aux listes vides : icône, titre, texte, bouton.
class _BlocMessage extends StatelessWidget {
  const _BlocMessage({
    required this.icone,
    required this.couleurIcone,
    required this.titre,
    this.message,
    this.libelleAction,
    this.onAction,
  });

  final IconData icone;
  final Color couleurIcone;
  final String titre;
  final String? message;
  final String? libelleAction;
  final VoidCallback? onAction; // VoidCallback = fonction sans paramètre

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 64, color: couleurIcone),
            const SizedBox(height: AppSpacing.m),
            Text(titre, style: textes.titleLarge, textAlign: TextAlign.center),
            // `if` dans une liste : l'élément n'est ajouté que si la condition est vraie.
            if (message != null) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                message!,
                style: textes.bodyMedium?.copyWith(color: AppColors.texteSecondaire),
                textAlign: TextAlign.center,
              ),
            ],
            if (libelleAction != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.l),
              FilledButton(onPressed: onAction, child: Text(libelleAction!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Erreur (souvent réseau), avec bouton « Réessayer ».
class MessageErreur extends StatelessWidget {
  const MessageErreur({
    super.key,
    this.titre = 'Connexion impossible',
    this.message = 'Vérifiez votre connexion internet puis réessayez.',
    required this.onReessayer,
  });

  final String titre;
  final String message;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    return _BlocMessage(
      icone: Icons.wifi_off,
      couleurIcone: AppColors.erreur,
      titre: titre,
      message: message,
      libelleAction: 'Réessayer',
      onAction: onReessayer,
    );
  }
}

/// Liste vide : « Aucune commande pour l'instant ».
class EtatVide extends StatelessWidget {
  const EtatVide({
    super.key,
    required this.titre,
    this.message,
    this.icone = Icons.inbox,
    this.libelleAction,
    this.onAction,
  });

  final String titre;
  final String? message;
  final IconData icone;
  final String? libelleAction;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _BlocMessage(
      icone: icone,
      couleurIcone: AppColors.texteSecondaire,
      titre: titre,
      message: message,
      libelleAction: libelleAction,
      onAction: onAction,
    );
  }
}
