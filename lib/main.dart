// ============================================================================
//  Pharmacies de garde — « L'Atelier des Maîtres »
//  Parcours : Accueil  ->  Résultats de recherche  ->  Fiche pharmacie
//
//  Direction artistique (tout est dessiné en code, aucune image, aucun package) :
//    • NUIT   -> « La Nuit étoilée » (Van Gogh)
//    • JOUR   -> « Les Nymphéas » (Monet)
//    • ACTION -> « Les papiers découpés » (Matisse) : corail pour les boutons
//
//  Aucune dépendance externe : seulement flutter/material et flutter/services.
//  Nécessite Dart 3 (Flutter 3.10 ou plus récent).
// ============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const PharmaGardeApp());

// ============================================================================
// 1. MODÈLE
// ============================================================================

/// Plage d'ouverture quotidienne (identique tous les jours dans ce prototype).
@immutable
class Horaires {
  const Horaires(this.ouverture, this.fermeture) : h24 = false;
  const Horaires.h24() : ouverture = 0, fermeture = 24, h24 = true;

  final int ouverture; // heure d'ouverture (0-23)
  final int fermeture; // heure de fermeture (1-24)
  final bool h24;

  bool estOuvertA(DateTime t) {
    if (h24) return true;
    final heure = t.hour + t.minute / 60;
    return heure >= ouverture && heure < fermeture;
  }

  String get libelle =>
      h24 ? '24h/24' : '${_hh(ouverture)} – ${_hh(fermeture)}';

  static String _hh(int h) => '${h.toString().padLeft(2, '0')}h00';
}

@immutable
class Pharmacie {
  const Pharmacie({
    required this.id,
    required this.nom,
    required this.commune,
    required this.quartier,
    required this.adresse,
    required this.telephone,
    required this.distanceKm,
    required this.horaires,
    required this.description,
    this.deGarde = false,
  });

  final String id;
  final String nom;
  final String commune;
  final String quartier;
  final String adresse;
  final String telephone;
  final double distanceKm;
  final Horaires horaires;
  final String description;
  final bool deGarde;

  /// Une pharmacie de garde est considérée ouverte en continu.
  bool estOuverte([DateTime? maintenant]) =>
      deGarde || horaires.estOuvertA(maintenant ?? DateTime.now());

  String get adresseComplete => '$adresse, $commune';

  String get distanceLibelle => distanceKm < 1
      ? '${(distanceKm * 1000).round()} m'
      : '${distanceKm.toStringAsFixed(1)} km';

  String statutDetaille([DateTime? maintenant]) {
    final t = maintenant ?? DateTime.now();
    if (horaires.h24) return 'Ouverte 24h/24';
    if (deGarde) return 'Pharmacie de garde, ouverte en continu';
    return horaires.estOuvertA(t)
        ? 'Ouverte, ferme à ${Horaires._hh(horaires.fermeture)}'
        : 'Fermée, ouvre à ${Horaires._hh(horaires.ouverture)}';
  }
}

// ============================================================================
// 2. DONNÉES FICTIVES (remplacées par Firestore en séance 4)
// ============================================================================

