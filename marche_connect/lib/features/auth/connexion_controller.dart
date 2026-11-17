// =====================================================================
//  connexion_controller.dart : la LOGIQUE de l'écran de connexion
//
//  On sépare la logique (ici) de l'affichage (connexion_screen.dart) :
//    - l'écran affiche l'état et transmet les appuis ;
//    - le contrôleur décide quoi faire (appeler le repository, gérer
//      les erreurs, connecter l'utilisateur).
//  Avantage : la logique se teste sans écran.
//
//  Déroulé :
//    Étape 1 « téléphone »  ── envoyerCode() ──►  Étape 2 « code »
//    Étape 2 « code »       ── verifierCode() ──► connecté ✔
//                           ── modifierNumero() ─► retour étape 1
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../data/repositories/providers.dart';
import 'session_provider.dart';

/// Les deux étapes de l'écran.
enum EtapeConnexion { telephone, code }

/// L'ÉTAT de l'écran à un instant donné. Immuable : chaque changement
/// crée un nouvel état avec copyWith.
class ConnexionState {
  const ConnexionState({
    this.etape = EtapeConnexion.telephone,
    this.telephone = '',
    this.enCours = false,
    this.erreur,
  });

  final EtapeConnexion etape;

  /// Numéro nettoyé (10 chiffres), rempli après l'étape 1.
  final String telephone;

  /// Vrai pendant un appel réseau : on affiche un rond qui tourne et
  /// on désactive le bouton (évite les doubles envois).
  final bool enCours;

  /// Message d'erreur à afficher, ou null.
  final String? erreur;

  ConnexionState copyWith({
    EtapeConnexion? etape,
    String? telephone,
    bool? enCours,
    String? erreur,
    bool effacerErreur = false,
  }) {
    return ConnexionState(
      etape: etape ?? this.etape,
      telephone: telephone ?? this.telephone,
      enCours: enCours ?? this.enCours,
      erreur: effacerErreur ? null : (erreur ?? this.erreur),
    );
  }
}

class ConnexionController extends Notifier<ConnexionState> {
  @override
  ConnexionState build() => const ConnexionState();

  /// Étape 1 : demande l'envoi du code par SMS.
  Future<void> envoyerCode(String saisie) async {
    final telephone = nettoyerTelephone(saisie);
    state = state.copyWith(enCours: true, effacerErreur: true);
    try {
      await ref.read(authRepositoryProvider).envoyerCode(telephone);
      state = state.copyWith(
        etape: EtapeConnexion.code,
        telephone: telephone,
        enCours: false,
      );
    } catch (_) {
      // Réseau coupé, serveur indisponible… : message simple (UX-02).
      state = state.copyWith(
        enCours: false,
        erreur: "Le code n'a pas pu être envoyé. Vérifiez votre connexion.",
      );
    }
  }

  /// Bouton « Renvoyer le code » : même appel, on reste à l'étape 2.
  Future<void> renvoyerCode() async {
    state = state.copyWith(enCours: true, effacerErreur: true);
    try {
      await ref.read(authRepositoryProvider).envoyerCode(state.telephone);
      state = state.copyWith(enCours: false);
    } catch (_) {
      state = state.copyWith(enCours: false, erreur: "Le code n'a pas pu être renvoyé.");
    }
  }

  /// Étape 2 : vérifie le code. Renvoie vrai si la connexion a réussi.
  Future<bool> verifierCode(String code) async {
    state = state.copyWith(enCours: true, effacerErreur: true);
    try {
      final utilisateur = await ref
          .read(authRepositoryProvider)
          .verifierCode(state.telephone, code.trim());

      if (utilisateur == null) {
        state = state.copyWith(enCours: false, erreur: 'Code incorrect. Réessayez.');
        return false;
      }
      // ✔ Connecté : on remplit la session. Le routeur est prévenu et
      // emmène l'utilisateur vers son accueil (ou la page demandée).
      ref.read(sessionProvider.notifier).connecter(utilisateur);
      state = state.copyWith(enCours: false);
      return true;
    } catch (_) {
      state = state.copyWith(
        enCours: false,
        erreur: 'Vérification impossible. Vérifiez votre connexion.',
      );
      return false;
    }
  }

  /// Lien « Modifier le numéro » : retour à l'étape 1.
  void modifierNumero() {
    state = state.copyWith(etape: EtapeConnexion.telephone, effacerErreur: true);
  }
}

/// `.autoDispose` : l'état est effacé quand on quitte l'écran.
/// En revenant plus tard, on repart de l'étape 1, champ vide.
final connexionControllerProvider =
    NotifierProvider.autoDispose<ConnexionController, ConnexionState>(
  ConnexionController.new,
);
