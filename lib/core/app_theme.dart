import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// The Prisha look: the logo's two colours, applied through Material 3.
///
/// The palette is taken from the company artwork in `assets/images/logo.png`
/// — a leaf green and a deep teal — rather than from the Medilab ProKit the
/// layout was modelled on. The kit gave us the card shapes and the spacing
/// rhythm; the colours are Prisha's own, and they are the same two the CRM
/// panel is painted in (`public/assets/css/prisha.css` over there), so the
/// three surfaces of the product look like one product.
///
/// Semantic names only below this line: a screen asks for `AppTheme.accent`
/// or a tile colour, never for "green", so re-tinting the app stays a change
/// to this file.
class AppTheme {
  AppTheme._();

  // --- Brand ---------------------------------------------------------------

  /// The logo's teal. Headers, primary actions, selected state.
  static const Color teal = Color(0xFF00797C);
  static const Color tealDark = Color(0xFF005F61);

  /// The logo's green. Confirmations, secondary accents.
  static const Color green = Color(0xFF6EAE40);
  static const Color greenDark = Color(0xFF5A9433);

  static const Color primary = teal;
  static const Color accent = green;

  /// The brand sweep, teal → green, in the pale form the app is built in:
  /// colour carries meaning here through icons, numbers and accents, and the
  /// large surfaces stay light so a screen read outdoors on a phone is calm
  /// rather than a slab of saturated colour.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFE6F4EF), Color(0xFFF1F8E6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// The same pale sweep left-to-right, for wide, short surfaces (app bars).
  static const LinearGradient barGradient = LinearGradient(
    colors: [Color(0xFFE9F5F0), Color(0xFFF2F9E9)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // --- Surfaces and text ---------------------------------------------------

  static const Color primaryLight = Color(0xFFEDF6F2);
  static const Color scaffold = Color(0xFFF6FAF8);
  static const Color surface = Colors.white;
  static const Color line = Color(0xFFE2ECE6);
  static const Color textPrimary = Color(0xFF1E2A32);
  static const Color textSecondary = Color(0xFF5E7079);
  static const Color shadow = Color(0x14174A3F);

  // --- Status --------------------------------------------------------------

  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE08A1E);
  static const Color danger = Color(0xFFD64535);
  static const Color info = Color(0xFF2A7FB8);

  // --- Tile accents --------------------------------------------------------

  /// The card palette. Six hues that sit beside the brand without fighting
  /// it; each tile picks one by meaning, never by position in a list.
  static const Color tileTeal = teal;
  static const Color tileGreen = Color(0xFF4E9B2E);
  static const Color tileBlue = Color(0xFF1B6CA8);
  static const Color tileAmber = Color(0xFFD98324);
  static const Color tileViolet = Color(0xFF5B4B9B);
  static const Color tileRose = Color(0xFFC0392B);

  /// A card in one of those hues: the pale wash, not the hue itself. The
  /// number on top is written in [ink] of the same hue, which is what makes
  /// the card readable while staying light.
  static LinearGradient tileGradient(Color base) => LinearGradient(
    colors: [
      Color.lerp(base, Colors.white, 0.90)!,
      Color.lerp(base, Colors.white, 0.80)!,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// The washed-out form of a hue, for a chip or an icon pad on white.
  static Color tint(Color base) => Color.lerp(base, Colors.white, 0.88)!;

  /// The hue darkened enough to read as text on its own [tint].
  static Color ink(Color base) => Color.lerp(base, Colors.black, 0.22)!;

  // --- Theme ---------------------------------------------------------------

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: teal,
        primary: teal,
        secondary: green,
        error: danger,
        surface: surface,
      ),
      scaffoldBackgroundColor: scaffold,
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme)
          .apply(bodyColor: textPrimary, displayColor: textPrimary),
      // Brand colour on a pale ground: BrandAppBar paints the gradient over
      // this, and a plain AppBar still comes out branded rather than grey.
      appBarTheme: AppBarTheme(
        backgroundColor: primaryLight,
        foregroundColor: tealDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: tealDark,
        ),
        iconTheme: const IconThemeData(color: teal),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _border(line),
        enabledBorder: _border(line),
        focusedBorder: _border(teal, width: 1.6),
        errorBorder: _border(danger),
        focusedErrorBorder: _border(danger, width: 1.6),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: teal,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: teal, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: teal),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      // A pale brand pill behind the selected tab with the glyph in teal on
      // it: the bar reads as part of the brand without going dark.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDCEFE6),
        elevation: 8,
        height: 68,
        shadowColor: shadow,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected) ? teal : textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? teal : textSecondary,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryLight,
        side: BorderSide.none,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: tealDark,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
      listTileTheme: const ListTileThemeData(iconColor: teal),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: teal),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
}