const pharmaciesFictives = <Pharmacie>[
  Pharmacie(
    id: 'ph-01',
    nom: 'Pharmacie du Campus',
    commune: 'Cocody',
    quartier: 'Riviera 2',
    adresse: 'Boulevard des Martyrs',
    telephone: '07 00 00 00 01',
    distanceKm: 0.4,
    horaires: Horaires(8, 22),
    deGarde: true,
    description:
        'Pharmacie de quartier proche du campus, conseils personnalisés et '
        'large choix de produits de parapharmacie.',
  ),
  Pharmacie(
    id: 'ph-02',
    nom: 'Pharmacie Saint-Michel',
    commune: 'Cocody',
    quartier: 'Deux Plateaux',
    adresse: 'Rue des Jardins',
    telephone: '07 00 00 00 06',
    distanceKm: 1.3,
    horaires: Horaires(8, 20),
    description:
        'Équipe à l\'écoute, orthopédie, matériel médical et préparations '
        'magistrales.',
  ),
  Pharmacie(
    id: 'ph-03',
    nom: 'Pharmacie Plateau Centre',
    commune: 'Plateau',
    quartier: 'Centre des affaires',
    adresse: "Avenue Franchet d'Esperey",
    telephone: '07 00 00 00 07',
    distanceKm: 4.4,
    horaires: Horaires(7, 19),
    description:
        'Située au coeur du quartier des affaires, idéale avant ou après le '
        'travail.',
  ),
  Pharmacie(
    id: 'ph-04',
    nom: 'Pharmacie de la Gare',
    commune: 'Adjamé',
    quartier: 'Liberté',
    adresse: 'Rue 12, près de la gare routière',
    telephone: '07 00 00 00 02',
    distanceKm: 3.8,
    horaires: Horaires(7, 20),
    description:
        'Pratique pour les voyageurs : ouverte tôt, avec un grand choix de '
        'médicaments courants.',
  ),
  Pharmacie(
    id: 'ph-05',
    nom: 'Pharmacie de la Lagune',
    commune: 'Marcory',
    quartier: 'Zone 4',
    adresse: 'Rue Pierre et Marie Curie',
    telephone: '07 00 00 00 04',
    distanceKm: 5.1,
    horaires: Horaires(8, 19),
    description:
        'Vue sur la lagune, service rapide, dépistages et conseils santé.',
  ),
  Pharmacie(
    id: 'ph-06',
    nom: 'Pharmacie de la Corniche',
    commune: 'Treichville',
    quartier: 'Boulevard de Marseille',
    adresse: 'Boulevard de Marseille',
    telephone: '07 00 00 00 08',
    distanceKm: 6.0,
    horaires: Horaires(8, 22),
    deGarde: true,
    description:
        'Pharmacie de garde du secteur sud, service de nuit assuré avec '
        'ordonnance ou sans.',
  ),
  Pharmacie(
    id: 'ph-07',
    nom: 'Pharmacie du Marché',
    commune: 'Yopougon',
    quartier: 'Sicogi',
    adresse: 'Avenue 5, face au grand marché',
    telephone: '07 00 00 00 03',
    distanceKm: 7.2,
    horaires: Horaires(8, 21),
    deGarde: true,
    description:
        'Au coeur du marché de Yopougon, forte affluence en journée et '
        'garde de nuit régulière.',
  ),
  Pharmacie(
    id: 'ph-08',
    nom: 'Pharmacie Les Palmiers',
    commune: 'Abobo',
    quartier: 'Sagbé',
    adresse: "Route d'Abobo, carrefour Sagbé",
    telephone: '07 00 00 00 05',
    distanceKm: 9.6,
    horaires: Horaires.h24(),
    deGarde: true,
    description:
        'Ouverte jour et nuit, tous les jours de la semaine, pour toutes les '
        'urgences du quartier.',
  ),
];

// Valeurs dérivées calculées une seule fois (et non à chaque build).
final _pharmaciesDeGarde = pharmaciesFictives
    .where((p) => p.deGarde)
    .toList(growable: false);

final List<String> _communes =
    (pharmaciesFictives.map((p) => p.commune).toSet().toList()..sort());

final _plusProches = rechercher(pharmaciesFictives)
    .take(3)
    .toList(growable: false);

// ============================================================================
// 3. LOGIQUE DE RECHERCHE (aucune dépendance à l'interface => testable)
// ============================================================================

const _accents = 'àâäéèêëîïôöùûüç';
const _sansAccents = 'aaaeeeeiioouuuc';

/// Minuscules + suppression des accents : « Adjamé » == « adjame ».
String normaliser(String texte) {
  final sortie = StringBuffer();
  for (final rune in texte.toLowerCase().runes) {
    final c = String.fromCharCode(rune);
    final i = _accents.indexOf(c);
    sortie.write(i == -1 ? c : _sansAccents[i]);
  }
  return sortie.toString().trim();
}

String _construireTexte(Pharmacie p) =>
    normaliser('${p.nom} ${p.commune} ${p.quartier} ${p.adresse}');

/// Index de recherche : calculé une seule fois pour toutes les pharmacies.
final Map<String, String> _index = {
  for (final p in pharmaciesFictives) p.id: _construireTexte(p),
};

String _texteDe(Pharmacie p) => _index[p.id] ?? _construireTexte(p);

enum FiltrePharmacie {
  toutes('Toutes', Icons.apps_rounded),
  ouvertes('Ouvertes', Icons.check_circle_outline_rounded),
  deGarde('De garde', Icons.nightlight_round);

  const FiltrePharmacie(this.libelle, this.icone);

  final String libelle;
  final IconData icone;

  bool accepte(Pharmacie p, DateTime maintenant) => switch (this) {
    FiltrePharmacie.toutes => true,
    FiltrePharmacie.ouvertes => p.estOuverte(maintenant),
    FiltrePharmacie.deGarde => p.deGarde,
  };
}

final _espaces = RegExp(r'\s+');

/// Filtre par texte (tous les mots saisis doivent correspondre) et par statut,
/// puis trie de la plus proche à la plus éloignée.
List<Pharmacie> rechercher(
  List<Pharmacie> source, {
  String requete = '',
  FiltrePharmacie filtre = FiltrePharmacie.toutes,
}) {
  final mots = normaliser(requete)
      .split(_espaces)
      .where((m) => m.isNotEmpty)
      .toList();
  final maintenant = DateTime.now(); // lu une seule fois
  final liste = source.where((p) {
    if (!filtre.accepte(p, maintenant)) return false;
    if (mots.isEmpty) return true;
    final texte = _texteDe(p);
    return mots.every(texte.contains);
  }).toList();
  liste.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return liste;
}

