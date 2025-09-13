import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/income_entry.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../widgets/income_row.dart';

class IncomeScreen extends StatefulWidget {
  final String month;
  final int year;

  const IncomeScreen({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final StorageService _storageService = StorageService();
  final ScrollController _scrollController = ScrollController();
  List<IncomeEntry> _incomeEntries = [];
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries =
        await _storageService.getIncomeEntries(widget.month, widget.year);
    setState(() {
      _incomeEntries = entries;
      _calculateTotal();
    });
  }


  Future<void> _saveEntries() async {
    try {
      await _storageService.saveIncomeEntries(
        widget.month,
        widget.year,
        _incomeEntries,
      );
      _calculateTotal();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: ${e.toString()}')),
      );
    }
  }

  void _calculateTotal() {
    double total = 0;
    for (var entry in _incomeEntries) {
      total += entry.amount;
    }
    setState(() => _totalAmount = total);
  }

  void _shareZeroAmountNames() async {
    try {
      await PdfService.shareZeroAmountNames(
        incomeEntries: _incomeEntries,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addNewEntry() {
    final newEntry = IncomeEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '',
      amount: 0,
      date: DateTime(widget.year, _getMonthNumber(widget.month), 1),
    );

    setState(() {
      _incomeEntries.add(newEntry);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _deleteEntry(int index) {
    if (index >= 0 && index < _incomeEntries.length) {
      final entryToDelete = _incomeEntries[index];
      setState(() {
        _incomeEntries.removeAt(index);
      });
      _saveEntries();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Entry deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                _incomeEntries.insert(index, entryToDelete);
              });
              _saveEntries();
            },
          ),
        ),
      );
    }
  }

  void _insertNewEntryAt(int index) {
    final newEntry = IncomeEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '',
      amount: 0,
      date: DateTime(widget.year, _getMonthNumber(widget.month), 1),
    );

    setState(() {
      _incomeEntries.insert(index + 1, newEntry);
    });
    _saveEntries();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New entry inserted')),
    );
  }

  String _getPreviousMonth() {
    const months = [
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
    final currentIndex = months.indexOf(widget.month);
    return currentIndex > 0 ? months[currentIndex - 1] : 'December';
  }

  Future<void> _copyFromPreviousMonth() async {
    final confirmed = await _showConfirmDialog(
      'Copy Names',
      'ADD NEW NAMES',
      'Import',
    );

    if (!confirmed) return;

    try {
      // Get previous month data
      String prevMonth =
          widget.month == 'January' ? 'December' : _getPreviousMonth();
      int prevYear = widget.month == 'January' ? widget.year - 1 : widget.year;

      final prevEntries =
          await _storageService.getIncomeEntries(prevMonth, prevYear);

      if (prevEntries.isNotEmpty) {
        setState(() {
          // Clear existing empty entries first
          _incomeEntries.clear();

          // Create new entries based on previous month data
          for (int i = 0; i < prevEntries.length; i++) {
            final newEntry = IncomeEntry(
              id: DateTime.now().microsecondsSinceEpoch.toString() +
                  i.toString(),
              name: prevEntries[i].name,
              amount: 0, // Copy names only, not amounts
              date: DateTime(widget.year, _getMonthNumber(widget.month), 1),
            );
            _incomeEntries.add(newEntry);
          }

          // Add at least 1 extra empty rows for new entries
          for (int i = 0; i < 1; i++) {
            final newEntry = IncomeEntry(
              id: DateTime.now().microsecondsSinceEpoch.toString() +
                  (prevEntries.length + i).toString(),
              name: '',
              amount: 0,
              date: DateTime(widget.year, _getMonthNumber(widget.month), 1),
            );
            _incomeEntries.add(newEntry);
          }
        });
        _saveEntries();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${prevEntries.length} names copied from $prevMonth $prevYear!')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No data found for $prevMonth $prevYear')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error copying data: ${e.toString()}')),
      );
    }
  }

  void _clearLastRow() async {
    if (_incomeEntries.isNotEmpty) {
      final confirmed = await _showConfirmDialog(
        'Delete Last Row',
        'Are you sure to delete the last row?',
        'Delete',
      );

      if (confirmed) {
        setState(() {
          _incomeEntries.removeLast();
        });
        _saveEntries();
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No rows to delete')),
      );
    }
  }

  Future<bool> _showConfirmDialog(
      String title, String message, String confirmText) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Column(
          children: [
            // Total section with action buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Text(
                    'Total: ${NumberFormat('#,###').format(_totalAmount.round())}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.file_download, color: Colors.grey),
                    onPressed: _copyFromPreviousMonth,
                    tooltip: 'Copy Names',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: Colors.transparent,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.green),
                    onPressed: _shareZeroAmountNames,
                    tooltip: 'Share Zero Names',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: Colors.transparent,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: _clearLastRow,
                    tooltip: 'Delete Last Row',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: Colors.transparent,
                    ),
                  ),
                 
                ],
              ),
            ),
            // Headers
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '#',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // List of entries
            Expanded(
              child: _incomeEntries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No income entries yet.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add your first income entry using the + button!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                          top: 8, bottom: 80, left: 8, right: 8),
                      itemCount: _incomeEntries.length,
                      itemBuilder: (context, index) {
                        return _buildEditableRow(index);
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNewEntry,
          backgroundColor: const Color(0xFF2196F3),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEditableRow(int index) {
    final entry = _incomeEntries[index];

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.horizontal,
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 30,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Confirm Delete'),
                content:
                    const Text('Sure To Delete?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              );
            },
          );
        } else if (direction == DismissDirection.startToEnd) {
          _insertNewEntryAt(index);
          return false;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteEntry(index);
        }
      },
      child: IncomeRow(
        index: index + 1,
        amount: entry.amount,
        name: entry.name,
        onAmountChanged: (newAmount) {
          setState(() {
            entry.amount = newAmount;
            _calculateTotal();
          });
          _saveEntries();
        },
        onNameChanged: (newName) {
          setState(() {
            entry.name = newName;
          });
          _saveEntries();
        },
      ),
    );
  }

  int _getMonthNumber(String monthName) {
    const monthMap = {
      'January': 1, 'February': 2, 'March': 3, 'April': 4,
      'May': 5, 'June': 6, 'July': 7, 'August': 8,
      'September': 9, 'October': 10, 'November': 11, 'December': 12
    };
    return monthMap[monthName] ?? 1;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}