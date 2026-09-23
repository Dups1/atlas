import 'package:flutter/material.dart';

/// Sistema de diseño centralizado para temas (Claro y Oscuro) en Fixi
/// basado estrictamente en la paleta oficial de Facebook (Meta).
class TemaFixi {
  TemaFixi._();

  // ==========================================
  // PALETA OFICIAL FACEBOOK (META)
  // ==========================================

  // --- Acento de Marca ---
  static const Color azulFacebook = Color(0xFF0866FF); // Facebook Brand Blue (#0866FF)
  static const Color azulFacebookHover = Color(0xFF1877F2); // Secondary Blue
  static const Color azulFacebookDark = Color(0xFF2D88FF); // Vibrant Blue for Dark Mode

  // --- Facebook Modo Claro ---
  static const Color fbFondoClaro = Color(0xFFF0F2F5); // Facebook classic light gray canvas
  static const Color fbSuperficieClaro = Color(0xFFFFFFFF); // Pure white cards & navigation bars
  static const Color fbSecundarioClaro = Color(0xFFE4E6EB); // Facebook light input / pills / buttons
  static const Color fbBordeClaro = Color(0xFFCED0D4); // Facebook divider & border
  static const Color fbTextoClaro = Color(0xFF050505); // Facebook primary text (near black)
  static const Color fbSubtituloClaro = Color(0xFF65676B); // Facebook muted text / inactive icon

  // --- Facebook Modo Oscuro ---
  static const Color fbFondoOscuro = Color(0xFF18191A); // Facebook dark canvas
  static const Color fbSuperficieOscuro = Color(0xFF242526); // Facebook dark card & bar surface
  static const Color fbSecundarioOscuro = Color(0xFF3A3B3C); // Facebook dark input / pills / buttons
  static const Color fbBordeOscuro = Color(0xFF393A3B); // Facebook dark divider & border
  static const Color fbTextoOscuro = Color(0xFFE4E6EB); // Facebook dark primary text
  static const Color fbSubtituloOscuro = Color(0xFFB0B3B8); // Facebook dark muted text / inactive icon

  // ==========================================
  // GRADIENTES COMPATIBLES (Sutiles estilo Facebook)
  // ==========================================
  static const List<Color> gradienteClaro = [
    Color(0xFFF0F2F5),
    Color(0xFFF0F2F5),
  ];

  static const List<Color> gradienteOscuro = [
    Color(0xFF18191A),
    Color(0xFF18191A),
  ];

