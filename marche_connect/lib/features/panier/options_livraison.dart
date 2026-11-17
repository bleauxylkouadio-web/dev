// =====================================================================
//  options_livraison.dart : RETRAIT ou LIVRAISON (choix du client)
//
//  Module « Livraison » + exigences :
//  - MAR-02 : heure de retrait choisie
//  - ACH-03 : frais et délai de livraison affichés AVANT validation
//
//  Frais de livraison (cahier des charges : 500 à 1 000 F acceptés) :
//  - même commune que l'étal : 500 F
//  - autre commune           : 1 000 F
//  Le client choisit lui-même sa zone : simple, et aucun GPS requis.
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';

/// Tarifs de livraison en F CFA.
abstract final class TarifsLivraison {
  static const memeCommune = 500;
  static const autreCommune = 1000;

  /// Délai annoncé au client (ACH-03).
  static const delaiAnnonce = '30 à 60 min';
}

/// Les choix d'heure de retrait proposés au client (MAR-02).
enum ChoixHeure { desQuePossible, dansUneHeure, dansDeuxHeures, autre }

class OptionsLivraison {
  const OptionsLivraison({
    this.mode = ModeLivraison.retrait,
    this.choixHeure = ChoixHeure.desQuePossible,
    this.heurePerso,
    this.adresse = '',
    this.memeCommune = true,
  });

  final ModeLivraison mode;

  /// Retrait : puce choisie.
  final ChoixHeure choixHeure;

  /// Retrait : heure précise, seulement si choixHeure == autre.
  final DateTime? heurePerso;

  /// Heure de retrait réelle, calculée AU MOMENT de la commande
  /// (« dans 1 h » = 1 h après l'appui sur Payer). null = dès que possible.
  DateTime? heureRetrait(DateTime maintenant) => switch (choixHeure) {
        ChoixHeure.desQuePossible => null,
        ChoixHeure.dansUneHeure => maintenant.add(const Duration(hours: 1)),
        ChoixHeure.dansDeuxHeures => maintenant.add(const Duration(hours: 2)),
        ChoixHeure.autre => heurePerso,
      };

  /// Livraison : adresse ou point de repère (« derrière la pharmacie… »).
  final String adresse;

  /// Livraison : le client est-il dans la même commune que l'étal ?
  final bool memeCommune;

  /// Frais à ajouter au total (0 pour un retrait).
  int get frais {
    if (mode == ModeLivraison.retrait) return 0;
    return memeCommune ? TarifsLivraison.memeCommune : TarifsLivraison.autreCommune;
  }

  /// Message d'erreur si le choix est incomplet, sinon null.
  String? get erreur {
    if (mode == ModeLivraison.livraison && adresse.trim().length < 5) {
      return 'Indiquez votre adresse ou un point de repère.';
    }
    return null;
  }

  OptionsLivraison copyWith({
    ModeLivraison? mode,
    ChoixHeure? choixHeure,
    DateTime? heurePerso,
    String? adresse,
    bool? memeCommune,
  }) {
    return OptionsLivraison(
      mode: mode ?? this.mode,
      choixHeure: choixHeure ?? this.choixHeure,
      heurePerso: heurePerso ?? this.heurePerso,
      adresse: adresse ?? this.adresse,
      memeCommune: memeCommune ?? this.memeCommune,
    );
  }
}

class OptionsLivraisonNotifier extends Notifier<OptionsLivraison> {
  @override
  OptionsLivraison build() => const OptionsLivraison();

  void choisirMode(ModeLivraison mode) => state = state.copyWith(mode: mode);

  /// Puces « Dès que possible », « Dans 1 h », « Dans 2 h ».
  void choisirHeure(ChoixHeure choix) => state = state.copyWith(choixHeure: choix);

  /// Puce « Autre heure » : heure précise choisie sur l'horloge.
  void choisirHeurePerso(DateTime heure) =>
      state = state.copyWith(choixHeure: ChoixHeure.autre, heurePerso: heure);

  void saisirAdresse(String adresse) => state = state.copyWith(adresse: adresse);

  void choisirZone({required bool memeCommune}) =>
      state = state.copyWith(memeCommune: memeCommune);

  /// Après une commande : on repart des valeurs par défaut.
  void reinitialiser() => state = const OptionsLivraison();
}

/// Partagé entre l'écran Panier (choix) et l'écran Paiement (lecture).
final optionsLivraisonProvider =
    NotifierProvider<OptionsLivraisonNotifier, OptionsLivraison>(OptionsLivraisonNotifier.new);
