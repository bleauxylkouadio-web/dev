// =====================================================================
//  widget_test.dart : tests de l'application complète (démarrage)
// =====================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:marche_connect/core/router/app_router.dart';
import 'package:marche_connect/core/router/routes.dart';

import 'helpers.dart';

void main() {
  testWidgets("L'application démarre sur la liste des étals, sans compte", (tester) async {
    final c = conteneurDeTest();
    await lancerApp(tester, c);

    expect(find.text('MARCHÉ_CONNECT'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('5 étals'), findsOneWidget);
  });

  testWidgets('Espace commerçant sans compte → redirigé vers la connexion', (tester) async {
    final c = conteneurDeTest();
    await lancerApp(tester, c);

    c.read(routerProvider).go(Routes.commercant);
    await tester.pumpAndSettle();
    expect(find.text('Recevoir le code'), findsOneWidget);
    // La suite du parcours (code OTP, retour) est testée dans connexion_test.dart.
  });
}
