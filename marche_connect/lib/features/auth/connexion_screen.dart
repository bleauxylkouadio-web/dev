// =====================================================================
//  connexion_screen.dart : ÉCRAN DE CONNEXION (téléphone + code OTP)
//
//  Module « Compte » : pas de mot de passe, un code par SMS suffit.
//  L'écran ne fait qu'AFFICHER l'état du ConnexionController et lui
//  transmettre les actions (voir connexion_controller.dart).
//
//  Après une connexion réussie, l'écran ne navigue pas lui-même :
//  le routeur voit la session changer et applique la règle 4 de
//  redirection.dart (accueil du rôle ou page demandée avant).
// =====================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/identite.dart';
import '../../data/mock/mock_data.dart';
import '../../data/repositories/providers.dart';
import 'connexion_controller.dart';
import 'widgets/etape_code.dart';
import 'widgets/etape_inscription.dart';
import 'widgets/etape_telephone.dart';

/// ConsumerStatefulWidget : comme StatefulWidget, avec accès à `ref`.
/// Il nous faut un état pour garder la clé du champ téléphone (comptes de démo).
class ConnexionScreen extends ConsumerStatefulWidget {
  const ConnexionScreen({super.key});

  @override
  ConsumerState<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends ConsumerState<ConnexionScreen> {
  /// Clé pour accéder à EtapeTelephoneState (méthode remplir()).
  final _cleTelephone = GlobalKey<EtapeTelephoneState>();

  @override
  Widget build(BuildContext context) {
    // ref.watch : l'écran se redessine à chaque changement d'état.
    final etat = ref.watch(connexionControllerProvider);
    // ref.read(...notifier) : pour APPELER les actions (pas d'écoute).
    final controleur = ref.read(connexionControllerProvider.notifier);
    final textes = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        // Flèche retour : consulter sans compte reste possible (UX-01).
        leading: IconButton(
          tooltip: 'Retour aux étals',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.etals),
        ),
      ),
      body: SafeArea(
        // Center + ConstrainedBox : sur ordinateur (PWA, back-office),
        // le formulaire ne s'étale pas sur toute la largeur.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.l),
              children: [
                // ---------- En-tête ----------
                // Logo de la marque (pictogramme + « MarchéConnect »).
                const Center(child: LogoMarcheConnect(taille: 52)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  switch (etat.etape) {
                    EtapeConnexion.telephone =>
                      'Entrez votre numéro.\nPas de mot de passe : un code par SMS suffit.',
                    EtapeConnexion.code => 'Entrez le code à 6 chiffres reçu par SMS.',
                    EtapeConnexion.inscription => 'Bienvenue ! Créons votre compte.',
                  },
                  style: textes.bodyMedium?.copyWith(color: AppColors.texteSecondaire),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.l),

                // ---------- Message d'erreur ----------
                if (etat.erreur != null) ...[
                  _BandeauErreur(message: etat.erreur!),
                  const SizedBox(height: AppSpacing.m),
                ],

                // ---------- Étape 1, 2 ou 3 ----------
                // AnimatedSwitcher : fondu enchaîné entre les étapes.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: switch (etat.etape) {
                    EtapeConnexion.telephone => EtapeTelephone(
                        key: _cleTelephone,
                        enCours: etat.enCours,
                        numeroInitial: etat.telephone,
                        onValider: controleur.envoyerCode,
                      ),
                    EtapeConnexion.code => EtapeCode(
                        key: const ValueKey('etape-code'),
                        telephone: etat.telephone,
                        enCours: etat.enCours,
                        onValider: controleur.verifierCode,
                        onRenvoyer: controleur.renvoyerCode,
                        onModifierNumero: controleur.modifierNumero,
                      ),
                    EtapeConnexion.inscription => EtapeInscription(
                        key: const ValueKey('etape-inscription'),
                        telephone: etat.telephone,
                        enCours: etat.enCours,
                        onValider: controleur.inscrire,
                      ),
                  },
                ),

                // ---------- Comptes de démo (développement uniquement) ----------
                // kDebugMode est faux dans l'application publiée :
                // ce bloc disparaît automatiquement en production.
                if (kDebugMode && etat.etape == EtapeConnexion.telephone) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _ComptesDemo(onChoisir: (tel) => _cleTelephone.currentState?.remplir(tel)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bandeau rouge avec icône, pour les erreurs.
class _BandeauErreur extends StatelessWidget {
  const _BandeauErreur({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.erreurClair,
        borderRadius: BorderRadius.circular(AppRadius.moyen),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: AppColors.erreur),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.erreur, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Liste repliable des comptes de démo : un appui remplit le numéro.
class _ComptesDemo extends ConsumerWidget {
  const _ComptesDemo({required this.onChoisir});

  final ValueChanged<String> onChoisir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateurs = ref.watch(mockDatabaseProvider).utilisateurs;

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.science),
        title: const Text('Comptes de démo'),
        subtitle: const Text('Code : $codeOtpDemo'),
        children: [
          for (final u in utilisateurs)
            ListTile(
              title: Text('${u.role.libelle} : ${u.nom}'),
              subtitle: Text(formaterTelephone(u.telephone)),
              trailing: const Icon(Icons.touch_app),
              onTap: () => onChoisir(u.telephone),
            ),
        ],
      ),
    );
  }
}
