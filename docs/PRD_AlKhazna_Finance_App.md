# Product Requirements Document (PRD): Al Khazna Personal Finance App

## 1. Executive Summary

**Product Name:** Al Khazna (The Treasury)
**Version:** 3.0.0
**Platform:** Cross-platform mobile application (Android/iOS) with desktop support
**Primary Purpose:** Simple, elegant personal finance tracking app for monthly income and expense management

**Target Users:** Individuals seeking a straightforward, bilingual (Arabic/English) solution for tracking monthly financial activities without complex budgeting features.

## 2. Product Vision & Goals

### Vision Statement
Create an intuitive, culturally-aware personal finance app that simplifies monthly income and expense tracking for Arabic and English-speaking users.

### Primary Goals
- **Simplicity First:** Zero learning curve with immediate usability
- **Cultural Sensitivity:** Full Arabic language support with proper RTL text handling
- **Data Ownership:** Local-first approach with user-controlled backup/export
- **Privacy & Security:** Strong authentication with biometric support
- **Professional Reporting:** Clean, exportable financial reports

## 3. Core Features & Functionality

### 3.1 Authentication System
**Priority:** P0 (Critical)

**Requirements:**
- Firebase Authentication integration
- Google Sign-In support
- Email/password authentication
- Biometric authentication (fingerprint/face unlock)
- "Remember me" functionality
- Forgot password with email reset
- Secure session management

**User Stories:**
- As a user, I can sign up with email/password or Google account
- As a user, I can enable biometric login for quick access
- As a user, I can reset my password via email if forgotten
- As a user, I can stay logged in across app sessions

### 3.2 Home Dashboard
**Priority:** P0 (Critical)

**Requirements:**
- App branding with "Alkhazna" title
- Month/Year period selector (dropdowns, 48px height, grey background)
- "Month Details" navigation button (blue styling)
- Total Balance card with green gradient background
- Number formatting with comma separators
- Responsive design for various screen sizes
- Proper Material 3 theming

**User Stories:**
- As a user, I can select any month/year to view financial data
- As a user, I can see my total balance prominently displayed
- As a user, I can navigate to detailed month view

### 3.3 Income Management
**Priority:** P0 (Critical)

**Requirements:**
- Table-style data entry interface
- Reusable IncomeRow widget with:
  - Light blue background with rounded corners
  - Alternating row colors (lighter/darker blue)
  - Three columns: Amount (numeric, 4-char limit), Name (string), Index (row number)
  - TextFields styled as plain labels by default
  - Green border on focus/tap
  - Index column read-only, right-aligned
  - Amount text appears green if > 0, black otherwise
- Real-time auto-save functionality
- Swipe-to-delete with confirmation
- + Button for adding new entries
- Support for Arabic text input
- Empty state handling

**User Stories:**
- As a user, I can add multiple income sources for any month
- As a user, I can edit income entries inline by tapping fields
- As a user, I can delete income entries with swipe gesture
- As a user, I can see visual feedback when editing (green borders)
- As a user, I can enter Arabic names for income sources

### 3.4 Expense Management
**Priority:** P0 (Critical)

**Requirements:**
- Modern form-based input interface
- Date picker with calendar icon and proper formatting
- Description and Amount input fields (grey backgrounds, rounded corners)
- Red "Add Expense" button (50px height) with icon
- Card-based expense list display:
  - Rounded corners
  - Amount in red with comma formatting
  - Description text centered (Arabic text support)
  - Date in DD/MM format
  - Row number in red circle (right-aligned)
- Form validation (both description and amount required)
- Swipe-to-delete with confirmation dialog
- Real-time data persistence

**User Stories:**
- As a user, I can add expenses with date, description, and amount
- As a user, I can see expenses in an organized card layout
- As a user, I can delete expenses with swipe confirmation
- As a user, I receive validation feedback for incomplete entries

### 3.5 Data Export & Reporting
**Priority:** P1 (Important)

**Requirements:**
- PDF report generation with comprehensive formatting:
  - Professional Excel-style layout
  - Arabic text support (proper rendering without character issues)
  - Multiple pages: Income details, Expense details, Summary page
  - Income pages with light blue styling
  - Summary page with income/expenses totals and +/- indicators
  - Proper number formatting with comma separators
  - Month/year context in headers
- Data export functionality:
  - Custom .NOG file format (JSON-based)
  - Date-based filename: DD-MM-YYYY.NOG
  - Export current month data or all historical data
  - Cross-platform sharing support
- Graceful handling of desktop platforms (file location messaging)

**User Stories:**
- As a user, I can generate professional PDF reports of my financial data
- As a user, I can export my data in a portable format for backup
- As a user, I can share exported files through my device's sharing system
- As a user, I can see proper Arabic text in generated reports

### 3.6 Data Import & Management
**Priority:** P1 (Important)

**Requirements:**
- File picker integration (cross-platform compatibility)
- .NOG file format validation
- Import preview functionality:
  - Display file contents summary
  - Show entry counts (income/expenses)
  - Export date information
  - Month coverage details
