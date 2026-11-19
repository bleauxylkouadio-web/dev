// =====================================================================
//  position_livreur.dart : OÙ EST LE LIVREUR en ce moment ?
//
//  Envoyée par le téléphone du livreur pendant une livraison, lue par
//  le ticket du client (suivi en direct).
//
//  Vie privée : la position n'est partagée QUE pendant l'étape
//  « En livraison » (du moment où le livreur a le colis jusqu'à la
//  remise). Avant et après, le client ne voit rien.
// =====================================================================

class PositionLivreur {
  const PositionLivreur({
    required this.commandeId,
    required this.livreurId,
    required this.latitude,
    required this.longitude,
    required this.misAJourLe,
    this.precisionMetres,
  });

  final String commandeId;
  final String livreurId;

  /// Coordonnées GPS en degrés (Abidjan ≈ 5,35 / -4,00).
  final double latitude;
  final double longitude;

  /// Précision annoncée par le GPS (rayon en mètres), si connue.
  final double? precisionMetres;

  /// Moment de la mesure : sert à afficher « il y a 20 s ».
  final DateTime misAJourLe;

  factory PositionLivreur.fromJson(Map<String, dynamic> json) => PositionLivreur(
        commandeId: json['commandeId'] as String,
        livreurId: json['livreurId'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        precisionMetres: (json['precisionMetres'] as num?)?.toDouble(),
        misAJourLe: DateTime.parse(json['misAJourLe'] as String),
      );

  Map<String, dynamic> toJson() => {
        'commandeId': commandeId,
        'livreurId': livreurId,
        'latitude': latitude,
        'longitude': longitude,
        'precisionMetres': precisionMetres,
        'misAJourLe': misAJourLe.toIso8601String(),
      };
}
