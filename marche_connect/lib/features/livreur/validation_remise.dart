// =====================================================================
//  validation_remise.dart : valider une remise et AFFICHER LE RÉSULTAT
//
//  Utilisé par :
//   - l'écran de scan (texte lu dans le QR) ;
//   - le bouton « Saisir le code » (ticket abîmé, client sans smartphone).
//
//  Résultat, en très gros (le livreur est dehors, souvent pressé) :
//   ✔ vert  : « Commande 482 913 remise » (+ montant à encaisser si besoin)
//   ✖ rouge : « Code non reconnu »
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/models.dart';
import 'livreur_providers.dart';

/// Valide puis affiche le résultat. Renvoie vrai si la remise est validée.
Future<bool> validerEtAfficher(BuildContext context, WidgetRef ref, String qrOuCode) async {
  Commande? commande;
  try {
    commande = await ref.read(livreurActionsProvider).validerRemise(qrOuCode);
  } catch (_) {
    commande = null;
  }
  if (!context.mounted) return commande != null;

  // Petite vibration : confirmation sans regarder l'écran.
  HapticFeedback.mediumImpact();

  await showDialog<void>(
    context: context,
    builder: (context) => _DialogueResultat(commande: commande),
  );
  return commande != null;
}

/// Ouvre la saisie du code à 6 chiffres puis valide.
Future<bool> saisirCodeEtValider(BuildContext context, WidgetRef ref) async {
  final code = await showDialog<String>(
    context: context,
    builder: (context) => const _DialogueCode(),
  );
  if (code == null || !context.mounted) return false;
  return validerEtAfficher(context, ref, code);
}

// ---------------------------------------------------------------------

class _DialogueResultat extends StatelessWidget {
  const _DialogueResultat({required this.commande});

  final Commande? commande;

  @override
  Widget build(BuildContext context) {
    final ok = commande != null;
    final textes = Theme.of(context).textTheme;
    // Paiement à la livraison : le livreur doit encaisser le montant.
    final aEncaisser = ok && commande!.moyenPaiement == MoyenPaiement.aLaLivraison;

    return AlertDialog(
      backgroundColor: ok ? AppColors.succesClair : AppColors.erreurClair,
      icon: Icon(
        ok ? Icons.check_circle : Icons.cancel,
        size: 72,
        color: ok ? AppColors.succes : AppColors.erreur,
      ),
      title: Text(ok ? 'Commande remise' : 'Code non reconnu', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ok) ...[
            Text('N° ${commande!.numeroFormate}', style: textes.headlineSmall),
            Text(commande!.nomClient, style: textes.titleMedium),
            if (aEncaisser) ...[
              const SizedBox(height: AppSpacing.m),
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.accentClair,
                  borderRadius: BorderRadius.circular(AppRadius.moyen),
                ),
                child: Text(
                  'À encaisser : ${formaterPrix(commande!.total)}',
                  style: textes.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ] else
            const Text(
              "Ce ticket n'existe pas, ou la commande n'est pas prête.\n"
              'Vérifiez le numéro avec le client.',
              textAlign: TextAlign.center,
            ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _DialogueCode extends StatefulWidget {
  const _DialogueCode();

  @override
  State<_DialogueCode> createState() => _DialogueCodeState();
}

class _DialogueCodeState extends State<_DialogueCode> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _valider() {
    if (_formKey.currentState!.validate()) Navigator.pop(context, _code.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Code du ticket'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, letterSpacing: 8, fontWeight: FontWeight.w700),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: const InputDecoration(hintText: '482913'),
          // Même règle que le code OTP : exactement 6 chiffres.
          validator: (v) => validerCodeOtp(v) == null ? null : 'Le code a 6 chiffres',
          onFieldSubmitted: (_) => _valider(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(onPressed: _valider, child: const Text('Valider')),
      ],
    );
  }
}