- Import mode options:
  - Replace: Clear existing data and import
  - Integrate: Merge with existing data (no duplicates)
- Import confirmation dialog with clear explanations
- Error handling with user-friendly messages
- Success feedback and navigation

**User Stories:**
- As a user, I can import previously exported .NOG files
- As a user, I can preview import contents before applying changes
- As a user, I can choose whether to replace or merge imported data
- As a user, I receive clear feedback about import success/failure

### 3.7 Settings & Configuration
**Priority:** P2 (Nice to have)

**Requirements:**
- Biometric authentication toggle
- Account management options
- App preferences
- About/version information
- Sign out functionality

**User Stories:**
- As a user, I can configure authentication preferences
- As a user, I can manage my account settings
- As a user, I can safely sign out of the application

### 3.8 Data Persistence & Storage
**Priority:** P0 (Critical)

**Requirements:**
- Hive local database integration
- Monthly data organization (month_year keys)
- Clean data loading (no auto-generation)
- Reliable CRUD operations
- Data integrity validation
- Empty state handling
- Recovery mechanisms

**User Stories:**
- As a user, my data persists across app sessions
- As a user, I only see data I've actually entered
- As a user, my data remains consistent and recoverable

## 4. Technical Architecture

### 4.1 Platform & Framework
- **Framework:** Flutter 3.24+ with Dart SDK >=3.5.0
- **Flutter Channel:** Stable (recommended for production)
- **UI Design:** Material 3 design system with custom theming
- **State Management:** Multi-layered approach:
  - **Provider**: Global app state and services
  - **ChangeNotifier**: Screen-specific state management
  - **ValueNotifier**: Lightweight reactive state for widgets
  - **StateNotifier + Riverpod**: Consider for complex state scenarios
- **Architecture Pattern:** Clean Architecture with MVVM
- **Build Tools:**
  - Android: Gradle 8.0+ with Kotlin DSL
  - iOS: Xcode 15.0+ with Swift integration
  - Desktop: CMake integration for Windows/Linux

### 4.2 Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State Management & Architecture
  provider: ^6.1.0              # Primary state management
  get_it: ^7.6.0                # Dependency injection
  riverpod: ^2.4.0              # Consider for complex state
  flutter_riverpod: ^2.4.0      # Riverpod Flutter integration

  # Authentication & Security
  firebase_auth: ^4.15.0
  firebase_core: ^2.24.0
  google_sign_in: ^6.2.0
  local_auth: ^2.1.7            # Biometric authentication
  flutter_secure_storage: ^9.0.0
  crypto: ^3.0.3

  # Data Storage & Persistence
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2
  sqflite: ^2.3.0              # Fallback/migration option
  drift: ^2.14.0               # Consider for complex queries

  # File Operations
  path_provider: ^2.1.1
  file_picker: ^8.0.0
  share_plus: ^7.2.1
  open_file: ^3.3.2            # File opening support

  # PDF & Reporting
  pdf: ^3.10.7
  printing: ^5.12.0
  flutter_pdfview: ^1.3.2      # PDF viewing capability

  # Internationalization & RTL
  intl: ^0.19.0
  flutter_bidi: ^0.3.0         # BiDi text support
  arabic_numbers: ^2.0.1       # Arabic numeral handling

  # UI Components & Material 3
  material_color_utilities: ^0.8.0  # Material 3 color system
  dynamic_color: ^1.7.0             # Dynamic theming
  cupertino_icons: ^1.0.6
  flutter_svg: ^2.0.9               # SVG icon support
  cached_network_image: ^3.3.1     # Image caching

  # Animations & Visual Effects
  flutter_staggered_animations: ^1.1.1
  shimmer: ^3.0.0
  lottie: ^3.0.0               # Advanced animations
  confetti: ^0.7.0

  # Form Handling & Validation
  reactive_forms: ^16.1.1      # Advanced form management
  validators: ^3.0.0
  mask_text_input_formatter: ^2.9.0

  # Background Processing & Notifications
  workmanager: ^0.5.2
  flutter_local_notifications: ^17.0.0

  # Network & Connectivity
  dio: ^5.4.0                  # HTTP client
  connectivity_plus: ^5.0.2
  internet_connection_checker: ^1.0.0

  # Device & Platform
  device_info_plus: ^10.1.0
  package_info_plus: ^6.0.0
  permission_handler: ^11.2.0
  app_settings: ^5.1.1         # Deep link to settings

  # Utilities
  uuid: ^4.3.3
  collection: ^1.18.0          # Enhanced collections
  equatable: ^2.0.5           # Value equality
  freezed_annotation: ^2.4.1  # Code generation
  json_annotation: ^4.8.1     # JSON serialization

  # Development & Debugging
  logger: ^2.0.2              # Structured logging
  flutter_launcher_icons: ^0.13.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.7
  hive_generator: ^2.0.1
  json_serializable: ^6.7.1
  freezed: ^2.4.7

  # Testing
  mockito: ^5.4.4
  mocktail: ^1.0.3
  patrol: ^3.6.1              # Advanced integration testing
  golden_toolkit: ^0.15.0     # Golden file testing

  # Code Quality
  flutter_lints: ^3.0.0
  very_good_analysis: ^5.1.0   # Enhanced linting
  import_sorter: ^4.6.0       # Import organization

  # Performance & Monitoring
  sentry_flutter: ^7.15.0     # Crash reporting
  firebase_crashlytics: ^3.4.0
  firebase_analytics: ^10.7.0
  firebase_performance: ^0.9.3
