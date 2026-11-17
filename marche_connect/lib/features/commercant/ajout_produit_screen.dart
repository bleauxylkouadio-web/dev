// =====================================================================
//  ajout_produit_screen.dart : « + Photo et prix » — NOUVEAU PRODUIT
//
//  UX-04 : un commerçant publie un produit en MOINS DE 3 MINUTES.
//  Donc : le strict minimum, de gros choix à toucher, et des valeurs
//  par défaut intelligentes (catégorie de l'étal, vente à la pièce).
//
//   [ 📷 Ajouter une photo ]
//   Nom du produit   [Tomates          ]
//   Prix             [500        ] F
//   Vendu            (kg) (lot) (pièce) (portion)
//   Catégorie        (Légumes) (Épicerie) …
//   Précision        [facultatif       ]
//   [          Publier le produit          ]
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/utils/icones.dart';
import '../../core/utils/validators.dart';
import '../../data/models/models.dart';
import 'commercant_providers.dart';

class AjoutProduitScreen extends ConsumerStatefulWidget {
  const AjoutProduitScreen({super.key});

  @override
  ConsumerState<AjoutProduitScreen> createState() => _AjoutProduitScreenState();
}

class _AjoutProduitScreenState extends ConsumerState<AjoutProduitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prix = TextEditingController();
  final _description = TextEditingController();

  UniteVente _unite = UniteVente.piece;
  CategorieProduit? _categorie; // null = celle de l'étal (voir build)
  bool _enCours = false;

  @override
  void dispose() {
    _nom.dispose();
    _prix.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _publier(CategorieProduit categorie) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enCours = true);
    try {
      final produit = await ref.read(commercantActionsProvider).ajouterProduit(
            nom: _nom.text.trim(),
            prix: int.parse(_prix.text),
            unite: _unite,
            categorie: categorie,
            description: _description.text.trim().isEmpty ? null : _description.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${produit.nom} est en vente !')),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _enCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le produit n'a pas pu être publié. Réessayez.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    final etal = ref.watch(monEtalProvider).value;
    // Catégorie par défaut : la première de l'étal (un étal de légumes
    // vend surtout des légumes) → un choix de moins à faire.
    final categorie = _categorie ?? etal?.categories.first ?? CategorieProduit.autres;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau produit')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: FilledButton(
            onPressed: _enCours ? null : () => _publier(categorie),
            child: _enCours
                ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3))
                : const Text('Publier le produit'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.m),
          children: [
            // ---------- Photo ----------
            // La photo sera envoyée au serveur (stockage d'images) quand
            // l'API existera. En attendant, l'icône de la catégorie s'affiche.
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("L'envoi de photos arrivera avec le serveur.")),
              ),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Ajouter une photo (bientôt)'),
            ),
            const SizedBox(height: AppSpacing.l),

            // ---------- Nom ----------
            TextFormField(
              controller: _nom,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nom du produit',
                hintText: 'Ex. : Tomates',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (v) => validerObligatoire(v, champ: 'le nom du produit'),
            ),
            const SizedBox(height: AppSpacing.m),

            // ---------- Prix ----------
            TextFormField(
              controller: _prix,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'Prix',
                prefixIcon: const Icon(Icons.sell),
                suffixText: 'F / ${_unite.symbole}',
              ),
              validator: validerPrix,
            ),
            const SizedBox(height: AppSpacing.l),

            // ---------- Unité (MAR-02) ----------
            Text('Vendu', style: textes.titleMedium),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                for (final u in UniteVente.values)
                  ChoiceChip(
                    label: Text(u.libelle),
                    selected: _unite == u,
                    onSelected: (_) => setState(() => _unite = u),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),

            // ---------- Catégorie ----------
            Text('Catégorie', style: textes.titleMedium),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                for (final c in CategorieProduit.values)
                  ChoiceChip(
                    avatar: Icon(iconeCategorie(c), size: 18),
                    label: Text(c.libelle),
                    selected: categorie == c,
                    onSelected: (_) => setState(() => _categorie = c),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),

            // ---------- Précision ----------
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Précision (facultatif)',
                hintText: 'Ex. : tas de 5 tomates bien mûres',
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Le produit est publié « Disponible ». Vous pourrez le passer en « Épuisé » d\'un geste.',
              style: textes.bodySmall?.copyWith(color: AppColors.texteSecondaire),
            ),
          ],
        ),
      ),
    );
  }
}