String pluriel(int n, String mot) => '$n $mot${n > 1 ? 's' : ''}';

String heureLibelle(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}h${t.minute.toString().padLeft(2, '0')}';

// ============================================================================
// 4. DESIGN SYSTEM
// ============================================================================

abstract final class AppColors {
  // Van Gogh : la nuit étoilée
  static const nuitProfonde = Color(0xFF0B1B4D);
  static const outremer = Color(0xFF2347B8);
  static const cobalt = Color(0xFF3A63D8);
  static const soleil = Color(0xFFFFC93C); // étoiles, lune, accents sur nuit

  // Monet : les nymphéas
  static const abysse = Color(0xFF0A4F5C);
  static const nenuphar = Color(0xFF1B9C85);
  static const lilas = Color(0xFF9D8DF1);

  // Matisse : papier découpé, pour l'action principale
  static const corail = Color(0xFFE8452A);

  static const primary = outremer;
  static const List<Color> nuit = [nuitProfonde, Color(0xFF1E3A9E), cobalt];
  static const List<Color> jour = [abysse, nenuphar];

  static const garde = outremer;
  static const ouvert = Color(0xFF0E8A72);
  static const ferme = Color(0xFFD93B2B);

  static const fond = Color(0xFFEFF3FB); // brume de l'aube
  static const texte = Color(0xFF16163A);
  static const texteDoux = Color(0xFF63658A);
  static const bordure = Color(0xFFDCE3F4);

  static const List<BoxShadow> ombre = [
    BoxShadow(color: Color(0x1A1B2A6E), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static LinearGradient degrade(
    List<Color> couleurs, {
    Alignment debut = Alignment.topLeft,
    Alignment fin = Alignment.bottomRight,
  }) => LinearGradient(begin: debut, end: fin, colors: couleurs);
}

/// Titres en empattement (esprit « cartel de musée »), corps en police système.
abstract final class AppText {
  static const serif = TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: ['Noto Serif', 'Times New Roman', 'serif'],
    fontWeight: FontWeight.w700,
  );
}

abstract final class AppTheme {
  static final ThemeData clair = _construire();

  static ThemeData _construire() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.outremer,
        primary: AppColors.outremer,
        surface: Colors.white,
      ),
    );
    final boutonForme = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.fond,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.texte,
        displayColor: AppColors.texte,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.corail,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 56),
          shape: boutonForme,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.outremer,
          backgroundColor: Colors.white,
          minimumSize: const Size(64, 56),
          shape: boutonForme,
          side: const BorderSide(color: AppColors.outremer, width: 1.6),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.outremer,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.nuitProfonde,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ----------------------------------------------------------- Les peintures ---

/// « La Nuit étoilée » : tourbillons bleus, étoiles scintillantes, croissant.
class CielEtoile extends CustomPainter {
  const CielEtoile({this.lune = true});

  final bool lune;

  // dx, dy (en fraction de la taille), échelle
  static const List<(double, double, double)> _tourbillons = [
    (0.80, 0.34, 1.0),
    (0.14, 0.70, 0.75),
    (0.50, 0.92, 0.6),
  ];

  // dx, dy, rayon de l'étoile
  static const List<(double, double, double)> _etoiles = [
    (0.10, 0.12, 5.5),
    (0.34, 0.08, 4.0),
    (0.58, 0.14, 6.0),
    (0.92, 0.62, 4.5),
    (0.66, 0.66, 3.5),
    (0.24, 0.42, 3.5),
    (0.05, 0.50, 3.0),
    (0.46, 0.56, 3.0),
  ];

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;

    // Tourbillons : arcs concentriques décalés, façon coups de pinceau.
    for (var k = 0; k < _tourbillons.length; k++) {
      final (dx, dy, e) = _tourbillons[k];
      final centre = Offset(w * dx, h * dy);
      for (var i = 0; i < 7; i++) {
        final pinceau = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = (2.6 - i * 0.18) * e + 0.6
          ..color =
              (i.isEven ? const Color(0xFF9DBBFF) : const Color(0xFF6C8CF2))
                  .withAlpha(34 + (i % 3) * 14);
        canvas.drawArc(
          Rect.fromCircle(center: centre, radius: (16 + i * 12.0) * e),
          i * 0.9 + k * 1.7,
          4.2,
          false,
          pinceau,
        );
      }
    }

