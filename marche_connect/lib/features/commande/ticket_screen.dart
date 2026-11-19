// =====================================================================
//  ticket_screen.dart : le TICKET QR d'une commande
//
//  Maquette « Ticket QR » (diapositive 14) :
//    Ticket de commande
//    N° 482 913
//    [   QR CODE   ]
//    Prête · à remettre au livreur
//    Scanner pour valider
//
//  Parcours QR (diapositive 7) : le livreur scanne ce QR pour valider
//  la remise. Pour un client SANS smartphone, le ticket est imprimé et
//  le code à 6 chiffres sert de secours si le QR est abîmé.
// =====================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../panier/widgets/recapitulatif.dart';
import 'commande_providers.dart';
import 'widgets/carte_livreur.dart';
import 'widgets/signaler_probleme.dart';
import 'widgets/suivi_commande.dart';

class TicketScreen extends ConsumerStatefulWidget {
  const TicketScreen({super.key, required this.commandeId});

  /// Identifiant lu dans l'adresse /ticket/:id.
  final String commandeId;

  /// Fréquence de mise à jour automatique du ticket et de la carte.
  static const actualisation = Duration(seconds: 10);

  @override
  ConsumerState<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends ConsumerState<TicketScreen> {
  Timer? _minuteur;

  String get commandeId => widget.commandeId;

  @override
  void initState() {
    super.initState();
    // Toutes les 10 s, tant que la commande n'est pas terminée :
    //  - on recharge le statut → le client voit « En route » dès que le
    //    livreur a récupéré le colis, SANS toucher l'écran ;
    //  - pendant la livraison, on recharge aussi la position du livreur.
    // (Avec la vraie API, une connexion WebSocket remplacera ce minuteur.)
    _minuteur = Timer.periodic(TicketScreen.actualisation, (_) {
      final c = ref.read(commandeProvider(commandeId)).value;
      if (c == null || c.statut.estTerminee) return;
      ref.invalidate(commandeProvider(commandeId));
      if (c.statut == StatutCommande.enLivraison) {
        ref.invalidate(positionLivreurProvider(commandeId));
      }
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commande = ref.watch(commandeProvider(commandeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket de commande'),
        // Après un paiement, il n'y a pas de page précédente (context.go) :
        // la flèche ramène alors aux commandes.
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.mesCommandes),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser le statut',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(commandeProvider(commandeId)),
          ),
        ],
      ),
      body: commande.when(
        loading: () => const Chargement(message: 'Chargement du ticket…'),
        error: (_, _) => MessageErreur(
          onReessayer: () => ref.invalidate(commandeProvider(commandeId)),
        ),
        data: (c) => c == null
            ? EtatVide(
                titre: 'Commande introuvable',
                message: 'Vérifiez le numéro du ticket.',
                icone: Icons.receipt_long,
                libelleAction: 'Mes commandes',
                onAction: () => context.go(Routes.mesCommandes),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(commandeProvider(commandeId).future),
                child: _ContenuTicket(commande: c),
              ),
      ),
    );
  }
}

class _ContenuTicket extends StatelessWidget {
  const _ContenuTicket({required this.commande});

  final Commande commande;