  // ==========================================
  // THEMEDATA MODO CLARO (Facebook Light)
  // ==========================================
  static final ThemeData temaClaro = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: azulFacebook,
      secondary: azulFacebookHover,
      surface: fbSuperficieClaro,
      onSurface: fbTextoClaro,
      onPrimary: Colors.white,
      secondaryContainer: fbSecundarioClaro,
      onSecondaryContainer: fbTextoClaro,
      surfaceContainerHighest: fbSecundarioClaro,
    ),
    scaffoldBackgroundColor: fbFondoClaro,
    canvasColor: fbFondoClaro,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: fbSuperficieClaro,
      surfaceTintColor: Colors.transparent,
      foregroundColor: fbTextoClaro,
      iconTheme: IconThemeData(color: fbTextoClaro),
      actionsIconTheme: IconThemeData(color: fbTextoClaro),
      titleTextStyle: TextStyle(
        color: fbTextoClaro,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      shape: Border(
        bottom: BorderSide(color: fbBordeClaro, width: 1),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: fbSuperficieClaro,
      selectedItemColor: azulFacebook,
      unselectedItemColor: fbSubtituloClaro,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      color: fbSuperficieClaro,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: fbBordeClaro, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: fbBordeClaro,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fbSecundarioClaro,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: fbBordeClaro),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: fbBordeClaro),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: azulFacebook, width: 1.8),
      ),
      hintStyle: const TextStyle(color: fbSubtituloClaro),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );

  // ==========================================
  // THEMEDATA MODO OSCURO (Facebook Dark)
  // ==========================================
  static final ThemeData temaOscuro = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: azulFacebookDark,
      secondary: azulFacebook,
      surface: fbSuperficieOscuro,
      onSurface: fbTextoOscuro,
      onPrimary: Colors.white,
      secondaryContainer: fbSecundarioOscuro,
      onSecondaryContainer: fbTextoOscuro,
      surfaceContainerHighest: fbSecundarioOscuro,
    ),
    scaffoldBackgroundColor: fbFondoOscuro,
    canvasColor: fbFondoOscuro,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: fbSuperficieOscuro,
      surfaceTintColor: Colors.transparent,
      foregroundColor: fbTextoOscuro,
      iconTheme: IconThemeData(color: fbTextoOscuro),
      actionsIconTheme: IconThemeData(color: fbTextoOscuro),
      titleTextStyle: TextStyle(
        color: fbTextoOscuro,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      shape: Border(
        bottom: BorderSide(color: fbBordeOscuro, width: 1),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: fbSuperficieOscuro,
      selectedItemColor: azulFacebookDark,
      unselectedItemColor: fbSubtituloOscuro,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      color: fbSuperficieOscuro,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: fbBordeOscuro, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: fbBordeOscuro,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fbSecundarioOscuro,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: fbBordeOscuro),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: fbBordeOscuro),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: azulFacebookDark, width: 1.8),
      ),
      hintStyle: const TextStyle(color: fbSubtituloOscuro),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );

  // ==========================================
  // HELPERS DINÁMICOS
  // ==========================================

  /// Determina si el contexto actual está en modo oscuro.
  static bool esOscuro(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Color de fondo general de página (Facebook feed background).
  static Color colorFondo(BuildContext context) {
    return esOscuro(context) ? fbFondoOscuro : fbFondoClaro;
  }

  /// Gradiente de fondo adaptativo para pantallas.
  static List<Color> gradienteFondo(BuildContext context) {
    return esOscuro(context) ? gradienteOscuro : gradienteClaro;
  }

  /// Color de la barra superior (AppBar).
  static Color colorBarraSuperior(BuildContext context) {
    return esOscuro(context) ? fbSuperficieOscuro : fbSuperficieClaro;
  }

  /// Color de la barra inferior (Bottom Bar).
  static Color colorBarraInferior(BuildContext context) {
    return esOscuro(context) ? fbSuperficieOscuro : fbSuperficieClaro;
  }

  /// Color de tarjetas y superficies elevadas.
  static Color colorTarjeta(BuildContext context) {
    return esOscuro(context) ? fbSuperficieOscuro : fbSuperficieClaro;
  }

  /// Color de tarjetas opacas/sólidas.
  static Color colorTarjetaSolida(BuildContext context) {
    return esOscuro(context) ? fbSuperficieOscuro : fbSuperficieClaro;
  }

  /// Color para elementos anidados, inputs o fondos secundarios (estilo pastillas Facebook).
  static Color colorSuperficieSecundaria(BuildContext context) {
    return esOscuro(context) ? fbSecundarioOscuro : fbSecundarioClaro;
  }

  /// Color de bordes y separadores (Facebook borders).
  static Color colorBorde(BuildContext context) {
    return esOscuro(context) ? fbBordeOscuro : fbBordeClaro;
  }

  /// Color para textos secundarios y etiquetas descriptivas.
  static Color colorSubtitulo(BuildContext context) {
    return esOscuro(context) ? fbSubtituloOscuro : fbSubtituloClaro;
  }

  /// Color para texto principal de títulos y cuerpo.
  static Color colorTextoPrincipal(BuildContext context) {
    return esOscuro(context) ? fbTextoOscuro : fbTextoClaro;
  }

  /// Color para sombras de elevación suaves.
  static Color colorSombra(BuildContext context) {
    return esOscuro(context)
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.06);
  }

  /// Genera una BoxDecoration estandarizada para tarjetas estilo Facebook.
  static BoxDecoration decoracionTarjeta(
    BuildContext context, {
    double radio = 16,
    bool conSombra = true,
    Border? borde,
    Color? colorFondo,
  }) {
    final dark = esOscuro(context);
    return BoxDecoration(
      color: colorFondo ?? (dark ? fbSuperficieOscuro : fbSuperficieClaro),
      borderRadius: BorderRadius.circular(radio),
      border: borde ?? Border.all(color: dark ? fbBordeOscuro : fbBordeClaro, width: 1),
      boxShadow: conSombra
          ? [
              BoxShadow(
                color: dark
                    ? Colors.black.withValues(alpha: 0.30)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ]
          : null,
    );
  }

  /// Genera la decoración para la barra inferior fija de navegación.
  static BoxDecoration decoracionBarraInferior(BuildContext context) {
    final dark = esOscuro(context);
    return BoxDecoration(
      color: dark ? fbSuperficieOscuro : fbSuperficieClaro,
      border: Border(
        top: BorderSide(color: dark ? fbBordeOscuro : fbBordeClaro, width: 1),
      ),
      boxShadow: [
        BoxShadow(
          color: dark
              ? Colors.black.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ],
    );
  }

  // ==========================================
  // ASSETS DE MARCA NEXO
  // ==========================================
  static const String logoNexoBlack = 'assets/images/nexo_black.png';
  static const String logoNexoWhite = 'assets/images/nexo_white.png';
  static const String logoNexoTransparente = 'assets/images/nexo_transparent.png';
  static const Color naranjaNexo = Color(0xFFF27C01);

  /// Genera el widget del logo de Nexo centrado para la barra superior (AppBar).
  /// Garantiza dimensiones idénticas al píxel en ambos temas (aspect ratio 955:319).
  static Widget logoAppBar(BuildContext context, {double height = 30}) {
    final dark = esOscuro(context);
    final double anchoCalculado = height * (955.0 / 319.0);
    return SizedBox(
      height: height,
      width: anchoCalculado,
      child: Image.asset(
        dark ? logoNexoBlack : logoNexoWhite,
        height: height,
        width: anchoCalculado,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(
            'Nexo',
            style: TextStyle(
              color: naranjaNexo,
              fontWeight: FontWeight.w900,
              fontSize: height * 0.75,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }
}