```

### 4.3 Data Models

**Enhanced IncomeEntry with Validation:**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'income_entry.freezed.dart';
part 'income_entry.g.dart';

@freezed
@HiveType(typeId: 0)
class IncomeEntry extends HiveObject with _$IncomeEntry {
  @HiveField(0)
  const factory IncomeEntry({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required double amount,
    @HiveField(3) required DateTime date,
    @HiveField(4) @Default('') String description,
    @HiveField(5) @Default('') String category,
    @HiveField(6) required DateTime createdAt,
    @HiveField(7) required DateTime updatedAt,
    @HiveField(8) @Default(false) bool isRecurring,
    @HiveField(9) @Default({}) Map<String, dynamic> metadata,
  }) = _IncomeEntry;

  factory IncomeEntry.fromJson(Map<String, dynamic> json) =>
      _$IncomeEntryFromJson(json);

  // Business logic methods
  bool get isValid => name.isNotEmpty && amount > 0;
  String get formattedAmount => NumberFormat('#,##0.00').format(amount);
  String get monthYear => DateFormat('yyyy-MM').format(date);
}
```

**Enhanced OutcomeEntry with Validation:**
```dart
@freezed
@HiveType(typeId: 1)
class OutcomeEntry extends HiveObject with _$OutcomeEntry {
  const factory OutcomeEntry({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required double amount,
    @HiveField(3) required DateTime date,
    @HiveField(4) @Default('') String description,
    @HiveField(5) @Default('general') String category,
    @HiveField(6) required DateTime createdAt,
    @HiveField(7) required DateTime updatedAt,
    @HiveField(8) @Default(false) bool isRecurring,
    @HiveField(9) @Default({}) Map<String, dynamic> metadata,
    @HiveField(10) String? receiptPath,
  }) = _OutcomeEntry;

  factory OutcomeEntry.fromJson(Map<String, dynamic> json) =>
      _$OutcomeEntryFromJson(json);

  bool get isValid => name.isNotEmpty && amount > 0;
  String get formattedAmount => NumberFormat('#,##0.00').format(amount);
  String get monthYear => DateFormat('yyyy-MM').format(date);
  bool get hasReceipt => receiptPath?.isNotEmpty ?? false;
}
```

**Monthly Summary Model:**
```dart
@freezed
@HiveType(typeId: 2)
class MonthlySummary with _$MonthlySummary {
  const factory MonthlySummary({
    @HiveField(0) required String monthYear,
    @HiveField(1) required double totalIncome,
    @HiveField(2) required double totalExpenses,
    @HiveField(3) required int incomeCount,
    @HiveField(4) required int expenseCount,
    @HiveField(5) required DateTime lastUpdated,
    @HiveField(6) @Default({}) Map<String, double> categoryTotals,
  }) = _MonthlySummary;

  factory MonthlySummary.fromJson(Map<String, dynamic> json) =>
      _$MonthlySummaryFromJson(json);

  double get balance => totalIncome - totalExpenses;
  bool get isPositive => balance >= 0;
  String get formattedBalance => NumberFormat('#,##0.00').format(balance);
}
```

### 4.4 Service Architecture

**Core Services:**
1. **AuthService:** Firebase authentication with session management
2. **StorageService:** Hive database with migration support
3. **PDFService:** Report generation with Arabic BiDi support
4. **DataSharingService:** Export/import with validation
5. **EmailService:** Password reset and notifications
6. **CacheService:** In-memory caching for performance
7. **ValidationService:** Centralized data validation
8. **LocalizationService:** RTL/LTR and translation management
9. **ThemeService:** Dynamic theme switching
10. **SecurityService:** Data encryption and biometric handling

**Architecture Patterns:**
- **Repository Pattern**: Data access abstraction layer
- **Service Layer**: Business logic separation
- **Dependency Injection**: GetIt or Provider-based DI container
- **Observer Pattern**: Reactive state updates
- **Command Pattern**: Action handling with undo/redo support
- **Factory Pattern**: Widget and service instantiation

**Service Characteristics:**
- Single responsibility with clear interfaces
- Comprehensive error handling with typed exceptions
- Async/await with proper cancellation support
- Extensive logging with different log levels
- Unit testable with mockable dependencies
- Memory leak prevention with proper disposal

