import 'package:flutter/material.dart';
import 'package:telegram_drive/splash_screen.dart';
import 'package:telegram_drive/theme/theme.dart';

final themeController = ThemeController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await themeController.loadTheme();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    themeController.addListener(_themeListener);
  }

  @override
  void dispose() {
    themeController.removeListener(_themeListener);
    super.dispose();
  }

  void _themeListener() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeleDrive',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2AABEE),
          brightness: Brightness.light,
          primary: const Color(0xFF2AABEE),
          onPrimary: Colors.white,
          secondary: const Color(0xFF1D9BF0),
          onSecondary: Colors.white,
          tertiary: const Color(0xFF00A884),
          background: Colors.white,
          surface: Colors.white,
          surfaceTint: Colors.transparent,
          onBackground: const Color(0xFF424242),
          onSurface: const Color(0xFF424242),
        ),
        textTheme: const TextTheme(
          displayLarge:
              TextStyle(color: Color(0xFF303030), fontWeight: FontWeight.w600),
          displayMedium:
              TextStyle(color: Color(0xFF303030), fontWeight: FontWeight.w600),
          displaySmall:
              TextStyle(color: Color(0xFF303030), fontWeight: FontWeight.w600),
          headlineLarge:
              TextStyle(color: Color(0xFF303030), fontWeight: FontWeight.w600),
          headlineMedium:
              TextStyle(color: Color(0xFF303030), fontWeight: FontWeight.w600),
          headlineSmall:
              TextStyle(color: Color(0xFF303030), fontWeight: FontWeight.w600),
          titleLarge:
              TextStyle(color: Color(0xFF303030), fontWeight: FontWeight.w600),
          titleMedium:
              TextStyle(color: Color(0xFF424242), fontWeight: FontWeight.w500),
          titleSmall:
              TextStyle(color: Color(0xFF424242), fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: Color(0xFF424242)),
          bodyMedium: TextStyle(color: Color(0xFF424242)),
          bodySmall: TextStyle(color: Color(0xFF616161)),
          labelLarge:
              TextStyle(color: Color(0xFF424242), fontWeight: FontWeight.w500),
          labelMedium: TextStyle(color: Color(0xFF424242)),
          labelSmall: TextStyle(color: Color(0xFF616161)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2AABEE),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF2AABEE),
          foregroundColor: Colors.white,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2AABEE),
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2AABEE),
            side: const BorderSide(color: Color(0xFF2AABEE), width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2AABEE),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2AABEE), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        dividerColor: const Color(0xFFE0E0E0),
        scaffoldBackgroundColor: const Color(0xFFF9FAFC),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF2AABEE),
          unselectedItemColor: Color(0xFF9E9E9E),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2AABEE),
          brightness: Brightness.dark,
          primary: const Color(0xFF3D9EE4),
          onPrimary: Colors.white,
          secondary: const Color(0xFF2389D9),
          onSecondary: Colors.white,
          tertiary: const Color(0xFF00A884),
          background: const Color(0xFF121622),
          surface: const Color(0xFF1A1F35),
          surfaceTint: Colors.transparent,
          onBackground: const Color(0xFFE1E1E1),
          onSurface: const Color(0xFFE1E1E1),
        ),
        textTheme: const TextTheme(
          displayLarge:
              TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.w600),
          displayMedium:
              TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.w600),
          displaySmall:
              TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.w600),
          headlineLarge:
              TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.w600),
          headlineMedium:
              TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.w600),
          headlineSmall:
              TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.w600),
          titleLarge:
              TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.w600),
          titleMedium:
              TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.w500),
          titleSmall:
              TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
          bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
          bodySmall: TextStyle(color: Color(0xFFBDBDBD)),
          labelLarge:
              TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.w500),
          labelMedium: TextStyle(color: Color(0xFFE0E0E0)),
          labelSmall: TextStyle(color: Color(0xFFBDBDBD)),
        ),
        scaffoldBackgroundColor: const Color(0xFF121622),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1F35),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1A1F35),
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF3D9EE4),
          foregroundColor: Colors.white,
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3D9EE4),
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF3D9EE4),
            side: const BorderSide(color: Color(0xFF3D9EE4), width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3D9EE4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF242B45),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF3D9EE4), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
        ),
        dividerColor: const Color(0xFF2A3352),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1F35),
          selectedItemColor: Color(0xFF3D9EE4),
          unselectedItemColor: Color(0xFF9E9E9E),
        ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1A1F35)),
      ),
      themeMode: themeController.themeMode,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
