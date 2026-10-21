import 'package:flutter/material.dart';

// ─── Colores (los mismos de siempre; ahora con nombre y ROL) ─────────────
const kFondo = Color(0xFF0E120C); // fondo de pantalla
const kSuperficie = Color(0xFF181E14); // tarjetas, hojas, secciones
const kBorde = Color(0xFF2A3222); // líneas y contornos
const kTexto = Color(0xFFF1F4EA); // texto principal
const kMuted = Color(0xFF8F9C80); // texto secundario
const kLima = Color(0xFFC8F54E); // acento: acción principal y "lo bueno"
const kIconoFondo = Color(0xFF37491C); // fondo de iconos y selección
const kPeligro = Color(0xFFFF8A80); // errores, excesos, borrar

// ─── S17-01: tokens de diseño ────────────────────────────────────────────
// Un sistema de diseño empieza por NOMBRAR las decisiones. Si cada pantalla
// escribe su propio `EdgeInsets.all(14)` y `circular(15)`, la app se ve
// "casi igual" en todas partes, que es peor que diferente.

/// Espaciado: múltiplos de 4. Nada de 10, 14 o 22 sueltos.
abstract final class Spacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Radios con JERARQUÍA: lo pequeño se redondea poco, lo grande más.
/// (No se llama `Radius`: ese nombre ya es una clase de Flutter.)
abstract final class Corners {
  static const control = 12.0; // campos, chips, botones
  static const card = 20.0; // tarjetas y secciones
  static const sheet = 28.0; // hojas inferiores
}

/// Una sola familia (Space Grotesk, incluida en assets/fonts con su licencia
/// OFL) con números tabulares: en una app de dinero las cifras se alinean.
const kFontFamily = 'SpaceGrotesk';
const kTabularFigures = [FontFeature.tabularFigures()];

ThemeData buildInkashTheme() {
  const scheme = ColorScheme.dark(
    primary: kLima,
    onPrimary: kFondo,
    secondary: kLima,
    onSecondary: kFondo,
    secondaryContainer: kIconoFondo,
    onSecondaryContainer: kLima,
    surface: kSuperficie,
    onSurface: kTexto,
    onSurfaceVariant: kMuted,
    error: kPeligro,
    outline: kBorde,
  );

  // Escala tipográfica: pocos tamaños, cada uno con un ROL.
  const text = TextTheme(
    displayLarge: TextStyle(
      fontSize: 52,
      fontWeight: FontWeight.w500,
      letterSpacing: -1.5,
      height: 1.05,
      fontFeatures: kTabularFigures,
    ), // la cifra principal del Inicio
    headlineSmall: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.5,
    ), // título de pestaña
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
    bodySmall: TextStyle(fontSize: 12, color: kMuted),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );

  final controlBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(Corners.control),
    borderSide: const BorderSide(color: kBorde),
  );

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: kFondo,
    fontFamily: kFontFamily,
    // apply() pinta TODO el cuerpo de kTexto; el texto secundario (bodySmall)
    // recupera su color después. (Lo detectó la revisión visual.)
    textTheme: text
        .apply(bodyColor: kTexto, displayColor: kTexto)
        .copyWith(bodySmall: text.bodySmall),
    appBarTheme: const AppBarTheme(
      backgroundColor: kFondo,
      foregroundColor: kTexto,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false, // títulos alineados a la izquierda, como las pestañas
      titleTextStyle: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: kTexto,
      ),
    ),
    // Campos: rellenos, con borde que se vuelve lima al enfocarse.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kFondo,
      contentPadding: const EdgeInsets.all(Spacing.l),
      labelStyle: const TextStyle(color: kMuted),
      hintStyle: const TextStyle(color: kMuted),
      helperStyle: const TextStyle(color: kMuted),
      border: controlBorder,
      enabledBorder: controlBorder,
      focusedBorder: controlBorder.copyWith(
        borderSide: const BorderSide(color: kLima, width: 2),
      ),
      errorBorder: controlBorder.copyWith(
        borderSide: const BorderSide(color: kPeligro),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: kLima,
        foregroundColor: kFondo,
        disabledBackgroundColor: kBorde,
        disabledForegroundColor: kMuted,
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.control),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kLima),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kLima,
        side: const BorderSide(color: kBorde),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.control),
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: kLima,
        selectedForegroundColor: kFondo,
        foregroundColor: kMuted,
        side: const BorderSide(color: kBorde),
        minimumSize: const Size(0, 48),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kSuperficie,
      selectedColor: kIconoFondo,
      side: const BorderSide(color: kBorde),
      showCheckmark: false,
      labelStyle: const TextStyle(fontFamily: kFontFamily, color: kTexto),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.control),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: kSuperficie,
      showDragHandle: true,
      dragHandleColor: kMuted,
      constraints: BoxConstraints(maxWidth: 640),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Corners.sheet),
        ),
      ),
    ),
    // Etiquetas de la barra en 11: "Presupuesto" cabe sin cortarse.
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kSuperficie,
      selectedItemColor: kLima,
      unselectedItemColor: kMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0, // sin sombra negra sobre la barra
      selectedLabelStyle: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(fontFamily: kFontFamily, fontSize: 11),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kLima,
      foregroundColor: kFondo,
      elevation: 0, // en fondo oscuro la sombra se ve como un aro negro
      highlightElevation: 0,
    ),
    // Filas: título en texto principal, subtítulo en secundario.
    listTileTheme: const ListTileThemeData(
      iconColor: kMuted,
      contentPadding: EdgeInsets.symmetric(horizontal: Spacing.l),
      titleTextStyle: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: kTexto,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 12,
        color: kMuted,
      ),
    ),
    dividerTheme: const DividerThemeData(color: kBorde, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kTexto,
      contentTextStyle: const TextStyle(fontFamily: kFontFamily, color: kFondo),
      actionTextColor: kIconoFondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.control),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: kLima,
      linearTrackColor: kBorde,
    ),
    cardTheme: CardThemeData(
      color: kSuperficie,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.card),
        side: const BorderSide(color: kBorde),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kSuperficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.card),
      ),
    ),
  );
}
