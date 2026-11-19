// =====================================================================
//  etape_inscription.dart : ÉTAPE 3 — créer son compte (nouveau numéro)
//
//   Vous êtes :
//   ┌──────────────────┐ ┌──────────────────┐
//   │ 🛒  Client        │ │ 🛵  Livreur       │   ← deux grandes cartes
//   │ Je commande       │ │ Je livre les      │
//   │ au marché         │ │ commandes         │
//   └──────────────────┘ └──────────────────┘
//   Votre nom        [Ibrahim Koné        ]
//   Votre commune    (Cocody) (Abobo) (Adjamé) (Treichville)
//   [            Créer mon compte            ]
//
//  Après « Créer mon compte », la personne est connectée et le routeur
//  l'emmène sur SON interface : un livreur arrive sur « Mes missions ».
//
//  Commerçants et administrateurs ne s'inscrivent pas ici : leur compte
//  est créé par l'équipe (vérification de l'étal).
// =====================================================================

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/models.dart';

class EtapeInscription extends StatefulWidget {
  const EtapeInscription({
    super.key,
    required this.telephone,
    required this.enCours,
    required this.onValider,
  });

  final String telephone;
  final bool enCours;

  /// Appelé avec le nom, le profil et la commune choisis.
  final Future<bool> Function({required String nom, required Role role, Commune? commune}) onValider;

  @override
  State<EtapeInscription> createState() => _EtapeInscriptionState();
}

class _EtapeInscriptionState extends State<EtapeInscription> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();

  Role _role = Role.client;
  Commune? _commune;

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  void _valider() {
    if (_formKey.currentState!.validate()) {
      widget.onValider(nom: _nom.text.trim(), role: _role, commune: _commune);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    final livreur = _role == Role.livreur;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Numéro vérifié : ${formaterTelephone(widget.telephone)}',
            style: textes.bodyMedium?.copyWith(color: AppColors.succes, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.l),

          // ---------- Profil ----------
          Text('Vous êtes :', style: textes.titleMedium),
          const SizedBox(height: AppSpacing.s),
          Row(
            children: [
              Expanded(
                child: _CarteProfil(
                  icone: Icons.shopping_basket,
                  titre: 'Client',
                  detail: 'Je commande au marché',
                  choisi: !livreur,
                  onTap: () => setState(() => _role = Role.client),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _CarteProfil(
                  icone: Icons.delivery_dining,
                  titre: 'Livreur',
                  detail: 'Je livre les commandes',
                  choisi: livreur,
                  onTap: () => setState(() => _role = Role.livreur),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),

          // ---------- Nom ----------
          TextFormField(
            controller: _nom,
            enabled: !widget.enCours,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              labelText: 'Votre nom',
              hintText: 'Ex. : Ibrahim Koné',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (v) => validerObligatoire(v, champ: 'votre nom'),
          ),
          const SizedBox(height: AppSpacing.l),

          // ---------- Commune ----------
          Text(
            livreur ? 'Votre commune de travail' : 'Votre commune (facultatif)',
            style: textes.titleMedium,
          ),
          const SizedBox(height: AppSpacing.s),
          // FormField : permet de VALIDER un choix de puces comme un champ texte.
          FormField<Commune>(
            initialValue: _commune,
            // Pour un livreur, la commune est obligatoire : elle sert à lui
            // proposer les livraisons proches.
            validator: (_) => livreur && _commune == null ? 'Choisissez votre commune' : null,
            builder: (champ) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    for (final c in Commune.values)
                      ChoiceChip(
                        label: Text(c.libelle),
                        selected: _commune == c,
                        onSelected: (_) {
                          setState(() => _commune = c);
                          champ.didChange(c);
                        },
                      ),
                  ],
                ),
                if (champ.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(champ.errorText!, style: const TextStyle(color: AppColors.erreur)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          FilledButton(
            onPressed: widget.enCours ? null : _valider,
            child: widget.enCours
                ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3))
                : Text(livreur ? 'Créer mon compte livreur' : 'Créer mon compte'),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Vous êtes commerçant ? Contactez l\'équipe MARCHÉ_CONNECT : '
            'nous créons votre étal avec vous.',
            style: textes.bodySmall?.copyWith(color: AppColors.texteSecondaire),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Grande carte sélectionnable (profil Client ou Livreur).
class _CarteProfil extends StatelessWidget {
  const _CarteProfil({
    required this.icone,
    required this.titre,
    required this.detail,
    required this.choisi,
    required this.onTap,
  });

  final IconData icone;
  final String titre;
  final String detail;
  final bool choisi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: choisi,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.moyen),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: choisi ? AppColors.primaireClair : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.moyen),
            border: Border.all(
              color: choisi ? AppColors.primaire : AppColors.bordure,
              width: choisi ? 3 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icone, size: 40, color: AppColors.primaire),
              const SizedBox(height: AppSpacing.xs),
              Text(titre, style: Theme.of(context).textTheme.titleMedium),
              Text(detail, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
