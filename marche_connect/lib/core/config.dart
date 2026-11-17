// =====================================================================
//  config.dart : réglages généraux de l'application
// =====================================================================

/// Adresse publique de la PWA (à remplacer par le vrai nom de domaine).
/// C'est le début des liens imprimés dans les QR des étals.
const String urlPubliqueApp = 'https://marche-connect.ci';

/// Commission de la plateforme sur le montant des produits vendus.
/// ⚠️ HYPOTHÈSE de travail (5 %) : le cahier des charges prévoit une
/// commission sans en fixer le taux. À confirmer avant le pilote.
const double tauxCommission = 0.05;

/// Lien complet encodé dans le QR plastifié d'un étal (MAR-05) :
/// le scanner avec l'appareil photo ouvre directement la vitrine.
String lienPublicEtal(String etalId) => '$urlPubliqueApp/etal/$etalId';