    // Étoiles : halo flou + éclat à quatre branches.
    for (final (dx, dy, r) in _etoiles) {
      final c = Offset(w * dx, h * dy);
      canvas.drawCircle(
        c,
        r * 2.2,
        Paint()
          ..color = AppColors.soleil.withAlpha(80)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.4),
      );
      canvas.drawPath(
        _eclat(c, r * 1.5),
        Paint()..color = const Color(0xFFFFE9A6),
      );
    }

    // Croissant de lune.
    if (lune) {
      final c = Offset(w * 0.86, h * 0.30);
      const r = 19.0;
      canvas.drawCircle(
        c,
        r * 1.9,
        Paint()
          ..color = AppColors.soleil.withAlpha(90)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
      final croissant = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: c, radius: r)),
        Path()..addOval(
          Rect.fromCircle(
            center: c.translate(r * 0.55, -r * 0.2),
            radius: r * 0.86,
          ),
        ),
      );
      canvas.drawPath(croissant, Paint()..color = AppColors.soleil);
    }
  }

  static Path _eclat(Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final rayon = i.isEven ? r : r * 0.32;
      final a = i * math.pi / 4 - math.pi / 2;
      final pt = Offset(c.dx + rayon * math.cos(a), c.dy + rayon * math.sin(a));
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(covariant CielEtoile old) => old.lune != lune;
}

/// « Les Nymphéas » : taches d'aquarelle, feuilles et fleurs de nénuphar.
class Nympheas extends CustomPainter {
  const Nympheas();

  // dx, dy, rayon, couleur (ARGB)
  static const List<(double, double, double, int)> _taches = [
    (0.15, 0.20, 70.0, 0x59BFE9D6),
    (0.85, 0.30, 85.0, 0x599D8DF1),
    (0.55, 0.85, 90.0, 0x40FFB6D1),
    (0.05, 0.90, 60.0, 0x4D7BD3A8),
  ];

  // dx, dy, rayon x, rotation
  static const List<(double, double, double, double)> _feuilles = [
    (0.80, 0.75, 38.0, 0.4),
    (0.18, 0.55, 28.0, 2.2),
    (0.62, 0.30, 22.0, 4.0),
    (0.92, 0.12, 26.0, 1.2),
  ];

  // dx, dy des fleurs
  static const List<(double, double)> _fleurs = [(0.78, 0.72), (0.20, 0.52)];

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;

    for (final (dx, dy, rayon, couleur) in _taches) {
      canvas.drawCircle(
        Offset(w * dx, h * dy),
        rayon,
        Paint()
          ..color = Color(couleur)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
      );
    }

    for (final (dx, dy, rx, rotation) in _feuilles) {
      final c = Offset(w * dx, h * dy);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rotation);
      canvas.scale(1, 0.55); // la feuille flotte à plat sur l'eau
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: rx),
        0.35,
        math.pi * 2 - 0.7,
        true,
        Paint()..color = const Color(0xFF9FE3C0).withAlpha(120),
      );
      canvas.restore();
    }

    // Deux fleurs : pétales roses autour d'un coeur jaune.
    for (final (dx, dy) in _fleurs) {
      final c = Offset(w * dx, h * dy);
      for (var i = 0; i < 6; i++) {
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(i * math.pi / 3);
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(0, -9), width: 9, height: 20),
          Paint()..color = const Color(0xFFFFD1E3).withAlpha(210),
        );
        canvas.restore();
      }
      canvas.drawCircle(c, 4, Paint()..color = AppColors.soleil);
    }
  }

  @override
  bool shouldRepaint(covariant Nympheas old) => false;
}

/// Bandeau peint : dégradé + peinture, avec un contenu posé dessus.
class FondPeint extends StatelessWidget {
  const FondPeint({
    super.key,
    required this.nuit,
    required this.child,
    this.rayon = 32,
  });

  final bool nuit;
  final double rayon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(rayon)),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.degrade(
                  nuit ? AppColors.nuit : AppColors.jour,
                  debut: Alignment.topCenter,
                  fin: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: nuit ? const CielEtoile() : const Nympheas(),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ============================================================================
// 5. APPLICATION ET NAVIGATION
// ============================================================================

class PharmaGardeApp extends StatelessWidget {
  const PharmaGardeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharmacies de garde',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.clair,
      initialRoute: Routes.accueil,
      onGenerateRoute: Routes.generer,
    );
  }
}

@immutable
class ResultatsArgs {
  const ResultatsArgs({
    this.requete = '',
    this.autourDeMoi = false,
    this.filtre = FiltrePharmacie.toutes,
  });
  final String requete;
  final bool autourDeMoi;
  final FiltrePharmacie filtre;
}

abstract final class Routes {
  static const accueil = '/';
  static const resultats = '/resultats';
  static const detail = '/detail';