### 4.5 Enhanced Project Structure
```
lib/
├── main.dart                     # App entry point with DI setup
├── app.dart                      # App configuration and routing
├── bootstrap.dart                # App initialization
│
├── core/                         # Core infrastructure
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── api_constants.dart
│   │   └── storage_constants.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   ├── failures.dart
│   │   └── error_handler.dart
│   ├── network/
│   │   ├── network_info.dart
│   │   └── dio_client.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── color_schemes.dart
│   │   └── text_themes.dart
│   └── utils/
│       ├── logger.dart
│       ├── extensions.dart
│       └── helpers.dart
│
├── data/                         # Data layer
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── hive_datasource.dart
│   │   │   └── secure_storage_datasource.dart
│   │   └── remote/
│   │       └── firebase_datasource.dart
│   ├── models/                   # Data models with adapters
│   │   ├── income_entry.dart
│   │   ├── outcome_entry.dart
│   │   ├── monthly_summary.dart
│   │   └── user_preferences.dart
│   └── repositories/             # Repository implementations
│       ├── finance_repository_impl.dart
│       ├── auth_repository_impl.dart
│       └── preferences_repository_impl.dart
│
├── domain/                       # Business logic layer
│   ├── entities/                 # Business entities
│   │   ├── financial_entry.dart
│   │   ├── user.dart
│   │   └── app_settings.dart
│   ├── repositories/             # Abstract repositories
│   │   ├── finance_repository.dart
│   │   ├── auth_repository.dart
│   │   └── preferences_repository.dart
│   └── usecases/                 # Use cases
│       ├── auth/
│       │   ├── login_usecase.dart
│       │   ├── logout_usecase.dart
│       │   └── biometric_auth_usecase.dart
│       ├── finance/
│       │   ├── add_income_usecase.dart
│       │   ├── add_expense_usecase.dart
│       │   ├── get_monthly_data_usecase.dart
│       │   └── export_data_usecase.dart
│       └── base_usecase.dart
│
├── presentation/                  # UI layer
│   ├── providers/                # State management
│   │   ├── auth_provider.dart
│   │   ├── finance_provider.dart
│   │   ├── theme_provider.dart
│   │   └── locale_provider.dart
│   ├── screens/                  # Screen widgets
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   └── biometric_setup_screen.dart
│   │   ├── finance/
│   │   │   ├── home_screen.dart
│   │   │   ├── income_screen.dart
│   │   │   ├── outcome_screen.dart
│   │   │   ├── balance_screen.dart
│   │   │   └── analytics_screen.dart
│   │   ├── settings/
│   │   │   ├── settings_screen.dart
│   │   │   ├── preferences_screen.dart
│   │   │   └── about_screen.dart
│   │   └── import_export/
│   │       ├── import_screen.dart
│   │       └── export_screen.dart
│   ├── widgets/                  # Reusable UI components
│   │   ├── common/
│   │   │   ├── app_button.dart
│   │   │   ├── app_text_field.dart
│   │   │   ├── loading_widget.dart
│   │   │   └── error_widget.dart
│   │   ├── finance/
│   │   │   ├── income_row.dart
│   │   │   ├── expense_card.dart
│   │   │   ├── balance_card.dart
│   │   │   └── chart_widgets.dart
│   │   └── forms/
│   │       ├── finance_form.dart
│   │       └── validation_widgets.dart
│   └── routing/
│       ├── app_router.dart
│       ├── route_names.dart
│       └── route_guards.dart
│
├── services/                     # Application services
│   ├── auth_service.dart
│   ├── storage_service.dart
│   ├── pdf_service.dart
│   ├── data_sharing_service.dart
│   ├── localization_service.dart
│   ├── theme_service.dart
│   ├── security_service.dart
│   └── cache_service.dart
│
├── l10n/                         # Localization
│   ├── app_localizations.dart
│   ├── app_en.arb
│   └── app_ar.arb
│
└── generated/                    # Generated code
    ├── *.g.dart                 # Hive adapters
    ├── *.freezed.dart           # Freezed models
    └── l10n/                    # Generated localizations
```

## 5. Enhanced UI/UX Requirements

### 5.1 Material 3 Design System Implementation

**Color System with Dynamic Theming:**
```dart
class AppColorScheme {
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2196F3),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD4E7FF),
    onPrimaryContainer: Color(0xFF001C3B),
    secondary: Color(0xFF4CAF50),
    onSecondary: Color(0xFFFFFFFF),
    error: Color(0xFFF44336),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFBFE),
    onSurface: Color(0xFF1C1B1F),
    surfaceVariant: Color(0xFFE7E0EC),
    outline: Color(0xFF79747E),
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF9ECAFF),
    onPrimary: Color(0xFF003258),
    primaryContainer: Color(0xFF00497D),
    onPrimaryContainer: Color(0xFFD4E7FF),
    secondary: Color(0xFF81C784),
    onSecondary: Color(0xFF003911),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: Color(0xFF1C1B1F),
    onSurface: Color(0xFFE6E1E5),
    surfaceVariant: Color(0xFF49454F),
    outline: Color(0xFF938F99),
  );
}
```

**Component Theming:**
```dart
class AppTheme {
  static ThemeData getTheme({
    required ColorScheme colorScheme,
    required String locale,
  }) {
    final isRTL = locale.startsWith('ar');

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Card theming for expense/income cards
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Input decoration for forms
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
      ),

      // Button theming
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
```

