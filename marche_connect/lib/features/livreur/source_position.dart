// =====================================================================
//  source_position.dart : D'OÙ VIENT la position du livreur ?
//
//  Deux sources possibles, même contrat :
//   - SourceGps     : le vrai GPS du téléphone (paquet geolocator).
//                     Demande l'autorisation la première fois.
//   - SourceSimulee : un trajet fictif Adjamé → Cocody, pour la démo
//                     et pour tester sur ordinateur sans GPS.
// =====================================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Une position mesurée.
class Coordonnees {
  const Coordonnees(this.latitude, this.longitude, {this.precisionMetres});

  final double latitude;
  final double longitude;
  final double? precisionMetres;
}

/// Erreur avec un message clair pour le livreur.
class PositionIndisponible implements Exception {
  const PositionIndisponible(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract interface class SourcePosition {
  /// Flux de positions : une nouvelle valeur à chaque déplacement.
  Stream<Coordonnees> suivre();
}

// ---------------------------------------------------------------------
//  VRAI GPS
// ---------------------------------------------------------------------
class SourceGps implements SourcePosition {
  const SourceGps();

  @override
  Stream<Coordonnees> suivre() async* {
    // 1. Le GPS du téléphone est-il allumé ?
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const PositionIndisponible('Activez la localisation (GPS) du téléphone.');
    }
    // 2. L'application a-t-elle le droit de lire la position ?
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission(); // fenêtre du système
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const PositionIndisponible(
        "Autorisez l'accès à la position pour que le client suive sa livraison.",
      );
    }
    // 3. Flux de positions : une nouvelle valeur tous les 15 m parcourus
    //    (économise la batterie et les données, UX-03).
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15),
    ).map((p) => Coordonnees(p.latitude, p.longitude, precisionMetres: p.accuracy));
  }
}

// ---------------------------------------------------------------------
//  TRAJET SIMULÉ (démo)
// ---------------------------------------------------------------------
class SourceSimulee implements SourcePosition {
  const SourceSimulee({this.intervalle = const Duration(seconds: 5)});

  final Duration intervalle;

  // Grand marché d'Adjamé → Cocody Angré (coordonnées approximatives).
  static const _depart = (5.3640, -4.0230);
  static const _arrivee = (5.3970, -3.9880);
  static const _etapes = 40;

  @override
  Stream<Coordonnees> suivre() async* {
    for (var i = 0; i <= _etapes; i++) {
      final t = i / _etapes; // de 0 (départ) à 1 (arrivée)
      yield Coordonnees(
        _depart.$1 + (_arrivee.$1 - _depart.$1) * t,
        _depart.$2 + (_arrivee.$2 - _depart.$2) * t,
        precisionMetres: 10,
      );
      await Future<void>.delayed(intervalle);
    }
  }
}

// ---------------------------------------------------------------------
//  PROVIDERS
// ---------------------------------------------------------------------

/// Interrupteur « Simuler le trajet (démo) » de l'espace livreur.
class SimulationPositionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void basculer() => state = !state;
}

final simulationPositionProvider =
    NotifierProvider<SimulationPositionNotifier, bool>(SimulationPositionNotifier.new);

/// La source utilisée : GPS, ou trajet simulé si l'interrupteur est activé.
/// Les tests remplacent ce provider par une fausse source.
final sourcePositionProvider = Provider<SourcePosition>(
  (ref) => ref.watch(simulationPositionProvider) ? const SourceSimulee() : const SourceGps(),
);
