// =====================================================================
//  panier_provider.dart : le PANIER du client (logique)
//
//  L'écran du panier sera construit à l'étape 10, mais la vitrine
//  (étape 9) doit déjà pouvoir y ajouter des produits.
//
//  Règle importante : UN PANIER = UN SEUL ÉTAL.
//  Une commande est préparée par un commerçant et livrée depuis son étal
//  (Commande.etalId). Si le client ajoute un produit d'un autre étal,
//  on lui demande s'il veut vider son panier.
// =====================================================================

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/repositories/providers.dart';

/// Contenu du panier (immuable).
class Panier {
  const Panier({this.etalId, this.nomEtal, this.lignes = const []});

  /// L'étal des produits du panier ; null quand le panier est vide.
  final String? etalId;
  final String? nomEtal;
  final List<LigneCommande> lignes;

  bool get estVide => lignes.isEmpty;

  /// Montant des produits (sans livraison).
  int get sousTotal => lignes.fold(0, (somme, l) => somme + l.total);

  /// Nombre de produits différents (affiché sur l'icône du panier).
  int get nombreLignes => lignes.length;

  /// Quantité d'un produit dans le panier (0 s'il n'y est pas).
  double quantiteDe(String produitId) {
    for (final ligne in lignes) {
      if (ligne.produitId == produitId) return ligne.quantite;
    }
    return 0;
  }

  // ---------- JSON : pour enregistrer le panier sur le téléphone ----------
  Map<String, dynamic> toJson() => {
        'etalId': etalId,
        'nomEtal': nomEtal,
        'lignes': [for (final l in lignes) l.toJson()],
      };

  factory Panier.fromJson(Map<String, dynamic> json) => Panier(
        etalId: json['etalId'] as String?,
        nomEtal: json['nomEtal'] as String?,
        lignes: [
          for (final l in json['lignes'] as List) LigneCommande.fromJson(l as Map<String, dynamic>),
        ],
      );
}

/// Résultat d'un ajout : soit ajouté, soit refusé car autre étal.
enum ResultatAjout { ajoute, autreEtal }

class PanierNotifier extends Notifier<Panier> {
  /// Clé du panier dans le stockage du téléphone.
  static const _cle = 'panier';

  /// MAR-04 : « commande conservée après une coupure réseau ».
  /// Au démarrage, on relit le panier enregistré ; ensuite, CHAQUE
  /// modification est enregistrée automatiquement (listenSelf).
  /// Fermer l'application ou perdre le réseau ne vide donc pas le panier.
  @override
  Panier build() {
    final stockage = ref.watch(stockageLocalProvider);
    listenSelf((_, nouveau) => stockage.ecrire(_cle, jsonEncode(nouveau.toJson())));

    final texte = stockage.lire(_cle);
    if (texte == null) return const Panier();
    try {
      return Panier.fromJson(jsonDecode(texte) as Map<String, dynamic>);
    } catch (_) {
      return const Panier(); // panier enregistré illisible : on repart à vide
    }
  }

  /// Ajoute 1 unité du produit. Si le produit est déjà là, augmente
  /// sa quantité. Refuse (autreEtal) si le panier contient un autre étal.
  ResultatAjout ajouter(Produit produit, Etal etal) {
    if (!state.estVide && state.etalId != etal.id) {
      return ResultatAjout.autreEtal;
    }
    final quantiteActuelle = state.quantiteDe(produit.id);
    if (quantiteActuelle > 0) {
      changerQuantite(produit.id, quantiteActuelle + 1);
    } else {
      state = Panier(
        etalId: etal.id,
        nomEtal: etal.nom,
        // MAR-03 : le prix est copié dans la ligne au moment de l'ajout.
        lignes: [...state.lignes, LigneCommande.depuisProduit(produit)],
      );
    }
    return ResultatAjout.ajoute;
  }

  /// Vide le panier puis ajoute le produit (réponse « Oui » à la question
  /// « Vider le panier ? »).
  void viderEtAjouter(Produit produit, Etal etal) {
    vider();
    ajouter(produit, etal);
  }

  /// Nouvelle quantité ; 0 ou moins retire la ligne.
  void changerQuantite(String produitId, double quantite) {
    if (quantite <= 0) {
      retirer(produitId);
      return;
    }
    state = Panier(
      etalId: state.etalId,
      nomEtal: state.nomEtal,
      lignes: [
        for (final l in state.lignes)
          l.produitId == produitId ? l.copyWith(quantite: quantite) : l,
      ],
    );
  }

  /// Retire une ligne. Si c'était la dernière, le panier redevient vide.
  void retirer(String produitId) {
    final restantes = state.lignes.where((l) => l.produitId != produitId).toList();
    state = restantes.isEmpty
        ? const Panier()
        : Panier(etalId: state.etalId, nomEtal: state.nomEtal, lignes: restantes);
  }

  void vider() => state = const Panier();
}

/// Pas d'autoDispose : le panier doit survivre quand on change d'écran.
final panierProvider = NotifierProvider<PanierNotifier, Panier>(PanierNotifier.new);