### 5.2 Enhanced Typography & Arabic Support

**Multi-Script Typography System:**
```dart
class AppTextTheme {
  static TextTheme getTextTheme(String locale) {
    final fontFamily = locale.startsWith('ar') ? 'NotoSansArabic' : 'Roboto';

    return TextTheme(
      displayLarge: GoogleFonts.getFont(
        fontFamily,
        fontSize: 57,
        fontWeight: FontWeight.w400,
        height: 1.12,
        letterSpacing: -0.25,
      ),
      headlineMedium: GoogleFonts.getFont(
        fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 1.29,
      ),
      titleLarge: GoogleFonts.getFont(
        fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.27,
      ),
      bodyLarge: GoogleFonts.getFont(
        fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.5,
      ),
      labelLarge: GoogleFonts.getFont(
        fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.1,
      ),
    );
  }
}
```

**Arabic Number Formatting:**
```dart
class NumberFormatter {
  static String formatCurrency(double amount, String locale) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: '', // No symbol, add manually for RTL support
      decimalDigits: 2,
    );

    String formatted = formatter.format(amount);

    // Convert to Arabic numerals if needed
    if (locale.startsWith('ar')) {
      formatted = _convertToArabicNumerals(formatted);
    }

    return formatted;
  }

  static String _convertToArabicNumerals(String input) {
    const english = '0123456789';
    const arabic = '٠١٢٣٤٥٦٧٨٩';

    String result = input;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }
}
```

### 5.3 Advanced Responsive Design

**Breakpoint System:**
```dart
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 840;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }
}
```

**Responsive Layout Components:**
```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.desktop) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= Breakpoints.mobile) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
```

### 5.4 Enhanced Accessibility Implementation

**WCAG 2.1 AA Compliance:**
```dart
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String semanticLabel;
  final VoidCallback? onTap;

  const AccessibleCard({
    Key? key,
    required this.child,
    required this.semanticLabel,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: BoxConstraints(minHeight: 48), // Minimum touch target
            padding: EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

**Screen Reader Support:**
```dart
class FinancialSummaryCard extends StatelessWidget {
  final double income;
  final double expenses;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: l10n.financialSummaryLabel(
        NumberFormatter.formatCurrency(income, l10n.localeName),
        NumberFormatter.formatCurrency(expenses, l10n.localeName),
        NumberFormatter.formatCurrency(balance, l10n.localeName),
      ),
      readOnly: true,
      child: Card(
        child: Column(
          children: [
            _buildRow(l10n.income, income, Colors.green),
            _buildRow(l10n.expenses, expenses, Colors.red),
            _buildRow(l10n.balance, balance,
                     balance >= 0 ? Colors.green : Colors.red),
          ],
        ),
      ),
    );
  }
}
```

**High Contrast & Large Text Support:**
```dart
class ThemedText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);

    // Adjust text size based on system settings
    final adjustedStyle = (style ?? theme.textTheme.bodyLarge!).copyWith(
      fontSize: (style?.fontSize ?? 16) * mediaQuery.textScaleFactor.clamp(0.8, 2.0),
    );

    // High contrast mode adjustments
    if (mediaQuery.highContrast) {
      return Container(
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline,
            width: 0.5,
          ),
        ),
        child: Text(text, style: adjustedStyle),
      );
    }

    return Text(text, style: adjustedStyle);
  }
}
```

## 6. Data Security & Privacy

### 6.1 Authentication Security
- Firebase Authentication with industry-standard security
- Biometric authentication integration
- Secure session management
- Automatic logout on security events
- Password complexity requirements

### 6.2 Data Protection
- Local-first data storage approach
- Encrypted secure storage for sensitive data
- No cloud storage of financial data without explicit user consent
- User-controlled export/backup functionality
- GDPR-compliant data handling

### 6.3 File Security
- Custom .NOG file format with validation
- File integrity checks on import
- Secure file sharing through system APIs
- No temporary file retention

## 7. Quality Assurance Requirements

### 7.1 Testing Strategy
- Unit tests for business logic services
- Widget tests for UI components
- Integration tests for critical user flows
- Platform testing (Android/iOS/Desktop)
- Arabic text rendering verification
- Performance testing with large datasets

### 7.2 Error Handling
- Graceful degradation on service failures
- User-friendly error messages
- Recovery mechanisms for data corruption
- Offline functionality with sync capabilities
- Crash reporting and analytics

### 7.3 Performance Requirements & Optimization

**Performance Targets:**
- App launch time: <2 seconds cold start, <500ms warm start
- Screen transitions: <200ms animation duration
- Data loading: <500ms for monthly data
- PDF generation: <3 seconds for comprehensive reports
- Memory usage: <80MB for typical usage
- Frame rate: 60 FPS consistently, 120 FPS on supported devices

**Flutter Performance Optimizations:**

**1. Build Optimizations:**
```dart
// Use const constructors extensively
const AppTitle('Al Khazna');

// Implement efficient list building
ListView.builder(
  itemCount: entries.length,
  itemBuilder: (context, index) => EntryCard(entries[index]),
);

