// =====================================================================
//  utils_test.dart : tests des formats et des validations
// =====================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:marche_connect/core/utils/formatters.dart';
import 'package:marche_connect/core/utils/validators.dart';
import 'package:marche_connect/data/models/models.dart';

/// Remplace les espaces insécables par des espaces normaux, pour écrire
/// les résultats attendus simplement.
String s(String texte) => texte.replaceAll(' ', ' ');

void main() {
  group('Prix', () {
    test('Séparateur de milliers et « F »', () {
      expect(s(formaterPrix(500)), '500 F');
      expect(s(formaterPrix(1500)), '1 500 F');
      expect(s(formaterPrix(1500000)), '1 500 000 F');
      expect(s(formaterPrix(0)), '0 F');
    });

    test('Prix avec unité', () {
      expect(s(formaterPrixUnitaire(500, UniteVente.kg)), '500 F / kg');
    });
  });

  group('Quantités (MAR-02)', () {
    test('Virgule à la française et pluriel', () {
      expect(s(formaterQuantite(1.5, UniteVente.kg)), '1,5 kg');
      expect(s(formaterQuantite(2, UniteVente.kg)), '2 kg');
      expect(s(formaterQuantite(3, UniteVente.lot)), '3 lots');
      expect(s(formaterQuantite(1, UniteVente.piece)), '1 pièce');
    });
  });

  group('Dates (UX-05)', () {
    final now = DateTime(2026, 11, 17, 14, 0);

    test('Âge du prix', () {
      expect(formaterDepuis(now, maintenant: now), "à l'instant");
      expect(formaterDepuis(DateTime(2026, 11, 17, 13, 48), maintenant: now), 'il y a 12 min');
      expect(formaterDepuis(DateTime(2026, 11, 17, 11, 0), maintenant: now), 'il y a 3 h');
      expect(formaterDepuis(DateTime(2026, 11, 16, 18, 30), maintenant: now), 'hier à 18 h 30');
      expect(formaterDepuis(DateTime(2026, 11, 14, 9, 0), maintenant: now), 'le 14 nov.');
    });

    test('Heure', () {
      expect(formaterHeure(DateTime(2026, 1, 1, 9, 5)), '9 h 05');
    });
  });

  group('Téléphone', () {
    test('Formatage et nettoyage de « +225 »', () {
      expect(formaterTelephone('0701020304'), '07 01 02 03 04');
      expect(nettoyerTelephone('+225 07 01 02 03 04'), '0701020304');
    });

    test('Validation', () {
      expect(validerTelephone('07 01 02 03 04'), isNull);
      expect(validerTelephone('+225 0505050505'), isNull);
      expect(validerTelephone(''), isNotNull);
      expect(validerTelephone('070102'), 'Le numéro doit avoir 10 chiffres');
      expect(validerTelephone('0901020304'), 'Le numéro doit commencer par 01, 05 ou 07');
    });
  });

  group('Autres validations', () {
    test('Code OTP', () {
      expect(validerCodeOtp('123456'), isNull);
      expect(validerCodeOtp('12345'), isNotNull);
    });

    test('Prix', () {
      expect(validerPrix('1 500'), isNull);
      expect(validerPrix('12,5'), 'Chiffres uniquement, sans virgule');
      expect(validerPrix('10'), 'Le prix minimum est 25 F');
    });
  });
}
