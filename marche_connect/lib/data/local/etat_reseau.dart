// =====================================================================
//  etat_reseau.dart : sommes-nous HORS LIGNE en ce moment ?
//
//  Mis à jour par les repositories en cache (repositories_en_cache.dart) :
//   - un appel réseau réussit  → en ligne ;
//   - un appel échoue mais le cache répond → hors ligne, avec la date
//     des données affichées.
//  Les écrans affichent alors un bandeau « Hors ligne ».
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

class EtatReseau {
  const EtatReseau({this.horsLigne = false, this.donneesDu});

  final bool horsLigne;

  /// Date d'enregistrement des données affichées hors ligne.
  final DateTime? donneesDu;
}

class EtatReseauNotifier extends Notifier<EtatReseau> {
  @override
  EtatReseau build() => const EtatReseau();

  void enLigne() {
    if (state.horsLigne) state = const EtatReseau();
  }

  void horsLigne(DateTime? donneesDu) => state = EtatReseau(horsLigne: true, donneesDu: donneesDu);
}

final etatReseauProvider = NotifierProvider<EtatReseauNotifier, EtatReseau>(EtatReseauNotifier.new);