// Use RepaintBoundary for complex widgets
RepaintBoundary(
  child: ComplexChart(data: chartData),
);
```

**2. State Management Performance:**
```dart
// Use ValueNotifier for simple reactive state
ValueNotifier<double> balance = ValueNotifier(0.0);

// Implement Selector for targeted rebuilds
Selector<FinanceProvider, double>(
  selector: (_, provider) => provider.totalBalance,
  builder: (_, balance, __) => BalanceCard(balance),
);

// Use ChangeNotifierProxyProvider for derived state
ChangeNotifierProxyProvider<AuthProvider, FinanceProvider>(
  create: (_) => FinanceProvider(),
  update: (_, auth, finance) => finance..updateUser(auth.user),
);
```

**3. Memory Management:**
```dart
// Proper disposal in StatefulWidgets
@override
void dispose() {
  _controller.dispose();
  _subscription.cancel();
  super.dispose();
}

// Use weak references for large objects
final WeakReference<List<Entry>> _entriesRef = WeakReference(entries);
```

**4. Asset & Image Optimization:**
- Vector graphics (SVG) for icons and illustrations
- Optimized PNG/WebP images with appropriate resolutions
- Asset bundling with flutter_launcher_icons
- Lazy loading for large datasets

**5. Database Performance:**
```dart
// Hive box optimization
class StorageService {
  static const String _entriesBox = 'entries';

  // Use lazy boxes for large datasets
  static late LazyBox<IncomeEntry> _incomeBox;

  // Batch operations
  Future<void> saveMultipleEntries(List<Entry> entries) async {
    await _box.putAll({
      for (final entry in entries) entry.id: entry
    });
  }
}
```

**6. Rendering Optimizations:**
```dart
// Use AutomaticKeepAliveClientMixin for expensive widgets
class ExpensiveWidget extends StatefulWidget {
  @override
  _ExpensiveWidgetState createState() => _ExpensiveWidgetState();
}

class _ExpensiveWidgetState extends State<ExpensiveWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
}
```

**7. Network & Background Optimization:**
```dart
// Use Isolates for heavy computations
static Future<PDFDocument> generatePDFInBackground(
  List<Entry> entries,
) async {
  return await compute(_generatePDF, entries);
}

// Implement request debouncing
Timer? _debounceTimer;
void _onSearchChanged(String query) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 300), () {
    _performSearch(query);
  });
}
```

## 8. Deployment & Distribution

### 8.1 Platform Requirements
- **Android:** API level 21+ (Android 5.0+)
- **iOS:** iOS 12.0+
- **Desktop:** Windows 10+, macOS 10.14+, Linux (Ubuntu 18.04+)

### 8.2 Enhanced Build Configuration

**Release Build Optimization:**
```yaml
# android/app/build.gradle
android {
  compileSdkVersion 34

  buildTypes {
    release {
      shrinkResources true
      minifyEnabled true
      proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
      signingConfig signingConfigs.release

      // Optimize APK size
      ndk {
        abiFilters 'arm64-v8a', 'armeabi-v7a', 'x86_64'
      }
    }
  }

  // Enable R8 full mode
  buildFeatures {
    shrinkResources true
  }
}
```

**Flutter Build Commands:**
```bash
# Android optimized builds
flutter build apk --release --shrink --obfuscate --split-debug-info=./debug-info
flutter build appbundle --release --obfuscate --split-debug-info=./debug-info

# iOS optimized builds
flutter build ipa --release --obfuscate --split-debug-info=./debug-info

# Desktop builds
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

**APK/Bundle Optimization:**
- Target multiple architectures with app bundles
- Use vector drawables instead of multiple PNG densities
- Enable ProGuard/R8 for code shrinking
- Split debug info for crash symbolication
- Compress assets and resources

**Signing Configuration:**
```properties
# android/key.properties
storePassword=<store-password>
keyPassword=<key-password>
keyAlias=<key-alias>
storeFile=<path-to-keystore>
```

**Build Flavors:**
```yaml
# Multiple environments support
flavors:
  development:
    applicationId: "com.alkhazna.dev"
  staging:
    applicationId: "com.alkhazna.staging"
  production:
    applicationId: "com.alkhazna"
```

### 8.3 Store Presence
- Professional app store listings
- Localized descriptions (Arabic/English)
- High-quality screenshots showcasing features
- Privacy policy and terms of service
- Regular update schedule

## 9. Success Metrics

### 9.1 User Engagement
- Daily/Monthly Active Users
- Session duration and frequency
- Feature adoption rates
- User retention (Day 1, 7, 30)

### 9.2 Functional Metrics
- Data export/import success rates
- PDF generation completion rates
- Authentication success rates
- Crash-free session percentage

### 9.3 Performance Metrics
- App store ratings and reviews
- Bug report frequency
- Support ticket volume
- Feature request patterns

## 10. Future Roadmap

### Phase 1: Core MVP (Months 1-3)
- Basic authentication and data entry
- Income/expense tracking
- Simple reporting
- Local data storage

