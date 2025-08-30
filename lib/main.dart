import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'models/income_entry.dart';
import 'models/outcome_entry.dart';
import 'models/entry_list_adapters.dart';
import 'services/enhanced_backup_service.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.indigo,
          fontFamily: 'Cairo',
        ),
        iconTheme: IconThemeData(color: Colors.indigo, size: 28),
      ),
      textTheme: const TextTheme(
        bodyLarge:
            TextStyle(color: Colors.black87, fontSize: 18, fontFamily: 'Cairo'),
        bodyMedium:
            TextStyle(color: Colors.black87, fontSize: 16, fontFamily: 'Cairo'),
        titleLarge: TextStyle(
            color: Colors.indigo,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo'),
        headlineMedium: TextStyle(
            color: Colors.indigo,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo'),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.indigo, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        isDense: true,
        fillColor: Colors.white,
        filled: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        shadowColor: Colors.indigo
            .withAlpha((0.08 * 255).round()), // Replaced withOpacity
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          elevation: 4,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
              Colors.indigo.shade50), // Replaced MaterialStateProperty
          iconColor: WidgetStateProperty.all(
              Colors.indigo), // Replaced MaterialStateProperty
          shape: WidgetStateProperty.all(RoundedRectangleBorder(
            // Replaced MaterialStateProperty
            borderRadius: BorderRadius.circular(30),
          )),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Colors.indigo,
        contentTextStyle:
            TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(30))),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.indigo,
        unselectedLabelColor: Colors.black54,
        indicatorColor: Colors.indigo,
        labelStyle: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo'),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.indigo,
        thickness: 1,
        space: 24,
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(IncomeEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(OutcomeEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(IncomeEntryListAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(OutcomeEntryListAdapter());
  }

  // Initialize Enhanced Backup Service
  await EnhancedBackupService().initialize();

  runApp(const AlKhaznaApp());
}

class AlKhaznaApp extends StatelessWidget {
  const AlKhaznaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al Khazna',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      navigatorKey: NavigationService.navigatorKey,
      locale: const Locale('en', ''),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''),
        Locale('en', ''),
      ],
    );
  }
}
