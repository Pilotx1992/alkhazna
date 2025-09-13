import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'models/income_entry.dart';
import 'models/outcome_entry.dart';
import 'models/user.dart';
import 'models/entry_list_adapters.dart';
import 'services/auth_service.dart';
import 'backup/utils/backup_scheduler.dart';
import 'backup/utils/notification_helper.dart';

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

  // Firebase removed - using Google Drive API directly for backup

  // Backup worker removed - using Drive backup service directly

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
  // User adapter for authentication (using typeId 4)
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(UserAdapter());
  }

  // Initialize backup scheduler and notifications for auto-backup functionality
  await BackupScheduler.initialize();
  await NotificationHelper().initialize();

  runApp(const AlKhaznaApp());
}

class AlKhaznaApp extends StatelessWidget {
  const AlKhaznaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService()..initialize(),
      child: MaterialApp(
        title: 'Al Khazna',
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
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
      ),
    );
  }
}

/// Authentication wrapper to handle routing based on auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final authState = authService.authState;
        
        // Show loading while initializing
        if (authState.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F9FA),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Color(0xFF2E7D32),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Al Khazna',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  SizedBox(height: 32),
                  CircularProgressIndicator(
                    color: Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Navigate based on authentication state
        if (authState.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