### Phase 2: Enhanced Features (Months 4-6)
- Advanced PDF reporting
- Data import/export
- Biometric authentication
- UI polish and animations

### Phase 3: Advanced Features (Months 7-12)
- Multi-currency support
- Category management
- Advanced analytics
- Cloud sync (optional)
- Budgeting features

## 11. Implementation Notes

### 11.1 Enhanced PDF Service with Arabic BiDi Support

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_bidi/flutter_bidi.dart';
import 'package:intl/intl.dart';

class PDFService {
  static Future<pw.Document> generateFinancialReport({
    required List<IncomeEntry> incomes,
    required List<OutcomeEntry> expenses,
    required String monthYear,
    required String locale,
  }) async {
    final pdf = pw.Document();
    final isRTL = locale.startsWith('ar');
    final font = await _loadArabicFont();

    // Summary page
    pdf.addPage(
      pw.MultiPage(
        textDirection: isRTL ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: font,
        ),
        build: (context) => [
          _buildHeader(monthYear, locale, isRTL),
          pw.SizedBox(height: 20),
          _buildSummaryTable(incomes, expenses, locale, isRTL),
          pw.SizedBox(height: 20),
          _buildIncomeSection(incomes, locale, isRTL),
          pw.SizedBox(height: 20),
          _buildExpenseSection(expenses, locale, isRTL),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(String monthYear, String locale, bool isRTL) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        textDirection: isRTL ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        children: [
          pw.Text(
            _localizeText('Al Khazna Financial Report', locale),
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Text(
            monthYear,
            style: pw.TextStyle(
              fontSize: 18,
              color: PdfColors.blue700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryTable(
    List<IncomeEntry> incomes,
    List<OutcomeEntry> expenses,
    String locale,
    bool isRTL,
  ) {
    final totalIncome = incomes.fold<double>(0, (sum, entry) => sum + entry.amount);
    final totalExpense = expenses.fold<double>(0, (sum, entry) => sum + entry.amount);
    final balance = totalIncome - totalExpense;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        _buildTableRow(
          [_localizeText('Total Income', locale), _formatCurrency(totalIncome, locale)],
          isHeader: false,
          textColor: PdfColors.green700,
          isRTL: isRTL,
        ),
        _buildTableRow(
          [_localizeText('Total Expenses', locale), _formatCurrency(totalExpense, locale)],
          isHeader: false,
          textColor: PdfColors.red700,
          isRTL: isRTL,
        ),
        _buildTableRow(
          [_localizeText('Net Balance', locale), _formatCurrency(balance, locale)],
          isHeader: false,
          textColor: balance >= 0 ? PdfColors.green700 : PdfColors.red700,
          backgroundColor: PdfColors.grey100,
          isRTL: isRTL,
        ),
      ],
    );
  }

  static pw.TableRow _buildTableRow(
    List<String> cells, {
    bool isHeader = false,
    PdfColor? backgroundColor,
    PdfColor? textColor,
    required bool isRTL,
  }) {
    return pw.TableRow(
      decoration: backgroundColor != null
          ? pw.BoxDecoration(color: backgroundColor)
          : null,
      children: cells.map((cell) {
        // Apply BiDi algorithm for mixed text
        final processedText = isRTL ? Bidi.logicalToVisual(cell) : cell;

        return pw.Container(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(
            processedText,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor ?? PdfColors.black,
            ),
            textAlign: isRTL ? pw.TextAlign.right : pw.TextAlign.left,
            textDirection: isRTL ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
        );
      }).toList(),
    );
  }

  static Future<pw.Font> _loadArabicFont() async {
    // Load Noto Sans Arabic font for PDF generation
    final fontData = await rootBundle.load('fonts/NotoSansArabic-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  static String _formatCurrency(double amount, String locale) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: '',
      decimalDigits: 2,
    );

    String formatted = formatter.format(amount);

    // Convert to Arabic numerals if needed
    if (locale.startsWith('ar')) {
      formatted = _convertToArabicNumerals(formatted);
    }

    return formatted;
  }

  static String _convertToArabicNumerals(String input) {
    const english = '0123456789';
    const arabic = '٠١٢٣٤٥٦٧٨٩';

    String result = input;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }

  static String _localizeText(String text, String locale) {
    // This would typically use your localization system
    if (locale.startsWith('ar')) {
      final translations = {
        'Al Khazna Financial Report': 'تقرير الخزنة المالي',
        'Total Income': 'إجمالي الدخل',
        'Total Expenses': 'إجمالي المصروفات',
        'Net Balance': 'الرصيد الصافي',
        'Income Details': 'تفاصيل الدخل',
        'Expense Details': 'تفاصيل المصروفات',
      };
      return translations[text] ?? text;
    }
    return text;
  }
}
```

### 11.2 Data Sharing Service
Custom .NOG file format with date-based naming:

```dart
static Future<void> _createAndShareFile({
  required Map<String, dynamic> data,
  required String filename,
}) async {
  final now = DateTime.now();
  final dateString = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
  final filePath = '${directory.path}/$dateString.NOG';
  // Implementation details...
}
```

### 11.3 Enhanced Critical UI Components

**Advanced IncomeRow Implementation:**
```dart
class IncomeRow extends StatefulWidget {
  final IncomeEntry entry;
  final Function(IncomeEntry) onUpdate;
  final VoidCallback onDelete;
  final int index;
  final bool isRTL;

  const IncomeRow({
    Key? key,
    required this.entry,
    required this.onUpdate,
    required this.onDelete,
    required this.index,
    required this.isRTL,
  }) : super(key: key);

  @override
  _IncomeRowState createState() => _IncomeRowState();
}

class _IncomeRowState extends State<IncomeRow>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late FocusNode _nameFocus;
  late FocusNode _amountFocus;
  late AnimationController _animController;
  late Animation<Color?> _borderAnimation;

  bool _isEditing = false;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
    _setupFocusListeners();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.entry.name);
    _amountController = TextEditingController(
      text: widget.entry.amount > 0 ? widget.entry.amount.toString() : '',
    );
    _nameFocus = FocusNode();
    _amountFocus = FocusNode();
  }

  void _setupAnimations() {
    _animController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _borderAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.green,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupFocusListeners() {
    _nameFocus.addListener(_onFocusChange);
    _amountFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final hasFocus = _nameFocus.hasFocus || _amountFocus.hasFocus;

    if (hasFocus && !_isEditing) {
      setState(() => _isEditing = true);
      _animController.forward();
    } else if (!hasFocus && _isEditing) {
      _debouncedSave();
    }
  }

  void _debouncedSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(Duration(milliseconds: 500), _saveEntry);
  }

  void _saveEntry() {
    final updatedEntry = widget.entry.copyWith(
      name: _nameController.text,
      amount: double.tryParse(_amountController.text) ?? 0,
      updatedAt: DateTime.now(),
    );

    widget.onUpdate(updatedEntry);

    setState(() => _isEditing = false);
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Alternating row colors
    final backgroundColor = widget.index.isEven
        ? theme.colorScheme.primaryContainer.withOpacity(0.3)
        : theme.colorScheme.primaryContainer.withOpacity(0.5);

    return Dismissible(
      key: Key(widget.entry.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (_) => _showDeleteConfirmation(context),
      background: _buildDismissBackground(theme),
      child: AnimatedBuilder(
        animation: _borderAnimation,
        builder: (context, child) {
          return Container(
            margin: EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _borderAnimation.value ?? Colors.transparent,
                width: 2,
              ),
            ),
            child: _buildRowContent(theme, l10n),
          );
        },
      ),
    );
  }

  Widget _buildRowContent(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        textDirection: widget.isRTL ? TextDirection.rtl : TextDirection.ltr,
        children: [
          // Amount field
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _amountController,
              focusNode: _amountFocus,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                LengthLimitingTextInputFormatter(10),
              ],
              style: theme.textTheme.bodyLarge?.copyWith(
                color: widget.entry.amount > 0 ? Colors.green : null,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0.00',
                contentPadding: EdgeInsets.zero,
              ),
              textAlign: widget.isRTL ? TextAlign.right : TextAlign.left,
            ),
          ),

