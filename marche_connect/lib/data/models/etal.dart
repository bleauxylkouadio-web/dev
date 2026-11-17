// =====================================================================
//  etal.dart : la boutique d'un commerçant au marché
//
//  Exigence MAR-05 : étal identifiable (nom, marché, emplacement).
//  Exigence ACH-01 : numéro d'appel, emplacement et avis visibles
//  avant de commander.
// =====================================================================

import 'enums.dart';

class Etal {
  const Etal({
    required this.id,
    required this.nom,
    required this.nomCommercant,
    required this.telephone,
    required this.marche,
    required this.commune,
    required this.emplacement,
    required this.categories,
    this.photoUrl,
    this.noteMoyenne = 0,
    this.nombreAvis = 0,
    this.misEnAvant = false,
    this.ouvert = true,
  });

  /// Identifiant unique. C'est aussi ce qui est encodé dans le QR plastifié
  /// de l'étal : scanner le QR ouvre la vitrine `/etal/<id>`.
  final String id;

  /// Nom de la boutique (ex. "Étal de Mariam").
  final String nom;

  /// Nom du commerçant (ex. "Mariam Koné").
  final String nomCommercant;

  /// Numéro pour appeler le commerçant (ACH-01).
  final String telephone;

  /// Nom du marché (ex. "Grand marché d'Adjamé").
  final String marche;

  /// Commune du marché (filtre de recherche).
  final Commune commune;

  /// Où trouver l'étal dans le marché (ex. "Allée C, étal n° 14").
  final String emplacement;

  /// Ce que vend l'étal (un étal peut avoir plusieurs catégories).
  final List<CategorieProduit> categories;

  /// Photo réelle de l'étal (ACH-01). Vide si pas encore de photo.
  final String? photoUrl;

  /// Note de 0 à 5, moyenne des avis clients. Le `= 0` est la valeur par défaut.
  final double noteMoyenne;

  /// Nombre d'avis reçus.
  final int nombreAvis;

  /// Mise en avant payante (module « Confiance et visibilité », V1.5).
  final bool misEnAvant;

  /// Faux quand le commerçant a fermé son étal pour la journée.
  final bool ouvert;

  /// Texte complet pour retrouver l'étal : "Grand marché d'Adjamé · Allée C, étal n° 14".
  String get adresseComplete => '$marche · $emplacement';

  /// Vrai si l'étal a au moins un avis (sinon on affiche « Nouveau »).
  bool get aDesAvis => nombreAvis > 0;

  Etal copyWith({
    String? nom,
    String? emplacement,
    String? photoUrl,
    double? noteMoyenne,
    int? nombreAvis,
    bool? misEnAvant,
    bool? ouvert,
  }) {
    return Etal(
      id: id,
      nom: nom ?? this.nom,
      nomCommercant: nomCommercant,
      telephone: telephone,
      marche: marche,
      commune: commune,
      emplacement: emplacement ?? this.emplacement,
      categories: categories,
      photoUrl: photoUrl ?? this.photoUrl,
      noteMoyenne: noteMoyenne ?? this.noteMoyenne,
      nombreAvis: nombreAvis ?? this.nombreAvis,
      misEnAvant: misEnAvant ?? this.misEnAvant,
      ouvert: ouvert ?? this.ouvert,
    );
  }

  factory Etal.fromJson(Map<String, dynamic> json) {
    return Etal(
      id: json['id'] as String,
      nom: json['nom'] as String,
      nomCommercant: json['nomCommercant'] as String,
      telephone: json['telephone'] as String,
      marche: json['marche'] as String,
      commune: Commune.values.byName(json['commune'] as String),
      emplacement: json['emplacement'] as String,
      // Liste de textes → liste d'enums.
      categories: (json['categories'] as List)
          .map((c) => CategorieProduit.values.byName(c as String))
          .toList(),
      photoUrl: json['photoUrl'] as String?,
      // « num » accepte 4 comme 4.5 ; on convertit en double.
      noteMoyenne: (json['noteMoyenne'] as num?)?.toDouble() ?? 0,
      nombreAvis: json['nombreAvis'] as int? ?? 0,
      misEnAvant: json['misEnAvant'] as bool? ?? false,
      ouvert: json['ouvert'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'nomCommercant': nomCommercant,
        'telephone': telephone,
        'marche': marche,
        'commune': commune.name,
        'emplacement': emplacement,
        'categories': categories.map((c) => c.name).toList(),
        'photoUrl': photoUrl,
        'noteMoyenne': noteMoyenne,
        'nombreAvis': nombreAvis,
        'misEnAvant': misEnAvant,
        'ouvert': ouvert,
      };
}
