// =====================================================================
//  scan_screen.dart : SCAN DU TICKET QR avec la caméra
//
//  Parcours QR (diapositive 7) : « le livreur scanne le ticket QR pour
//  valider la remise » — que le client ait un smartphone (ticket à
//  l'écran) ou non (ticket imprimé).
//
//   ┌ Scanner le ticket                   [🔦] ┐
//   │                                          │
//   │         ┌──────────────────┐              │
//   │         │   (caméra)       │  ← cadre    │
//   │         └──────────────────┘              │
//   │  Placez le QR du ticket dans le cadre     │
//   │  [⌨ Le QR est abîmé : saisir le code]     │
//   └──────────────────────────────────────────┘
//
//  Paquet mobile_scanner : fonctionne sur Android, iOS et navigateur.
//  Permissions : la caméra est demandée à la première ouverture
//  (iOS : texte NSCameraUsageDescription dans ios/Runner/Info.plist).
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_sizes.dart';
import 'validation_remise.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  /// Pilote la caméra (lampe, pause…).
  final _camera = MobileScannerController(
    formats: const [BarcodeFormat.qrCode], // on ne cherche que des QR
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// Vrai pendant la validation : on ignore les autres détections
  /// (la caméra voit le même QR plusieurs fois par seconde).
  bool _traitement = false;

  @override
  void dispose() {
    _camera.dispose(); // libère la caméra
    super.dispose();
  }

  Future<void> _surDetection(BarcodeCapture capture) async {
    if (_traitement) return;
    final texte = capture.barcodes.firstOrNull?.rawValue;
    if (texte == null) return;

    _traitement = true;
    await _camera.stop(); // pause pendant l'affichage du résultat
    if (!mounted) return;

    final ok = await validerEtAfficher(context, ref, texte);
    if (!mounted) return;
    if (ok) {
      context.pop(); // retour aux missions, mises à jour
    } else {
      _traitement = false;
      await _camera.start(); // nouvel essai
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner le ticket'),
        actions: [
          IconButton(
            tooltip: 'Lampe',
            icon: const Icon(Icons.flashlight_on),
            onPressed: () => _camera.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ---------- La caméra, plein écran ----------
          MobileScanner(
            controller: _camera,
            onDetect: _surDetection,
            // Caméra refusée, absente (ordinateur) ou en erreur.
            errorBuilder: (context, erreur) => _CameraIndisponible(
              onCode: () => saisirCodeEtValider(context, ref),
            ),
          ),

          // ---------- Cadre de visée ----------
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(AppRadius.grand),
              ),
            ),
          ),

          // ---------- Consigne + secours ----------
          Positioned(
            left: AppSpacing.m,
            right: AppSpacing.m,
            bottom: AppSpacing.l,
            child: SafeArea(
              child: Column(
                children: [
                  const Text(
                    'Placez le QR du ticket dans le cadre',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () async {
                      final ok = await saisirCodeEtValider(context, ref);
                      if (ok && context.mounted) context.pop();
                    },
                    icon: const Icon(Icons.dialpad),
                    label: const Text('QR abîmé : saisir le code'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Affiché quand la caméra ne peut pas démarrer.
class _CameraIndisponible extends StatelessWidget {
  const _CameraIndisponible({required this.onCode});

  final VoidCallback onCode;

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.l),
          child: Text(
            "Caméra indisponible.\nAutorisez l'accès à la caméra dans les réglages, "
            'ou saisissez le code du ticket.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
