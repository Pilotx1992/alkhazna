import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'month_page.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _months = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
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
    // Initialize with default values
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
      final allIncome = await _storageService.getAllIncomeEntries();
      final allOutcome = await _storageService.getAllOutcomeEntries();
      setState(() {
        _totalIncome = allIncome.fold(0.0, (sum, entry) => sum + entry.amount);
        _totalOutcome =
            allOutcome.fold(0.0, (sum, entry) => sum + entry.amount);
        _isTotalsLoading = false;
      });
    } catch (e) {
      setState(() => _isTotalsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // App Title
                Text(
                  'Alkhazna',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Select Period Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Period',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 48, // ← هنا تحدد الارتفاع الذي تريده (مثلاً 48 بكسل)
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 48, // ← أضف هذا السطر لتحديد ارتفاع القائمة المنسدلة للسنة
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
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
                        child: ElevatedButton(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Month Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Total Balance Card
                _isTotalsLoading
                    ? const CircularProgressIndicator()
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green[400]!,
                              Colors.green[600]!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Total Balance',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              (_totalIncome - _totalOutcome)
                                  .abs()
                                  .toStringAsFixed(0)
                                  .replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]},',
                                  ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                
                const SizedBox(height: 32),
                
                // Data Backup Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Data Backup',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Implement export functionality
                              },
                              icon: const Icon(Icons.download, size: 18),
                              label: const Text('Export'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2196F3),
                                side: const BorderSide(color: Color(0xFF2196F3)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Implement import functionality
                              },
                              icon: const Icon(Icons.upload, size: 18),
                              label: const Text('Import'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[300]!),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement professional backup functionality
                          },
                          icon: const Icon(Icons.business_center, size: 18),
                          label: const Text('Professional Backup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
