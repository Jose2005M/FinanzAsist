import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class ColoresFinanzAsist {
  static const fondo = Color(0xFFFFF3D6);
  static const panel = Color(0xFFFFFAEC);
  static const tinta = Color(0xFF20211D);
  static const secundaria = Color(0xFF5D594F);
  static const dorado = Color(0xFFF0B400);
  static const foco = Color(0xFF89620B);
  static const borde = Color(0xFF706A5C);
  static const error = Color(0xFFAA3026);
  static const separador = Color(0xFFDBCFAD);
  static const seleccion = Color(0xFFFFE49A);
  static const deshabilitado = Color(0xFFE7D8A9);
  static const sombra = Color(0x146B4B14);
}

abstract final class TemaFinanzAsist {
  static const sistema = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: ColoresFinanzAsist.fondo,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static ThemeData crear() {
    final colores =
        ColorScheme.fromSeed(
          seedColor: ColoresFinanzAsist.dorado,
          brightness: Brightness.light,
        ).copyWith(
          primary: ColoresFinanzAsist.foco,
          onPrimary: Colors.white,
          primaryContainer: ColoresFinanzAsist.seleccion,
          onPrimaryContainer: ColoresFinanzAsist.tinta,
          secondary: ColoresFinanzAsist.foco,
          onSecondary: Colors.white,
          secondaryContainer: ColoresFinanzAsist.seleccion,
          onSecondaryContainer: ColoresFinanzAsist.tinta,
          surface: ColoresFinanzAsist.panel,
          onSurface: ColoresFinanzAsist.tinta,
          onSurfaceVariant: ColoresFinanzAsist.secundaria,
          surfaceContainerLowest: const Color(0xFFFFFCF5),
          surfaceContainerLow: ColoresFinanzAsist.panel,
          surfaceContainer: const Color(0xFFFFF7E2),
          surfaceContainerHigh: const Color(0xFFF7EDCF),
          surfaceContainerHighest: const Color(0xFFF0E4C0),
          surfaceTint: Colors.transparent,
          outline: ColoresFinanzAsist.borde,
          outlineVariant: ColoresFinanzAsist.separador,
          error: ColoresFinanzAsist.error,
          onError: Colors.white,
          errorContainer: const Color(0xFFFDE7E2),
          onErrorContainer: const Color(0xFF77221A),
          inverseSurface: ColoresFinanzAsist.tinta,
          onInverseSurface: ColoresFinanzAsist.panel,
        );
    final base = ThemeData(useMaterial3: true, colorScheme: colores);
    final textos = base.textTheme.apply(
      bodyColor: ColoresFinanzAsist.tinta,
      displayColor: ColoresFinanzAsist.tinta,
    );
    final redondeado = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );
    final contorno = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: ColoresFinanzAsist.borde,
        width: 1.25,
      ),
    );
    final estiloBoton = textos.labelLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
    return base.copyWith(
      scaffoldBackgroundColor: ColoresFinanzAsist.fondo,
      textTheme: textos.copyWith(
        headlineSmall: textos.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleLarge: textos.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: textos.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: textos.bodyMedium?.copyWith(height: 1.4),
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: ColoresFinanzAsist.fondo,
        foregroundColor: ColoresFinanzAsist.tinta,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: 20,
        titleTextStyle: textos.titleLarge?.copyWith(
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: sistema,
      ),
      cardTheme: CardThemeData(
        color: ColoresFinanzAsist.panel,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x336B4B14),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColoresFinanzAsist.panel,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(
          color: ColoresFinanzAsist.secundaria,
          fontSize: 16,
        ),
        floatingLabelStyle: const TextStyle(
          color: ColoresFinanzAsist.foco,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: ColoresFinanzAsist.secundaria,
          fontSize: 16,
        ),
        helperStyle: const TextStyle(
          color: ColoresFinanzAsist.secundaria,
          fontSize: 13,
        ),
        errorStyle: const TextStyle(
          color: ColoresFinanzAsist.error,
          fontSize: 13,
        ),
        helperMaxLines: 3,
        errorMaxLines: 3,
        prefixIconColor: ColoresFinanzAsist.secundaria,
        suffixIconColor: ColoresFinanzAsist.secundaria,
        border: contorno,
        enabledBorder: contorno,
        disabledBorder: contorno.copyWith(
          borderSide: const BorderSide(color: ColoresFinanzAsist.separador),
        ),
        focusedBorder: contorno.copyWith(
          borderSide: const BorderSide(
            color: ColoresFinanzAsist.foco,
            width: 2,
          ),
        ),
        errorBorder: contorno.copyWith(
          borderSide: const BorderSide(
            color: ColoresFinanzAsist.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: contorno.copyWith(
          borderSide: const BorderSide(
            color: ColoresFinanzAsist.error,
            width: 2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ColoresFinanzAsist.dorado,
          foregroundColor: ColoresFinanzAsist.tinta,
          disabledBackgroundColor: ColoresFinanzAsist.deshabilitado,
          disabledForegroundColor: ColoresFinanzAsist.secundaria,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: redondeado,
          textStyle: estiloBoton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColoresFinanzAsist.tinta,
          backgroundColor: ColoresFinanzAsist.panel,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: const BorderSide(color: ColoresFinanzAsist.borde),
          shape: redondeado,
          textStyle: estiloBoton,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColoresFinanzAsist.foco,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: redondeado,
          textStyle: estiloBoton,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(48),
          foregroundColor: ColoresFinanzAsist.tinta,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ColoresFinanzAsist.panel,
        surfaceTintColor: Colors.transparent,
        indicatorColor: ColoresFinanzAsist.dorado,
        elevation: 0,
        height: 80,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => textos.labelMedium?.copyWith(
            color: estados.contains(WidgetState.selected)
                ? ColoresFinanzAsist.tinta
                : ColoresFinanzAsist.secundaria,
            fontWeight: estados.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(
            color: estados.contains(WidgetState.selected)
                ? ColoresFinanzAsist.tinta
                : ColoresFinanzAsist.secundaria,
            size: 24,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: ColoresFinanzAsist.panel,
        selectedColor: ColoresFinanzAsist.seleccion,
        checkmarkColor: ColoresFinanzAsist.tinta,
        side: const BorderSide(color: ColoresFinanzAsist.separador),
        labelStyle: textos.labelLarge?.copyWith(
          color: ColoresFinanzAsist.tinta,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: ColoresFinanzAsist.panel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textos.bodyLarge,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColoresFinanzAsist.panel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textos.titleLarge,
        contentTextStyle: textos.bodyLarge,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: ColoresFinanzAsist.panel,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: ColoresFinanzAsist.panel,
        headerForegroundColor: ColoresFinanzAsist.tinta,
        dividerColor: ColoresFinanzAsist.separador,
        todayBorder: const BorderSide(color: ColoresFinanzAsist.foco),
        todayBackgroundColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? ColoresFinanzAsist.dorado
              : Colors.transparent,
        ),
        todayForegroundColor: const WidgetStatePropertyAll(
          ColoresFinanzAsist.tinta,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? ColoresFinanzAsist.dorado
              : null,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.disabled)
              ? ColoresFinanzAsist.secundaria
              : ColoresFinanzAsist.tinta,
        ),
        yearBackgroundColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? ColoresFinanzAsist.dorado
              : null,
        ),
        yearForegroundColor: const WidgetStatePropertyAll(
          ColoresFinanzAsist.tinta,
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: ColoresFinanzAsist.panel,
        collapsedBackgroundColor: ColoresFinanzAsist.panel,
        textColor: ColoresFinanzAsist.tinta,
        collapsedTextColor: ColoresFinanzAsist.tinta,
        iconColor: ColoresFinanzAsist.foco,
        collapsedIconColor: ColoresFinanzAsist.secundaria,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ColoresFinanzAsist.tinta,
        contentTextStyle: textos.bodyMedium?.copyWith(
          color: ColoresFinanzAsist.panel,
        ),
        actionTextColor: ColoresFinanzAsist.dorado,
        closeIconColor: ColoresFinanzAsist.panel,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(
        color: ColoresFinanzAsist.separador,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ColoresFinanzAsist.foco,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: ColoresFinanzAsist.foco,
        selectionColor: Color(0x66F0B400),
        selectionHandleColor: ColoresFinanzAsist.foco,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: ColoresFinanzAsist.foco,
        textColor: ColoresFinanzAsist.tinta,
        titleTextStyle: textos.titleMedium,
        subtitleTextStyle: textos.bodyMedium?.copyWith(
          color: ColoresFinanzAsist.secundaria,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }
}
