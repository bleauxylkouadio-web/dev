// =====================================================================
//  etape_code.dart : ÉTAPE 2 — saisie du code OTP à 6 chiffres
//
//   Code envoyé au 07 01 02 03 04   (Modifier)
//   ┌───────────────────────────────┐
//   │        1  2  3  4  5  6       │
//   └───────────────────────────────┘
//   [            Valider           ]
//   Renvoyer le code dans 30 s
//
//  Dès que 6 chiffres sont tapés, la vérification part toute seule :
//  un appui de moins (UX-01, rapidité).
// =====================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';

class EtapeCode extends StatefulWidget {
  const EtapeCode({
    super.key,
    required this.telephone,
    required this.enCours,
    required this.onValider,
    required this.onRenvoyer,
    required this.onModifierNumero,
  });

  final String telephone;
  final bool enCours;
  final ValueChanged<String> onValider;
  final VoidCallback onRenvoyer;
  final VoidCallback onModifierNumero;

  @override
  State<EtapeCode> createState() => _EtapeCodeState();
}

class _EtapeCodeState extends State<EtapeCode> {
  /// Délai avant de pouvoir redemander un code (évite les SMS en rafale).
  static const _delaiRenvoi = 30;

  final _formKey = GlobalKey<FormState>();
  final _controleur = TextEditingController();

  Timer? _minuteur;
  int _secondesRestantes = _delaiRenvoi;

  @override
  void initState() {
    super.initState();
    _demarrerMinuteur();
  }

  /// Compte à rebours : chaque seconde, on enlève 1 et on redessine.
  void _demarrerMinuteur() {
    _minuteur?.cancel();
    setState(() => _secondesRestantes = _delaiRenvoi);
    _minuteur = Timer.periodic(const Duration(seconds: 1), (minuteur) {
      if (_secondesRestantes <= 1) minuteur.cancel();
      setState(() => _secondesRestantes--);
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel(); // sinon le minuteur continue après la fermeture
    _controleur.dispose();
    super.dispose();
  }

  void _valider() {
    if (_formKey.currentState!.validate()) {
      widget.onValider(_controleur.text);
    }
  }

  void _renvoyer() {
    _controleur.clear();
    widget.onRenvoyer();
    _demarrerMinuteur();
  }

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    final peutRenvoyer = _secondesRestantes <= 0 && !widget.enCours;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------- Rappel du numéro + lien pour le modifier ----------
          Text(
            'Code envoyé par SMS au',
            style: textes.bodyMedium?.copyWith(color: AppColors.texteSecondaire),
            textAlign: TextAlign.center,
          ),
          Text(
            formaterTelephone(widget.telephone),
            style: textes.titleLarge,
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: widget.enCours ? null : widget.onModifierNumero,
            child: const Text('Modifier le numéro'),
          ),
          const SizedBox(height: AppSpacing.m),

          // ---------- Champ du code ----------
          TextFormField(
            controller: _controleur,
            enabled: !widget.enCours,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            // Sur Android/iOS, propose le code reçu par SMS au-dessus du clavier.
            autofillHints: const [AutofillHints.oneTimeCode],
            style: const TextStyle(fontSize: 32, letterSpacing: 12, fontWeight: FontWeight.w700),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(hintText: '••••••', counterText: ''),
            validator: validerCodeOtp,
            // Validation automatique au 6e chiffre.
            onChanged: (texte) {
              if (texte.length == 6) _valider();
            },
          ),
          const SizedBox(height: AppSpacing.l),
          FilledButton(
            onPressed: widget.enCours ? null : _valider,
            child: widget.enCours
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : const Text('Valider'),
          ),
          const SizedBox(height: AppSpacing.s),

          // ---------- Renvoyer le code ----------
          TextButton(
            onPressed: peutRenvoyer ? _renvoyer : null,
            child: Text(
              peutRenvoyer
                  ? 'Renvoyer le code'
                  : 'Renvoyer le code dans $_secondesRestantes s',
            ),
          ),
        ],
      ),
    );
  }
}
