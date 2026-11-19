// =====================================================================
//  partage_position.dart : PARTAGE DE LA POSITION du livreur
//
//  Démarre AUTOMATIQUEMENT dès qu'une mission passe « En livraison »
//  (le livreur a touché « J'ai récupéré la commande »), et s'arrête
//  tout seul quand plus aucune livraison n'est en cours (remise validée).
//
//  Affiche un bandeau en haut de l'écran des missions :
//    📍 Position partagée avec 1 client · envoyée à l'instant
//  ou, en cas de problème :
//    ⚠ Activez la localisation (GPS) du téléphone.   [Réessayer]
//
//  Envoi au plus toutes les 10 s : assez pour un suivi fluide, sans
//  consommer trop de données mobiles (UX-03).
// =====================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';
import '../auth/session_provider.dart';
import 'livreur_providers.dart';
import 'source_position.dart';

class PartagePosition extends ConsumerStatefulWidget {
  const PartagePosition({super.key});

  /// Délai minimum entre deux envois au serveur.
  static const intervalleEnvoi = Duration(seconds: 10);

  @override
  ConsumerState<PartagePosition> createState() => _PartagePositionState();
}

class _PartagePositionState extends ConsumerState<PartagePosition> {
  /// Abonnement au flux GPS (null = partage arrêté).
  StreamSubscription<Coordonnees>? _abonnement;

  /// Commandes « En livraison » dont on partage la position.
  List<Commande> _enRoute = const [];

  DateTime? _dernierEnvoi;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    // Après le premier affichage : démarrer si une livraison est déjà en cours.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _synchroniser(ref.read(missionsProvider).value);
    });
  }

  @override
  void dispose() {
    _abonnement?.cancel(); // on quitte l'écran : on arrête le GPS
    super.dispose();
  }

  /// Démarre ou arrête le partage selon les missions en cours.
  void _synchroniser(List<Commande>? missions) {
    if (missions == null) return;
    final enRoute = missions.where((c) => c.statut == StatutCommande.enLivraison).toList();
    setState(() => _enRoute = enRoute);

    if (enRoute.isEmpty) {
      _arreter();
    } else if (_abonnement == null) {
      _demarrer();
    }
  }

  void _demarrer() {
    setState(() => _erreur = null);
    _abonnement = ref.read(sourcePositionProvider).suivre().listen(
          _surPosition,
          onError: (Object e) {
            _arreter();
            if (mounted) {
              setState(() => _erreur = e is PositionIndisponible ? e.message : 'Position indisponible.');
            }
          },
        );
  }

  void _arreter() {
    _abonnement?.cancel();
    _abonnement = null;
    _dernierEnvoi = null;
  }

  /// Nouvelle position mesurée : on l'envoie (au plus toutes les 10 s).
  Future<void> _surPosition(Coordonnees c) async {
    final maintenant = DateTime.now();
    if (_dernierEnvoi != null && maintenant.difference(_dernierEnvoi!) < PartagePosition.intervalleEnvoi) {
      return;
    }
    final livreur = ref.read(sessionProvider);
    if (livreur == null) return;

    final suivi = ref.read(suiviRepositoryProvider);
    try {
      // Un livreur peut transporter plusieurs commandes à la fois.
      for (final commande in _enRoute) {
        await suivi.envoyerPosition(PositionLivreur(
          commandeId: commande.id,
          livreurId: livreur.id,
          latitude: c.latitude,
          longitude: c.longitude,
          precisionMetres: c.precisionMetres,
          misAJourLe: maintenant,
        ));
      }
      if (mounted) {
        setState(() {
          _dernierEnvoi = maintenant;
          _erreur = null;
        });
      }
    } catch (_) {
      // Réseau coupé : on réessaiera à la prochaine position.
      if (mounted) setState(() => _erreur = "Envoi de la position impossible (réseau). Nouvel essai bientôt.");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chaque changement des missions (récupérée, remise…) relance la synchro.
    ref.listen(missionsProvider, (_, suivant) => _synchroniser(suivant.value));
    // Changement de source (interrupteur « Simuler ») : on redémarre.
    ref.listen(sourcePositionProvider, (_, _) {
      _arreter();
      if (_enRoute.isNotEmpty) _demarrer();
    });

    if (_enRoute.isEmpty) return const SizedBox.shrink();

    final n = _enRoute.length;
    final probleme = _erreur != null;

    return Container(
      width: double.infinity,
      color: probleme ? AppColors.erreurClair : AppColors.succesClair,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                probleme ? Icons.location_off : Icons.my_location,
                color: probleme ? AppColors.erreur : AppColors.succes,
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  probleme
                      ? _erreur!
                      : 'Position partagée avec $n client${n > 1 ? 's' : ''}'
                          '${_dernierEnvoi == null ? '…' : ' · envoyée ${formaterDepuis(_dernierEnvoi!)}'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: probleme ? AppColors.erreur : AppColors.succes,
                  ),
                ),
              ),
            ],
          ),
          if (probleme)
            Wrap(
              spacing: AppSpacing.s,
              children: [
                TextButton(
                  onPressed: () {
                    _arreter();
                    _demarrer();
                  },
                  child: const Text('Réessayer'),
                ),
                // Développement : trajet simulé si pas de GPS (ordinateur).
                if (kDebugMode)
                  TextButton(
                    onPressed: () => ref.read(simulationPositionProvider.notifier).basculer(),
                    child: Text(ref.watch(simulationPositionProvider) ? 'Utiliser le GPS' : 'Simuler le trajet (démo)'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
