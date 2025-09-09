import 'package:google_sign_in/google_sign_in.dart';
import 'simple_login_screen.dart';
import 'restore_options_screen.dart';
import 'simple_backup_screen.dart';

import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "month_page.dart";
import "../services/storage_service.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _months = const [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];
  final List<int> _years = List.generate(11, (index) => 2025 + index);

  late String _selectedMonth;
  late int _selectedYear;

  final StorageService _storageService = StorageService();
  
  double _totalIncome = 0;
  double _totalOutcome = 0;
  bool _isTotalsLoading = true;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedMonth = _months[DateTime.now().month - 1];
    _selectedYear = DateTime.now().year;
    _loadLastSelection();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadTotals();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTotals();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLastSelection() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMonth = prefs.getString('lastSelectedMonth') ??
          _months[DateTime.now().month - 1];
      _selectedYear = prefs.getInt('lastSelectedYear') ?? DateTime.now().year;
    });
  }

  Future<void> _saveSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSelectedMonth', _selectedMonth);
    await prefs.setInt('lastSelectedYear', _selectedYear);
  }

  Future<void> _loadTotals() async {
    setState(() => _isTotalsLoading = true);
    try {
      // Load data for the selected month and year
      final monthIncomeEntries = await _storageService.getIncomeEntries(_selectedMonth, _selectedYear);
      final monthOutcomeEntries = await _storageService.getOutcomeEntries(_selectedMonth, _selectedYear);
      
      setState(() {
        _totalIncome = monthIncomeEntries.fold(0.0, (sum, entry) => sum + entry.amount);
        _totalOutcome = monthOutcomeEntries.fold(0.0, (sum, entry) => sum + entry.amount);
        _isTotalsLoading = false;
      });
    } catch (e) {
      setState(() => _isTotalsLoading = false);
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bodyContent = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // Select Period Section
            Card(
              elevation: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.surfaceContainer,
                      colorScheme.surfaceContainer.withAlpha((255 * 0.8).round()),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.05).round()),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Period',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // Month Dropdown
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Month',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onSurface.withAlpha((255 * 0.6).round()),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    border: Border.all(color: colorScheme.outline),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButton<String>(
                                    value: _selectedMonth,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    items: _months.map((month) {
                                      return DropdownMenuItem(
                                        value: month,
                                        child: Text(month),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedMonth = value;
                                        });
                                        _saveSelection();
                                        _loadTotals(); // Reload totals when month changes
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Year Dropdown
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Year',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onSurface.withAlpha((255 * 0.6).round()),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    border: Border.all(color: colorScheme.outline),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButton<int>(
                                    value: _selectedYear,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    items: _years.map((year) {
                                      return DropdownMenuItem(
                                        value: year,
                                        child: Text(year.toString()),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedYear = value;
                                        });
                                        _saveSelection();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Month Details Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MonthPage(
                                  month: _selectedMonth,
                                  year: _selectedYear,
                                ),
                              ),
                            );
                            _loadTotals();
                          },
                          child: const Text('Month Details'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Total Balance Card - Matching HomeScreen.jpg design
            _isTotalsLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4CAF50), // Material Green 500
                          Color(0xFF81C784), // Material Green 300
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withAlpha((255 * 0.3).round()),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Balance',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          (_totalIncome - _totalOutcome)
                              .toStringAsFixed(0)
                              .replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (Match m) => '${m[1]},',
                              ),
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 48,
                          ),
                        ),
                      ],
                    ),
                  ),
            
          ],
        ),
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'Alkhazna',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          backgroundColor: colorScheme.surface,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.backup),
              tooltip: 'Backup & Restore',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SimpleBackupScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.cloud_download),
              tooltip: 'Restore Options',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RestoreOptionsScreen()),
                );
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
              onPressed: () async {
                final googleSignIn = GoogleSignIn();
                await googleSignIn.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const SimpleLoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: bodyContent,
      ),
    );
  }
}