          SizedBox(width: 16),

          // Name field
          Expanded(
            child: TextFormField(
              controller: _nameController,
              focusNode: _nameFocus,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: l10n.incomeNameHint,
                contentPadding: EdgeInsets.zero,
              ),
              textAlign: widget.isRTL ? TextAlign.right : TextAlign.left,
              textDirection: widget.isRTL ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),

          SizedBox(width: 16),

          // Index display
          Container(
            width: 30,
            child: Text(
              '${widget.index + 1}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissBackground(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.delete_outline,
        color: theme.colorScheme.onError,
        size: 32,
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteIncomeTitle),
        content: Text(l10n.deleteIncomeMessage(widget.entry.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _nameController.dispose();
    _amountController.dispose();
    _nameFocus.dispose();
    _amountFocus.dispose();
    _animController.dispose();
    super.dispose();
  }
}
```

### 11.4 Build Configuration
For Android APK naming, manual renaming may be required:
```bash
mv app-release.apk Alkhazna.apk
```

---

### 11.5 Material 3 Component Specifications

**Floating Action Button:**
```dart
class AddEntryFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(Icons.add),
      label: Text(tooltip),
      elevation: 3,
      focusElevation: 6,
      hoverElevation: 4,
      highlightElevation: 8,
    );
  }
}
```

**Navigation Bar:**
```dart
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: l10n.home,
        ),
        NavigationDestination(
          icon: Icon(Icons.trending_up_outlined),
          selectedIcon: Icon(Icons.trending_up),
          label: l10n.income,
        ),
        NavigationDestination(
          icon: Icon(Icons.trending_down_outlined),
          selectedIcon: Icon(Icons.trending_down),
          label: l10n.expenses,
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: l10n.settings,
        ),
      ],
    );
  }
}
```

---

**Document Version:** 2.0 - Enhanced Flutter Implementation
**Last Updated:** September 2024
**Prepared for:** Flutter Development Team
**Flutter Version:** 3.24+ with Material 3