  /// Phrase sous le QR, selon le statut (maquette : « Prête · à remettre au livreur »).
  String get _consigne => switch (commande.statut) {
        StatutCommande.enAttente => 'En attente de confirmation du commerçant',
        StatutCommande.confirmee => 'Confirmée · en préparation',
        StatutCommande.prete => commande.modeLivraison == ModeLivraison.livraison
            ? 'Prête · à remettre au livreur'
            : "Prête · montrez ce ticket à l'étal",
        StatutCommande.enLivraison => 'En route · montrez ce QR au livreur',
        StatutCommande.livree => 'Remise effectuée. Merci !',
        StatutCommande.annulee => 'Commande annulée',
      };

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    final c = commande;
    final termine = c.statut.estTerminee;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.m),
      children: [
        // =============== SUIVI DU LIVREUR EN DIRECT ===============
        // Dès que le livreur a le colis (« En livraison ») et jusqu'à la
        // remise : c'est l'information la plus attendue, on la met en haut.
        if (c.statut == StatutCommande.enLivraison) ...[
          CarteLivreur(commande: c),
          const SizedBox(height: AppSpacing.m),
        ],

        // =============== LE TICKET ===============
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              children: [
                Text(c.nomEtal, style: textes.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                Text('N° ${c.numeroFormate}', style: textes.headlineSmall),
                const SizedBox(height: AppSpacing.m),

                // ---------- Le QR code ----------
                // Opacity : un ticket terminé est grisé (le QR ne sert plus).
                Opacity(
                  opacity: termine ? 0.25 : 1,
                  child: Container(
                    // Fond blanc + marge blanche (« zone calme ») : indispensable
                    // pour que les scanners lisent le QR, même en plein soleil.
                    color: Colors.white,
                    padding: const EdgeInsets.all(AppSpacing.s),
                    child: QrImageView(
                      data: c.contenuQr, // « MC:CMD:c-1:482913 »
                      size: 220,
                      backgroundColor: Colors.white,
                      // Correction d'erreur élevée : le QR reste lisible
                      // même froissé ou taché (ticket imprimé).
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                      semanticsLabel: 'QR code de la commande ${c.numeroFormate}',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                BadgeStatutCommande(statut: c.statut),
                const SizedBox(height: AppSpacing.s),
                Text(_consigne, style: textes.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.m),

                // ---------- Code de secours ----------
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
                  decoration: BoxDecoration(
                    color: AppColors.fond,
                    borderRadius: BorderRadius.circular(AppRadius.petit),
                  ),
                  child: Text(
                    'Code de secours : ${c.numeroFormate}',
                    style: textes.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),

        // =============== MAR-01 : confirmation sous 10 min ===============
        if (c.statut == StatutCommande.enAttente) ...[
          _BandeauAttente(commande: c),
          const SizedBox(height: AppSpacing.m),
        ],

        // =============== SUIVI ===============
        Text('Suivi', style: textes.titleLarge),
        const SizedBox(height: AppSpacing.s),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: SuiviCommande(commande: c),
          ),
        ),
        const SizedBox(height: AppSpacing.m),

        // =============== DÉTAILS ===============
        Text('Détails', style: textes.titleLarge),
        const SizedBox(height: AppSpacing.s),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final l in c.lignes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${l.nomProduit} × ${formaterQuantite(l.quantite, l.unite)}'),
                        ),
                        Text(formaterPrix(l.total)),
                      ],
                    ),
                  ),
                const Divider(height: AppSpacing.l),
                _Info(
                  icone: c.modeLivraison == ModeLivraison.livraison
                      ? Icons.delivery_dining
                      : Icons.storefront,
                  texte: c.modeLivraison == ModeLivraison.livraison
                      ? 'Livraison : ${c.adresseLivraison ?? ''}'
                      : c.heureRetrait == null
                          ? "Retrait à l'étal dès que possible"
                          : "Retrait à l'étal vers ${formaterHeure(c.heureRetrait!)}",
                ),
                _Info(
                  icone: Icons.payments,
                  texte: '${c.moyenPaiement.libelle} · ${c.statutPaiement.libelle}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Recapitulatif(
          sousTotal: c.sousTotal,
          fraisLivraison: c.fraisLivraison,
          avecLivraison: c.modeLivraison == ModeLivraison.livraison,
        ),
        const SizedBox(height: AppSpacing.l),

        // =============== ACH-04 : signaler un problème ===============
        if (c.statut == StatutCommande.livree) ...[
          SignalerProbleme(commande: c),
          const SizedBox(height: AppSpacing.l),
        ],
      ],
    );
  }
}

/// Bandeau MAR-01 : délai de confirmation, ou retard du commerçant.
class _BandeauAttente extends StatelessWidget {
  const _BandeauAttente({required this.commande});

  final Commande commande;

  @override
  Widget build(BuildContext context) {
    final enRetard = commande.estEnRetardDeConfirmation(DateTime.now());
    final texte = enRetard
        ? "Le commerçant n'a pas encore confirmé. Vous pouvez l'appeler depuis sa vitrine."
        : 'Le commerçant confirme avant ${formaterHeure(commande.limiteConfirmation)}.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.attenteClair,
        borderRadius: BorderRadius.circular(AppRadius.moyen),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top, color: AppColors.attente),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(texte, style: const TextStyle(color: AppColors.attente, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Ligne « icône + texte » des détails.
class _Info extends StatelessWidget {
  const _Info({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: AppColors.primaire),
          const SizedBox(width: AppSpacing.s),
          Expanded(child: Text(texte)),
        ],
      ),
    );
  }
}
