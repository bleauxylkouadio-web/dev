// =====================================================================
//  utilisateur.dart : une personne qui a un compte
//
//  Module « Compte » : inscription par numéro de téléphone + code OTP.
//  Pas d'e-mail ni de mot de passe : le téléphone suffit.
// =====================================================================

import 'enums.dart';

class Utilisateur {
  /// Constructeur. `required` = paramètre obligatoire.
  /// `const` permet à Flutter de réutiliser l'objet en mémoire.
  const Utilisateur({
    required this.id,
    required this.telephone,
    required this.nom,
    required this.role,
    this.commune,
    this.etalId,
  });

  /// Identifiant unique, attribué par le serveur (ex. "u-001").
  final String id;

  /// Numéro ivoirien à 10 chiffres, sans indicatif (ex. "0701020304").
  final String telephone;

  /// Nom affiché (ex. "Mariam Koné").
  final String nom;

  /// Client, commerçant, livreur ou administrateur.
  final Role role;

  /// Commune de l'utilisateur, utile pour proposer les étals proches.
  /// Le `?` veut dire « peut être vide (null) ».
  final Commune? commune;

  /// Pour un commerçant : l'identifiant de SON étal. Vide pour les autres rôles.
  final String? etalId;

  /// Numéro formaté pour l'affichage : "07 01 02 03 04".
  String get telephoneFormate {
    final buffer = StringBuffer();
    for (var i = 0; i < telephone.length; i++) {
      if (i > 0 && i.isEven) buffer.write(' ');
      buffer.write(telephone[i]);
    }
    return buffer.toString();
  }

  // -------------------------------------------------------------------
  //  copyWith : crée une COPIE en changeant seulement certains champs.
  //  Nos objets sont « immuables » (final partout) : on ne les modifie
  //  jamais, on les remplace par une copie. Ça évite beaucoup de bugs.
  // -------------------------------------------------------------------
  Utilisateur copyWith({
    String? nom,
    Commune? commune,
  }) {
    return Utilisateur(
      id: id,
      telephone: telephone,
      nom: nom ?? this.nom, // « ?? » = si nom est null, garder l'ancien
      role: role,
      commune: commune ?? this.commune,
      etalId: etalId,
    );
  }

  // -------------------------------------------------------------------
  //  JSON : format d'échange avec l'API et de stockage hors ligne.
  //  fromJson = lire un objet reçu ; toJson = préparer un objet à envoyer.
  // -------------------------------------------------------------------
  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['id'] as String,
      telephone: json['telephone'] as String,
      nom: json['nom'] as String,
      role: Role.values.byName(json['role'] as String),
      commune: json['commune'] == null
          ? null
          : Commune.values.byName(json['commune'] as String),
      etalId: json['etalId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'telephone': telephone,
        'nom': nom,
        'role': role.name,
        'commune': commune?.name,
        'etalId': etalId,
      };
}
