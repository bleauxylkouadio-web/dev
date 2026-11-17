// =====================================================================
//  mes_produits_onglet.dart : MES PRODUITS
//
//  - Interrupteur Disponible/Épuisé en un geste (UX-04).
//  - Appui sur un produit → changer son prix (MAR-03).
//  - Bouton flottant « Photo et prix » → nouveau produit.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../commercant_providers.dart';

class MesProduitsOnglet extends ConsumerWidget {
  const MesProduitsOnglet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produits = ref.watch(mesProduitsProvider);

    return produits.when(
      loading: () => const Chargement(message: 'Chargement des produits…'),
      error: (_, _) => MessageErreur(onReessayer: () => ref.invalidate(mesProduitsProvider)),
      data: (liste) {
        if (liste.isEmpty) {
          return const EtatVide(
            titre: 'Aucun produit',
            message: 'Appuyez sur « Photo et prix » pour ajouter votre premier produit.',
            icone: Icons.inventory_2,
          );
        }
        final nbDispo = liste.where((p) => p.disponible).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, 96),
          children: [
            Text(
              '$nbDispo disponible${nbDispo > 1 ? 's' : ''} · ${liste.length - nbDispo} épuisé${liste.length - nbDispo > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.texteSecondaire),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "Touchez un produit pour changer son prix.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.m),
            for (final produit in liste) ...[
              CarteProduit(
                produit: produit,
                onBasculer: () => ref.read(commercantActionsProvider).basculerDisponibilite(produit),
                onTap: () => _changerPrix(context, ref, produit),
              ),
              const SizedBox(height: AppSpacing.s),
            ],
          ],
        );
      },
    );
  }

  /// Feuille qui monte du bas avec un champ « Nouveau prix ».
  Future<void> _changerPrix(BuildContext context, WidgetRef ref, Produit produit) async {
    final nouveauPrix = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true, // la feuille remonte au-dessus du clavier
      builder: (context) => _FeuillePrix(produit: produit),
    );
    if (nouveauPrix == null || nouveauPrix == produit.prix) return;
    await ref.read(commercantActionsProvider).changerPrix(produit, nouveauPrix);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${produit.nom} : ${formaterPrix(nouveauPrix)} / ${produit.unite.symbole}')),
      );
    }
  }
}

class _FeuillePrix extends StatefulWidget {
  const _FeuillePrix({required this.produit});

  final Produit produit;

  @override
  State<_FeuillePrix> createState() => _FeuillePrixState();
}

class _FeuillePrixState extends State<_FeuillePrix> {
  final _formKey = GlobalKey<FormState>();
  late final _controleur = TextEditingController(text: '${widget.produit.prix}');

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  void _valider() {
    if (_formKey.currentState!.validate()) {
      // Navigator.pop renvoie la valeur à showModalBottomSheet.
      Navigator.pop(context, int.parse(_controleur.text.replaceAll(' ', '')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.produit;
    return Padding(
      // viewInsets.bottom = hauteur du clavier ouvert.
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l, AppSpacing.l, AppSpacing.l,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.l,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Prix de « ${p.nom} »', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Les commandes déjà passées gardent leur prix.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.m),
            TextFormField(
              controller: _controleur,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'Nouveau prix',
                suffixText: 'F / ${p.unite.symbole}',
              ),
              validator: validerPrix,
              onFieldSubmitted: (_) => _valider(),
            ),
            const SizedBox(height: AppSpacing.l),
            FilledButton(onPressed: _valider, child: const Text('Enregistrer le prix')),
          ],
        ),
      ),
    );
  }
}
