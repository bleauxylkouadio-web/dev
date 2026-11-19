// =====================================================================
//  carte_livreur.dart : OÙ EST MON LIVREUR ? (suivi en direct)
//
//  Affiché sur le ticket dès que la commande est « En livraison »,
//  c'est-à-dire dès que le livreur a récupéré le colis.
//
//   ┌──────────────────────────────────────┐
//   │            (carte)       🛵           │
//   └──────────────────────────────────────┘
//   Votre livreur arrive · position il y a 20 s
//   [ Ouvrir dans Google Maps ]
//
//  Carte : flutter_map + fonds OpenStreetMap (gratuits, sans clé).
//  ⚠ En production, utiliser un fournisseur de fonds de carte (ou un
//  serveur à soi) : les serveurs publics d'OpenStreetMap limitent l'usage.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../commande_providers.dart';

class CarteLivreur extends ConsumerWidget {
  const CarteLivreur({super.key, required this.commande});

  final Commande commande;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(positionLivreurProvider(commande.id));
    final textes = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // `.value` : on garde l'ancienne position affichée pendant le
          // rechargement (pas de clignotement toutes les 10 s).
          switch (position.value) {
            final p? => _Carte(position: p),
            null => Container(
                height: 120,
                color: AppColors.primaireClair,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Text(
                  position.isLoading ? 'Recherche du livreur…' : 'Position du livreur en attente…',
                  textAlign: TextAlign.center,
                ),
              ),
          },
          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.delivery_dining, color: AppColors.primaire),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(child: Text('Votre livreur arrive', style: textes.titleMedium)),
                  ],
                ),
                if (position.value != null)
                  Text(
                    'Position ${formaterDepuis(position.value!.misAJourLe)}',
                    style: textes.bodySmall?.copyWith(color: AppColors.texteSecondaire),
                  ),
                if (position.value != null) ...[
                  const SizedBox(height: AppSpacing.s),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.https('www.google.com', '/maps/search/', {
                        'api': '1',
                        'query': '${position.value!.latitude},${position.value!.longitude}',
                      }),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.map),
                    label: const Text('Ouvrir dans Google Maps'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La carte centrée sur le livreur. Elle SUIT le livreur quand sa
/// position change (MapController.move).
class _Carte extends StatefulWidget {
  const _Carte({required this.position});

  final PositionLivreur position;

  @override
  State<_Carte> createState() => _CarteState();
}

class _CarteState extends State<_Carte> {
  final _controleur = MapController();
  bool _prete = false; // la carte doit être affichée avant de pouvoir bouger

  LatLng get _point => LatLng(widget.position.latitude, widget.position.longitude);

  @override
  void didUpdateWidget(covariant _Carte ancien) {
    super.didUpdateWidget(ancien);
    // Nouvelle position : on recentre la carte, en gardant le zoom choisi.
    if (_prete && ancien.position.misAJourLe != widget.position.misAJourLe) {
      _controleur.move(_point, _controleur.camera.zoom);
    }
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: FlutterMap(
        mapController: _controleur,
        options: MapOptions(
          initialCenter: _point,
          initialZoom: 15,
          onMapReady: () => _prete = true,
        ),
        children: [
          // Fonds de carte OpenStreetMap.
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'ci.marcheconnect.marche_connect',
          ),
          // Le livreur : rond orange avec un scooter.
          MarkerLayer(
            markers: [
              Marker(
                point: _point,
                width: 48,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.delivery_dining, color: AppColors.surAccent),
                ),
              ),
            ],
          ),
          // Mention obligatoire des contributeurs OpenStreetMap, sous forme
          // d'une petite icône ⓘ qui se déplie (tient sur un petit écran).
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'Contributeurs OpenStreetMap',
                onTap: () => launchUrl(Uri.https('www.openstreetmap.org', '/copyright')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
