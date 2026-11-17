// =====================================================================
//  mode_assiste_screen.dart : MODE ASSISTÉ — commande pour un client
//  SANS SMARTPHONE (parcours QR, diapositive 7, colonne de droite)
//
//    1. Le client demande au commerçant
//    2. Le commerçant saisit la commande   ← cet écran
//    3. Paiement espèces ou code USSD
//    4. Ticket QR imprimé + code à 6 chiffres
//
//  Exigence ACH-06 : achat possible sans smartphone.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../panier/widgets/ligne_panier.dart' show pasPourUnite;
import 'commercant_providers.dart';

class ModeAssisteScreen extends ConsumerStatefulWidget {
  const ModeAssisteScreen({super.key});

  @override
  ConsumerState<ModeAssisteScreen> createState() => _ModeAssisteScreenState();
}

class _ModeAssisteScreenState extends ConsumerState<ModeAssisteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _telephone = TextEditingController();

  /// Quantités choisies : produitId → quantité.
  final Map<String, double> _quantites = {};
  bool _especes = true; // espèces (true) ou Mobile Money par code USSD (false)
  bool _enCours = false;

  @override
  void dispose() {
    _nom.dispose();
    _telephone.dispose();
    super.dispose();
  }

  void _changer(Produit p, double delta) {
    setState(() {
      final q = (_quantites[p.id] ?? 0) + delta;
      if (q <= 0) {
        _quantites.remove(p.id);
      } else {
        _quantites[p.id] = q;
      }
    });
  }

  Future<void> _valider(List<Produit> produits) async {
    if (!_formKey.currentState!.validate()) return;
    if (_quantites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez au moins un produit.')),
      );
      return;
    }
    setState(() => _enCours = true);

    final lignes = [
      for (final p in produits)
        if (_quantites.containsKey(p.id)) LigneCommande.depuisProduit(p, quantite: _quantites[p.id]!),
    ];
    try {
      final commande = await ref.read(commercantActionsProvider).creerCommandeAssistee(
            nomClient: _nom.text.trim().isEmpty ? 'Client au comptoir' : _nom.text.trim(),
            telephoneClient: nettoyerTelephone(_telephone.text),
            lignes: lignes,
            // Espèces = paiement à la remise ; sinon le client paie
            // par code USSD sur son téléphone basique.
            moyenPaiement: _especes ? MoyenPaiement.aLaLivraison : MoyenPaiement.orangeMoney,
          );
      if (!mounted) return;
      // On remplace cet écran par le ticket : à montrer, photographier ou imprimer.
      context.pushReplacement(Routes.ticket(commande.id));
    } catch (_) {
      if (!mounted) return;
      setState(() => _enCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La commande n'a pas pu être créée. Réessayez.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    final produitsAsync = ref.watch(mesProduitsProvider);
    // Seuls les produits disponibles peuvent être vendus.
    final produits = (produitsAsync.value ?? []).where((p) => p.disponible).toList();
    final total = produits.fold<int>(
      0,
      (somme, p) => somme + (p.prix * (_quantites[p.id] ?? 0)).round(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Commande assistée')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.surAccent,
            ),
            onPressed: _enCours ? null : () => _valider(produits),
            child: _enCours
                ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3))
                : Text('Créer le ticket · ${formaterPrix(total)}'),
          ),
        ),
      ),
      body: produitsAsync.isLoading
          ? const Chargement()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.m),
                children: [
                  Text(
                    'Pour un client sans smartphone : saisissez sa commande, '
                    'il repart avec un ticket et un code à 6 chiffres.',
                    style: textes.bodyMedium?.copyWith(color: AppColors.texteSecondaire),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // ---------- Client ----------
                  TextFormField(
                    controller: _nom,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nom du client (facultatif)',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextFormField(
                    controller: _telephone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Téléphone (facultatif)',
                      helperText: 'Pour le prévenir par SMS quand c\'est prêt',
                      prefixIcon: Icon(Icons.phone),
                      prefixText: '+225 ',
                    ),
                    // Facultatif, mais s'il est rempli il doit être valide.
                    validator: (v) => (v == null || v.isEmpty) ? null : validerTelephone(v),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // ---------- Produits ----------
                  Text('Produits', style: textes.titleLarge),
                  const SizedBox(height: AppSpacing.s),
                  if (produits.isEmpty)
                    const EtatVide(titre: 'Aucun produit disponible', icone: Icons.inventory_2),
                  for (final p in produits)
                    _LigneProduit(
                      produit: p,
                      quantite: _quantites[p.id] ?? 0,
                      onMoins: () => _changer(p, -pasPourUnite(p.unite)),
                      onPlus: () => _changer(p, pasPourUnite(p.unite)),
                    ),
                  const SizedBox(height: AppSpacing.l),

                  // ---------- Paiement ----------
                  Text('Paiement', style: textes.titleLarge),
                  const SizedBox(height: AppSpacing.s),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: true, icon: Icon(Icons.payments), label: Text('Espèces')),
                      ButtonSegment(value: false, icon: Icon(Icons.dialpad), label: Text('Code USSD')),
                    ],
                    selected: {_especes},
                    onSelectionChanged: (s) => setState(() => _especes = s.first),
                  ),
                  if (!_especes)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.s),
                      child: Text(
                        'Le client compose le code USSD de son opérateur pour payer.',
                        style: textes.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Ligne « produit · prix · [−] quantité [+] ».
class _LigneProduit extends StatelessWidget {
  const _LigneProduit({
    required this.produit,
    required this.quantite,
    required this.onMoins,
    required this.onPlus,
  });

  final Produit produit;
  final double quantite;
  final VoidCallback onMoins;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final choisi = quantite > 0;
    return Card(
      color: choisi ? AppColors.primaireClair : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(produit.nom, style: Theme.of(context).textTheme.titleMedium),
                  Text(formaterPrixUnitaire(produit.prix, produit.unite)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Moins de ${produit.nom}',
              onPressed: choisi ? onMoins : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            SizedBox(
              width: 64,
              child: Text(
                choisi ? formaterQuantite(quantite, produit.unite) : '0',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Plus de ${produit.nom}',
              onPressed: onPlus,
              icon: const Icon(Icons.add_circle, color: AppColors.primaire),
            ),
          ],
        ),
      ),
    );
  }
}
