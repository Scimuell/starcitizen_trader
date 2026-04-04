import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'db/app_db.dart';
import 'services/bootstrap.dart';
import 'ui/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  final db = await AppDatabase.open();
  await seedCatalogIfEmpty(db);
  runApp(StarcitizenTraderApp(db: db));
}

class StarcitizenTraderApp extends StatelessWidget {
  const StarcitizenTraderApp({super.key, required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StarMarket',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: HomeShell(db: db),
    );
  }

  ThemeData _buildTheme() {
    const background = Color(0xFF080C14);
    const surface = Color(0xFF0D1520);
    const surfaceVariant = Color(0xFF111D2E);
    const cyan = Color(0xFF00D4FF);
    const cyanDim = Color(0xFF0099BB);
    const onBackground = Color(0xFFCDD6E8);
    const onSurface = Color(0xFFB0BDD0);
    const border = Color(0xFF1E3048);

    final colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: cyan,
      onPrimary: background,
      secondary: cyanDim,
      onSecondary: background,
      surface: surface,
      onSurface: onBackground,
      surfaceContainerHighest: surfaceVariant,
      outline: border,
      error: const Color(0xFFFF4C6A),
      onError: Colors.white,
      secondaryContainer: const Color(0xFF0D2030),
      onSecondaryContainer: cyan,
      primaryContainer: const Color(0xFF0A2840),
      onPrimaryContainer: cyan,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: border,
      fontFamily: 'monospace',

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: onBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onBackground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
          fontFamily: 'monospace',
        ),
        iconTheme: IconThemeData(color: cyan),
        actionsIconTheme: IconThemeData(color: cyan),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: const Color(0xFF0A2840),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: cyan);
          }
          return const IconThemeData(color: onSurface);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: cyan, fontSize: 11, letterSpacing: 1);
          }
          return const TextStyle(color: onSurface, fontSize: 11, letterSpacing: 1);
        }),
      ),

      // ✅ FIXED
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),

      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        titleTextStyle: TextStyle(color: onBackground, fontSize: 14, fontFamily: 'monospace'),
        subtitleTextStyle: TextStyle(color: onSurface, fontSize: 12, fontFamily: 'monospace'),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        labelStyle: const TextStyle(color: onSurface, fontSize: 12, letterSpacing: 1),
        hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.5)),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: cyan, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: Color(0xFFFF4C6A)),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: Color(0xFFFF4C6A), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cyan,
          foregroundColor: background,
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            fontSize: 13,
          ),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cyan,
          side: const BorderSide(color: cyan),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            fontSize: 13,
          ),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cyan,
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            fontSize: 13,
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: cyan,
        foregroundColor: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
      ),

      // ✅ FIXED
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: border),
        ),
        titleTextStyle: const TextStyle(
          color: onBackground,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          fontFamily: 'monospace',
        ),
        contentTextStyle: const TextStyle(
          color: onSurface,
          fontSize: 13,
          fontFamily: 'monospace',
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: const TextStyle(color: onBackground, fontFamily: 'monospace', fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: border),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceVariant,
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: border),
          ),
        ),
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(color: onBackground, fontFamily: 'monospace', fontWeight: FontWeight.w700, letterSpacing: 1.5),
        titleMedium: TextStyle(color: onBackground, fontFamily: 'monospace', fontWeight: FontWeight.w600, letterSpacing: 1.5),
        titleSmall: TextStyle(color: onSurface, fontFamily: 'monospace', letterSpacing: 1),
        bodyLarge: TextStyle(color: onBackground, fontFamily: 'monospace'),
        bodyMedium: TextStyle(color: onBackground, fontFamily: 'monospace', fontSize: 13),
        bodySmall: TextStyle(color: onSurface, fontFamily: 'monospace', fontSize: 11),
        labelLarge: TextStyle(color: onBackground, fontFamily: 'monospace', letterSpacing: 1),
        labelMedium: TextStyle(color: onSurface, fontFamily: 'monospace', fontSize: 11, letterSpacing: 1),
        labelSmall: TextStyle(color: onSurface, fontFamily: 'monospace', fontSize: 10, letterSpacing: 1),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(color: cyan),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      iconTheme: const IconThemeData(color: onSurface),
    );
  }
}