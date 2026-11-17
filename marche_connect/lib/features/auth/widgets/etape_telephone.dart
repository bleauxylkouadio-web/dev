// =====================================================================
//  etape_telephone.dart : ÉTAPE 1 — saisie du numéro de téléphone
//
//   ┌───────────────────────────────┐
//   │ 📞 +225 │ 07 01 02 03 04       │
//   └───────────────────────────────┘
//   [        Recevoir le code        ]
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/validators.dart';

/// StatefulWidget car il garde le contrôleur du champ texte et la clé
/// du formulaire (ils doivent survivre aux redessins).
class EtapeTelephone extends StatefulWidget {
  const EtapeTelephone({
    super.key,
    required this.enCours,
    required this.onValider,
    this.numeroInitial = '',
  });

  final bool enCours;

  /// Appelé avec le numéro saisi, seulement s'il est valide.
  final ValueChanged<String> onValider;

  /// Pré-rempli quand on revient avec « Modifier le numéro ».
  final String numeroInitial;

  @override
  State<EtapeTelephone> createState() => EtapeTelephoneState();
}

class EtapeTelephoneState extends State<EtapeTelephone> {
  /// La clé du formulaire permet d'appeler validate() sur tous ses champs.
  final _formKey = GlobalKey<FormState>();

  /// Le contrôleur donne accès au texte tapé (_controleur.text).
  late final TextEditingController _controleur =
      TextEditingController(text: widget.numeroInitial);

  /// Remplit le champ (utilisé par les comptes de démo).
  void remplir(String numero) => _controleur.text = numero;

  @override
  void dispose() {
    // Toujours libérer un contrôleur quand le widget disparaît.
    _controleur.dispose();
    super.dispose();
  }

  void _valider() {
    // validate() appelle le `validator` de chaque champ et affiche
    // les messages d'erreur en rouge. Renvoie vrai si tout est bon.
    if (_formKey.currentState!.validate()) {
      widget.onValider(_controleur.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _controleur,
            enabled: !widget.enCours,
            autofocus: true,
            keyboardType: TextInputType.phone, // clavier numérique
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            style: const TextStyle(fontSize: 22, letterSpacing: 1.5),
            // Filtres de saisie : chiffres uniquement, 10 au maximum.
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: 'Numéro de téléphone',
              hintText: '07 01 02 03 04',
              prefixIcon: Icon(Icons.phone),
              prefixText: '+225 ',
            ),
            validator: validerTelephone, // fonction de l'étape 6
            onFieldSubmitted: (_) => _valider(), // touche « OK » du clavier
          ),
          const SizedBox(height: AppSpacing.l),
          FilledButton(
            // onPressed: null → bouton grisé pendant le chargement.
            onPressed: widget.enCours ? null : _valider,
            child: widget.enCours
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : const Text('Recevoir le code'),
          ),
        ],
      ),
    );
  }
}
