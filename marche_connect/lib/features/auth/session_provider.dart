// =====================================================================
//  session_provider.dart : QUI est connecté en ce moment ?
//
//  La session contient l'utilisateur connecté, ou `null` si personne
//  ne l'est (visiteur : il peut consulter les étals sans compte, UX-01).
//
//  Riverpod « Notifier » = une boîte qui contient une valeur (l'état)
//  et des méthodes pour la changer. Quand l'état change, tous les
//  widgets qui l'écoutent (et le routeur) sont prévenus automatiquement.
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';

class SessionNotifier extends Notifier<Utilisateur?> {
  /// État de départ : personne n'est connecté.
  @override
  Utilisateur? build() => null;

  /// Appelée après un code OTP correct (écran de connexion).
  void connecter(Utilisateur utilisateur) => state = utilisateur;

  /// Bouton « Se déconnecter ».
  void deconnecter() => state = null;
}

/// Le provider à utiliser dans les écrans :
///   - lire       : `ref.watch(sessionProvider)` → Utilisateur?
///   - modifier   : `ref.read(sessionProvider.notifier).connecter(u)`
final sessionProvider =
    NotifierProvider<SessionNotifier, Utilisateur?>(SessionNotifier.new);
