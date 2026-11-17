// =====================================================================
//  paiement_controller.dart : la LOGIQUE du paiement
//
//  payer() :
//   1. lit le panier, les options de livraison et l'utilisateur connecté ;
//   2. crée la commande (repository) ;
//   3. vide le panier et remet les options à zéro ;
//   4. renvoie la commande créée → l'écran ouvre le ticket.
//
//  En démo, le paiement Mobile Money réussit toujours (mock).
//  Avec la vraie API, l'agrégateur de paiement agréé enverra une
//  demande de validation sur le téléphone du client (ACH-05 : aucune
//  donnée de carte ni code secret ne passe par l'application).
// =====================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';
import '../auth/session_provider.dart';
import '../panier/options_livraison.dart';
import '../panier/panier_provider.dart';

class PaiementState {
  const PaiementState({this.moyen = MoyenPaiement.wave, this.enCours = false, this.erreur});

  /// Wave par défaut : 16 clients sur 18 l'utilisent (enquête terrain).
  final MoyenPaiement moyen;
  final bool enCours;
  final String? erreur;
}

class PaiementController extends Notifier<PaiementState> {
  @override
  PaiementState build() => const PaiementState();

  void choisirMoyen(MoyenPaiement moyen) => state = PaiementState(moyen: moyen);

  /// Renvoie la commande créée, ou null en cas d'échec (erreur dans l'état).
  Future<Commande?> payer() async {
    final panier = ref.read(panierProvider);
    final options = ref.read(optionsLivraisonProvider);
    final client = ref.read(sessionProvider);

    // Sécurités (normalement impossibles grâce à l'écran et au routeur).
    if (panier.estVide || client == null || options.erreur != null) {
      state = PaiementState(moyen: state.moyen, erreur: 'Commande incomplète.');
      return null;
    }

    state = PaiementState(moyen: state.moyen, enCours: true);
    try {
      final commande = await ref.read(commandeRepositoryProvider).creerCommande(
            etalId: panier.etalId!,
            clientId: client.id,
            nomClient: client.nom,
            telephoneClient: client.telephone,
            lignes: panier.lignes,
            modeLivraison: options.mode,
            fraisLivraison: options.frais,
            adresseLivraison:
                options.mode == ModeLivraison.livraison ? options.adresse.trim() : null,
            heureRetrait: options.mode == ModeLivraison.retrait
                ? options.heureRetrait(DateTime.now())
                : null,
            moyenPaiement: state.moyen,
          );

      // Commande créée : on repart de zéro pour la prochaine.
      ref.read(panierProvider.notifier).vider();
      ref.read(optionsLivraisonProvider.notifier).reinitialiser();
      state = PaiementState(moyen: state.moyen);
      return commande;
    } catch (_) {
      // Le panier est CONSERVÉ : le client peut réessayer (MAR-04).
      state = PaiementState(
        moyen: state.moyen,
        erreur: 'Le paiement n\'a pas abouti. Votre panier est conservé, réessayez.',
      );
      return null;
    }
  }
}

final paiementControllerProvider =
    NotifierProvider.autoDispose<PaiementController, PaiementState>(PaiementController.new);