  static Route<void> generer(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      Routes.resultats => ResultatsPage(
        args: (settings.arguments as ResultatsArgs?) ?? const ResultatsArgs(),
      ),
      Routes.detail => DetailPage(pharmacie: settings.arguments as Pharmacie),
      _ => const AccueilPage(),
    };
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }

  static void versResultats(
    BuildContext context, {
    String requete = '',
    bool autourDeMoi = false,
    FiltrePharmacie filtre = FiltrePharmacie.toutes,
  }) {
    Navigator.of(context).pushNamed(
      resultats,
      arguments: ResultatsArgs(
        requete: requete,
        autourDeMoi: autourDeMoi,
        filtre: filtre,
      ),
    );
  }

  static void versDetail(BuildContext context, Pharmacie pharmacie) {
    Navigator.of(context).pushNamed(detail, arguments: pharmacie);
  }
}

// ============================================================================
// 6. ÉCRANS
// ============================================================================

// ---------------------------------------------------------------- Écran 1 ---
class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rechercher([String? texte]) =>
      Routes.versResultats(context, requete: texte ?? _controller.text);

  @override
  Widget build(BuildContext context) {
    final bas = MediaQuery.paddingOf(context).bottom;
    final nbGardes = _pharmaciesDeGarde.length;

    return Scaffold(
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EnTeteAccueil(controller: _controller, onRechercher: _rechercher),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TuileAction(
                      nuit: true,
                      icone: Icons.nightlight_round,
                      titre: 'De garde',
                      sousTitre: pluriel(nbGardes, 'pharmacie'),
                      onTap: () => Routes.versResultats(
                        context,
                        filtre: FiltrePharmacie.deGarde,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TuileAction(
                      nuit: false,
                      icone: Icons.my_location_rounded,
                      titre: 'Autour de moi',
                      sousTitre: 'Les plus proches',
                      onTap: () =>
                          Routes.versResultats(context, autourDeMoi: true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const TitreSection('Par commune'),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final commune in _communes)
                    ActionChip(
                      avatar: const Icon(
                        Icons.place_rounded,
                        size: 18,
                        color: AppColors.nenuphar,
                      ),
                      label: Text(commune),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.bordure),
                      shape: const StadiumBorder(),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                      onPressed: () => _rechercher(commune),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            TitreSection(
              'De garde cette nuit',
              actionLabel: 'Voir tout',
              onAction: () => Routes.versResultats(
                context,
                filtre: FiltrePharmacie.deGarde,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 184,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _pharmaciesDeGarde.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) => CarteGarde(
                  pharmacie: _pharmaciesDeGarde[i],
                  onTap: () =>
                      Routes.versDetail(context, _pharmaciesDeGarde[i]),
                ),
              ),
            ),
            const SizedBox(height: 30),
            TitreSection(
              'Les plus proches',
              actionLabel: 'Voir tout',
              onAction: () => Routes.versResultats(context, autourDeMoi: true),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (final p in _plusProches) ...[
                    CartePharmacie(
                      pharmacie: p,
                      onTap: () => Routes.versDetail(context, p),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            SizedBox(height: bas + 16),
          ],
        ),
      ),
    );
  }
}

class _EnTeteAccueil extends StatelessWidget {
  const _EnTeteAccueil({required this.controller, required this.onRechercher});

  final TextEditingController controller;
  final ValueChanged<String> onRechercher;

  @override
  Widget build(BuildContext context) {
    return FondPeint(
      nuit: true,
      rayon: 36,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.soleil,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_rounded,
                      color: AppColors.nuitProfonde,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'PharmaGarde',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const Pastille(
                    texte: 'Abidjan',
                    couleur: Colors.white,
                    icone: Icons.location_on_rounded,
                    surFonce: true,
                  ),
                ],
              ),
              const SizedBox(height: 34),
              Text(
                'Votre pharmacie\nde garde, tout près.',
                style: AppText.serif.copyWith(
                  color: Colors.white,
                  fontSize: 31,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Horaires, adresse et téléphone à Abidjan.',
                style: TextStyle(
                  color: Colors.white.withAlpha(225),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 22),
              ChampRecherche(controller: controller, onSubmitted: onRechercher),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Écran 2 ---
class ResultatsPage extends StatefulWidget {
  const ResultatsPage({super.key, required this.args});

  final ResultatsArgs args;

  @override
  State<ResultatsPage> createState() => _ResultatsPageState();
}

class _ResultatsPageState extends State<ResultatsPage> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.args.requete,
  );
  late FiltrePharmacie _filtre = widget.args.filtre;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reinitialiser() => setState(() {
    _controller.clear();
    _filtre = FiltrePharmacie.toutes;
  });

  @override
  Widget build(BuildContext context) {
    final resultats = rechercher(
      pharmaciesFictives,
      requete: _controller.text,
      filtre: _filtre,
    );
    final n = resultats.length;
    final autour = widget.args.autourDeMoi;

    return Scaffold(
      body: Column(
        children: [
          FondPeint(
            nuit: !autour,
            rayon: 28,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const BoutonRetour(),
                        const SizedBox(width: 4),
                        Text(
                          autour ? 'Autour de moi' : 'Résultats',
                          style: AppText.serif.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: ChampRecherche(
                        controller: _controller,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (autour)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _BandeauInfo(
                icone: Icons.my_location_rounded,
                texte: 'Position simulée : Cocody (données fictives).',
              ),
            ),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: FiltrePharmacie.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = FiltrePharmacie.values[i];
                final actif = f == _filtre;
                return ChoiceChip(
                  avatar: Icon(
                    f.icone,
                    size: 18,
                    color: actif ? Colors.white : AppColors.texteDoux,
                  ),
                  label: Text(f.libelle),
                  selected: actif,
                  showCheckmark: false,
                  selectedColor: AppColors.outremer,
                  backgroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  side: BorderSide(
                    color: actif ? AppColors.outremer : AppColors.bordure,
                  ),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: actif ? Colors.white : AppColors.texte,
                  ),
                  onSelected: (_) => setState(() => _filtre = f),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${pluriel(n, 'pharmacie')} trouvée${n > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: AppColors.texteDoux,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: n == 0
                ? EtatVide(onReinitialiser: _reinitialiser)
                : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      4,
                      20,
                      MediaQuery.paddingOf(context).bottom + 20,
                    ),
                    itemCount: n,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => Apparition(
                      key: ValueKey(resultats[i].id),
                      index: i,
                      child: CartePharmacie(
                        pharmacie: resultats[i],
                        heroTag: 'pharmacie-${resultats[i].id}',
                        onTap: () => Routes.versDetail(context, resultats[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Écran 3 ---
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.pharmacie});

  final Pharmacie pharmacie;

  static const _jours = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  // Presse-papiers en attendant url_launcher (appel / itinéraire réels).
  Future<void> _copier(
    BuildContext context,
    String texte,
    String message,
  ) async {
    await Clipboard.setData(ClipboardData(text: texte));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final p = pharmacie;
    final t = Theme.of(context).textTheme;
    final ouverte = p.estOuverte();
    final aujourdhui = DateTime.now().weekday - 1;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FondPeint(
              nuit: p.deGarde,
              rayon: 36,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BoutonRetour(),
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AvatarPharmacie(
                              taille: 66,
                              deGarde: p.deGarde,
                              surFonce: true,
                              heroTag: 'pharmacie-${p.id}',
                            ),
                            const SizedBox(height: 16),
                            Text(
                              p.nom,
                              style: AppText.serif.copyWith(
                                color: Colors.white,
                                fontSize: 27,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.place_rounded,
                                  size: 18,
                                  color: Colors.white.withAlpha(220),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${p.quartier}, ${p.commune}',
                                    style: t.bodyMedium?.copyWith(
                                      color: Colors.white.withAlpha(230),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Pastille(
                                  texte: ouverte ? 'Ouverte' : 'Fermée',
                                  couleur: Colors.white,
                                  icone: ouverte
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  surFonce: true,
                                ),
                                if (p.deGarde)
                                  const Pastille(
                                    texte: 'De garde',
                                    couleur: Colors.white,
                                    icone: Icons.nightlight_round,
                                    surFonce: true,
                                  ),
                                Pastille(
                                  texte: p.distanceLibelle,
                                  couleur: Colors.white,
                                  icone: Icons.near_me_rounded,
                                  surFonce: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              p.statutDetaille(),
                              style: t.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _copier(
                            context,
                            p.telephone,
                            'Numéro copié : ${p.telephone}',
                          ),
                          icon: const Icon(Icons.call_rounded),
                          label: const Text('Appeler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copier(
                            context,
                            p.adresseComplete,
                            'Adresse copiée pour l\'itinéraire',
                          ),
                          icon: const Icon(Icons.directions_rounded),
                          label: const Text('Itinéraire'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CarteSection(
                    titre: 'Coordonnées',
                    children: [
                      LigneInfo(
                        icone: Icons.place_rounded,
                        libelle: 'Adresse',
                        valeur: p.adresseComplete,
                        onCopier: () => _copier(
                          context,
                          p.adresseComplete,
                          'Adresse copiée',
                        ),
                      ),
                      const SizedBox(height: 14),
                      LigneInfo(
                        icone: Icons.phone_rounded,
                        libelle: 'Téléphone',
                        valeur: p.telephone,
                        onCopier: () =>
                            _copier(context, p.telephone, 'Numéro copié'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CarteSection(
                    titre: "Horaires d'ouverture",
                    children: [
                      for (var i = 0; i < _jours.length; i++)
                        _LigneHoraire(
                          jour: _jours[i],
                          horaire: p.horaires.libelle,
                          estAujourdhui: i == aujourdhui,
                        ),
                      if (p.deGarde && !p.horaires.h24) ...[
                        const SizedBox(height: 10),
                        const _BandeauInfo(
                          icone: Icons.nightlight_round,
                          texte:
                              'Assure la garde : ouverte en continu pendant '
                              'la période de garde.',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  CarteSection(
                    titre: 'À propos',
                    children: [
                      Text(
                        p.description,
                        style: t.bodyMedium?.copyWith(
                          color: AppColors.texteDoux,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LigneHoraire extends StatelessWidget {
  const _LigneHoraire({
    required this.jour,
    required this.horaire,
    required this.estAujourdhui,
  });

  final String jour;
  final String horaire;
  final bool estAujourdhui;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: estAujourdhui ? FontWeight.w800 : FontWeight.w500,
      color: estAujourdhui ? AppColors.outremer : AppColors.texte,
    );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: estAujourdhui ? AppColors.outremer.withAlpha(22) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(jour, style: style),
          if (estAujourdhui) ...[
            const SizedBox(width: 8),
            const Pastille(texte: "Aujourd'hui", couleur: AppColors.outremer),
          ],
          const Spacer(),
          Text(horaire, style: style),
        ],
      ),
    );
  }
}

// ============================================================================
// 7. WIDGETS RÉUTILISABLES
// ============================================================================

/// Petit badge arrondi (statut, distance, garde…).
class Pastille extends StatelessWidget {
  const Pastille({
    super.key,
    required this.texte,
    required this.couleur,
    this.icone,
    this.surFonce = false,
  });

  final String texte;
  final Color couleur;
  final IconData? icone;
  final bool surFonce; // true : à poser sur une peinture foncée

  @override
  Widget build(BuildContext context) {
    final fond = surFonce ? Colors.white.withAlpha(46) : couleur.withAlpha(30);
    final premierPlan = surFonce ? Colors.white : couleur;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 14, color: premierPlan),
            const SizedBox(width: 5),
          ],
          Text(
            texte,
            style: TextStyle(
              color: premierPlan,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton retour rond, lisible sur n'importe quelle peinture.
class BoutonRetour extends StatelessWidget {
  const BoutonRetour({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Retour',
      onPressed: () => Navigator.of(context).maybePop(),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withAlpha(46),
        foregroundColor: Colors.white,
        minimumSize: const Size(46, 46),
      ),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}

/// Apparition douce : seuls les premiers éléments d'une liste s'animent.
class Apparition extends StatelessWidget {
  const Apparition({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (index > 5) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Grande tuile d'action de l'accueil (nuit étoilée ou nymphéas).
class TuileAction extends StatelessWidget {
  const TuileAction({
    super.key,
    required this.nuit,
    required this.icone,
    required this.titre,
    required this.sousTitre,
    required this.onTap,
  });

  final bool nuit;
  final IconData icone;
  final String titre;
  final String sousTitre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$titre, $sousTitre',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: AppColors.ombre,
        ),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            height: 136,
            decoration: BoxDecoration(
              gradient: AppColors.degrade(
                nuit ? AppColors.nuit : AppColors.jour,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: nuit
                            ? const CielEtoile(lune: false)
                            : const Nympheas(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: nuit ? AppColors.soleil : Colors.white,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            icone,
                            size: 22,
                            color: nuit
                                ? AppColors.nuitProfonde
                                : AppColors.abysse,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          titre,
                          style: AppText.serif.copyWith(
                            color: Colors.white,
                            fontSize: 19,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sousTitre,
                          style: TextStyle(
                            color: Colors.white.withAlpha(230),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AvatarPharmacie extends StatelessWidget {
  const AvatarPharmacie({
    super.key,
    this.taille = 54,
    this.deGarde = false,
    this.surFonce = false,
    this.heroTag,
  });

  final double taille;
  final bool deGarde;
  final bool surFonce;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        color: surFonce ? (deGarde ? AppColors.soleil : Colors.white) : null,
        gradient: surFonce
            ? null
            : AppColors.degrade(deGarde ? AppColors.nuit : AppColors.jour),
        borderRadius: BorderRadius.circular(taille * 0.3),
      ),
      child: Icon(
        deGarde ? Icons.nightlight_round : Icons.local_pharmacy_rounded,
        size: taille * 0.5,
        color: surFonce
            ? (deGarde ? AppColors.nuitProfonde : AppColors.abysse)
            : (deGarde ? AppColors.soleil : Colors.white),
      ),
    );
    return heroTag == null ? avatar : Hero(tag: heroTag!, child: avatar);
  }
}

/// Carte pleine largeur (listes de résultats).
class CartePharmacie extends StatelessWidget {
  const CartePharmacie({
    super.key,
    required this.pharmacie,
    required this.onTap,
    this.heroTag,
  });

  final Pharmacie pharmacie;
  final VoidCallback onTap;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final p = pharmacie;
    final ouverte = p.estOuverte();

    return Semantics(
      button: true,
      label:
          '${p.nom}, ${p.commune}, ${ouverte ? 'ouverte' : 'fermée'}, '
          '${p.distanceLibelle}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.ombre,
        ),
        child: Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            // Cadre doré discret pour les pharmacies de garde.
            side: BorderSide(
              color: p.deGarde
                  ? AppColors.soleil.withAlpha(190)
                  : AppColors.bordure,
              width: p.deGarde ? 1.6 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AvatarPharmacie(deGarde: p.deGarde, heroTag: heroTag),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.serif.copyWith(fontSize: 17),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.quartier}, ${p.commune}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.texteDoux,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Pastille(
                              texte: ouverte ? 'Ouverte' : 'Fermée',
                              couleur: ouverte
                                  ? AppColors.ouvert
                                  : AppColors.ferme,
                              icone: ouverte
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                            ),
                            if (p.deGarde)
                              const Pastille(
                                texte: 'De garde',
                                couleur: AppColors.garde,
                                icone: Icons.nightlight_round,
                              ),
                            Pastille(
                              texte: p.distanceLibelle,
                              couleur: AppColors.texteDoux,
                              icone: Icons.near_me_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.texteDoux,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte « nuit étoilée » du carrousel horizontal des pharmacies de garde.
class CarteGarde extends StatelessWidget {
  const CarteGarde({super.key, required this.pharmacie, required this.onTap});

  final Pharmacie pharmacie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = pharmacie;

    return SizedBox(
      width: 256,
      child: Semantics(
        button: true,
        label: 'Garde : ${p.nom}, ${p.commune}, ${p.distanceLibelle}',
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: AppColors.ombre,
          ),
          child: Material(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(26),
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                gradient: AppColors.degrade(AppColors.nuit),
              ),
              child: InkWell(
                onTap: onTap,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(painter: CielEtoile(lune: false)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Pastille(
                                texte: 'De garde',
                                couleur: Colors.white,
                                icone: Icons.nightlight_round,
                                surFonce: true,
                              ),
                              const Spacer(),
                              Text(
                                p.distanceLibelle,
                                style: const TextStyle(
                                  color: AppColors.soleil,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            p.nom,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.serif.copyWith(
                              color: Colors.white,
                              fontSize: 19,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.commune,
                            style: TextStyle(
                              color: Colors.white.withAlpha(225),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_rounded,
                                size: 16,
                                color: AppColors.soleil,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                p.telephone,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChampRecherche extends StatelessWidget {
  const ChampRecherche({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330B1B4D),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Nom, commune ou quartier…',
          hintStyle: const TextStyle(color: AppColors.texteDoux),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.outremer,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, valeur, _) => valeur.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Effacer',
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.texteDoux,
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class TitreSection extends StatelessWidget {
  const TitreSection(this.titre, {super.key, this.actionLabel, this.onAction});

  final String titre;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(titre, style: AppText.serif.copyWith(fontSize: 21)),
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel ?? 'Voir tout'),
            ),
        ],
      ),
    );
  }
}

class CarteSection extends StatelessWidget {
  const CarteSection({super.key, required this.titre, required this.children});

  final String titre;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.bordure),
        boxShadow: AppColors.ombre,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: AppText.serif.copyWith(fontSize: 18)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class LigneInfo extends StatelessWidget {
  const LigneInfo({
    super.key,
    required this.icone,
    required this.libelle,
    required this.valeur,
    this.onCopier,
  });

  final IconData icone;
  final String libelle;
  final String valeur;
  final VoidCallback? onCopier;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.outremer.withAlpha(22),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icone, color: AppColors.outremer, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                libelle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.texteDoux,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valeur,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (onCopier != null)
          IconButton(
            tooltip: 'Copier',
            onPressed: onCopier,
            icon: const Icon(
              Icons.copy_rounded,
              size: 20,
              color: AppColors.texteDoux,
            ),
          ),
      ],
    );
  }
}

class _BandeauInfo extends StatelessWidget {
  const _BandeauInfo({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.outremer.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icone, size: 18, color: AppColors.outremer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texte,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.outremer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EtatVide extends StatelessWidget {
  const EtatVide({super.key, required this.onReinitialiser});

  final VoidCallback onReinitialiser;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppColors.degrade(AppColors.nuit),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 42,
                color: AppColors.soleil,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Aucune pharmacie trouvée',
              style: AppText.serif.copyWith(fontSize: 19),
            ),
            const SizedBox(height: 6),
            const Text(
              'Essayez un autre nom, une autre commune ou retirez les filtres.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.texteDoux),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onReinitialiser,
              child: const Text('Réinitialiser la recherche'),
            ),
          ],
        ),
      ),
    );
  }
}
