import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/security/unlock_screen.dart';
import 'models/income_entry.dart';
import 'models/outcome_entry.dart';
import 'models/user.dart';
import 'models/entry_list_adapters.dart';
import 'models/security_settings.dart';
import 'services/auth_service.dart';
import 'services/security_service.dart';
import 'services/connectivity_service.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'services/notification_settings_service.dart';
import 'backup/utils/backup_scheduler.dart';
import 'backup/utils/notification_helper.dart';
import 'backup/services/backup_service.dart';

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

  static ThemeData get darkTheme {
    // Enhanced dark theme with better contrast and modern colors
    const primaryColor = Color(0xFF7C4DFF); // Vibrant purple
    const secondaryColor = Color(0xFF536DFE); // Bright indigo
    const surfaceColor = Color(0xFF1E1E2E); // Softer dark surface
    const backgroundColor = Color(0xFF181825); // Deep background
    const cardColor = Color(0xFF262637); // Elevated card color

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        surfaceContainer: cardColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        error: const Color(0xFFCF6679),
      ),
      scaffoldBackgroundColor: backgroundColor,

      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.white,
          fontFamily: 'Cairo',
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Cairo'),
        bodyMedium: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Cairo'),
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
        headlineMedium: TextStyle(
          color: primaryColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withAlpha((0.3 * 255).round()), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        isDense: true,
        fillColor: cardColor,
        filled: true,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withAlpha((0.5 * 255).round())),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black.withAlpha((0.4 * 255).round()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          elevation: 4,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
            primaryColor.withAlpha((0.2 * 255).round()),
          ),
          iconColor: WidgetStateProperty.all(primaryColor),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Cairo',
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: Colors.white54,
        indicatorColor: primaryColor,
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          fontFamily: 'Cairo',
        ),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withAlpha((0.12 * 255).round()),
        thickness: 1,
        space: 24,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withAlpha((0.5 * 255).round());
          }
          return Colors.grey.withAlpha((0.3 * 255).round());
        }),
      ),

      listTileTheme: ListTileThemeData(
        textColor: Colors.white,
        iconColor: Colors.white70,
        tileColor: cardColor,
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontFamily: 'Cairo',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

/// Migrate old income entries to add createdAt field
Future<void> _migrateIncomeEntries() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final migrationDone = prefs.getBool('income_createdAt_migration') ?? false;
    
    if (migrationDone) {
      return; // Migration already done
    }

    final incomeBox = await Hive.openBox<List<dynamic>>('income_entries');
    int migratedCount = 0;

    for (final key in incomeBox.keys) {
      final value = incomeBox.get(key);
      if (value is List) {
        bool modified = false;
        final updatedList = value.map((item) {
          if (item is IncomeEntry) {
            // إذا كان amount > 0 وليس له createdAt، استخدم date كـ createdAt
            if (item.amount > 0 && item.createdAt == null) {
              item.createdAt = item.date;
              modified = true;
              migratedCount++;
            }
          }
          return item;
        }).toList();
        
        if (modified) {
          await incomeBox.put(key, updatedList);
        }
      }
    }

    // Mark migration as done
    await prefs.setBool('income_createdAt_migration', true);
    
    if (kDebugMode) {
      print('✅ Migration completed: $migratedCount income entries updated');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Migration error: $e');
    }
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
  // SecuritySettings adapter for PIN/biometric (using typeId 5)
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(SecuritySettingsAdapter());
  }

  // Initialize backup scheduler and notifications for auto-backup functionality
  await BackupScheduler.initialize();
  await NotificationHelper().initialize();

  // Migrate old data to add createdAt field
  await _migrateIncomeEntries();

  runApp(const AlKhaznaApp());
}

class AlKhaznaApp extends StatefulWidget {
  const AlKhaznaApp({super.key});

  @override
  State<AlKhaznaApp> createState() => _AlKhaznaAppState();
}

class _AlKhaznaAppState extends State<AlKhaznaApp> with WidgetsBindingObserver {
  late SecurityService _securityService;
  late ThemeService _themeService;
  late LanguageService _languageService;
  late NotificationSettingsService _notificationSettingsService;

  // Track when app went to background
  DateTime? _pausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _securityService = SecurityService();
    _securityService.initialize();
    _themeService = ThemeService();
    _themeService.initialize();
    _languageService = LanguageService();
    _languageService.initialize();
    _notificationSettingsService = NotificationSettingsService();
    _notificationSettingsService.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Smart auto-lock logic
    if (state == AppLifecycleState.paused) {
      // App going to background - record timestamp
      _pausedTime = DateTime.now();
      debugPrint('📱 App paused at $_pausedTime');

      // Don't lock immediately - wait for resume
    } else if (state == AppLifecycleState.resumed) {
      // App resumed - check if should lock
      debugPrint('📱 App resumed');

      if (_pausedTime != null) {
        final shouldLock = _securityService.shouldLockOnResume(_pausedTime!);

        if (shouldLock) {
          _securityService.lockApp();
          debugPrint('🔒 App locked due to timeout');
        } else {
          debugPrint('✅ App stays unlocked (within grace period or session active)');
        }

        _pausedTime = null;
      }

      // Trigger rebuild to show unlock screen if needed
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()..initialize()),
        ChangeNotifierProvider(create: (context) => BackupService()),
        ChangeNotifierProvider.value(value: _securityService), // Security service
        ChangeNotifierProvider.value(value: _themeService), // Theme service
        ChangeNotifierProvider.value(value: _languageService), // Language service
        ChangeNotifierProvider.value(value: _notificationSettingsService), // Notification settings
      ],
      child: Consumer2<ThemeService, LanguageService>(
        builder: (context, themeService, languageService, child) {
          return MaterialApp(
            title: 'Al Khazna',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            home: const SecurityWrapper(), // Wrap with SecurityWrapper
            locale: languageService.locale,
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
        },
      ),
    );
  }
}

/// SecurityWrapper checks if app is locked
/// Shows UnlockScreen if locked, otherwise shows normal flow
class SecurityWrapper extends StatelessWidget {
  const SecurityWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityService>(
      builder: (context, securityService, child) {
        // If locked and PIN is enabled, show unlock screen
        if (securityService.isLocked && securityService.isPinEnabled) {
          return const UnlockScreen();
        }

        // Otherwise, show normal auth flow
        return const AuthWrapper();
      },
    );
  }
}

/// Authentication wrapper to handle routing based on auth state
/// Supports Offline-First approach - goes directly to HomeScreen when offline
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isCheckingConnectivity = true;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final isOnline = await _connectivityService.isOnline();
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
          _isCheckingConnectivity = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOnline = false;
          _isCheckingConnectivity = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final authState = authService.authState;
        
        // Show loading while checking connectivity or initializing auth
        if (_isCheckingConnectivity || authState.isLoading) {
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
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 16,
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
        
        // Offline-First: If no internet, go directly to HomeScreen
        if (!_isOnline) {
          return const HomeScreen();
        }
        
        // Online: Navigate based on authentication state
        if (authState.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
