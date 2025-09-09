import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/outcome_entry.dart';
import '../services/storage_service.dart';

class OutcomeScreen extends StatefulWidget {
  final String month;
  final int year;

  const OutcomeScreen({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<OutcomeScreen> createState() => _OutcomeScreenState();
}

class _OutcomeScreenState extends State<OutcomeScreen> {
  final StorageService _storageService = StorageService();
  final ScrollController _scrollController = ScrollController();
  List<OutcomeEntry> _outcomeEntries = [];
  final Map<String, TextEditingController> _amountControllers = {};
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _dateControllers = {};
  DateTime _selectedDate = DateTime.now();
  
  // Controllers for the input form
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries =
        await _storageService.getOutcomeEntries(widget.month, widget.year);
    setState(() {
      _outcomeEntries = entries;
      _initializeControllers();
    });
  }

  void _initializeControllers() {
    for (var controller in _amountControllers.values) {
      controller.dispose();
    }
    for (var controller in _nameControllers.values) {
      controller.dispose();
    }
    for (var controller in _dateControllers.values) {
      controller.dispose();
    }
    _amountControllers.clear();
    _nameControllers.clear();
    _dateControllers.clear();

    for (var entry in _outcomeEntries) {
      _amountControllers[entry.id] = TextEditingController(
          text: entry.amount > 0 ? entry.amount.toStringAsFixed(0) : '');
      _nameControllers[entry.id] = TextEditingController(text: entry.name);
      _dateControllers[entry.id] =
          TextEditingController(text: DateFormat('dd/MM').format(entry.date));
    }
  }

  Future<void> _saveEntries() async {
    try {
      await _storageService.saveOutcomeEntries(
        widget.month,
        widget.year,
        _outcomeEntries,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: ${e.toString()}')),
        );
      }
    }
  }


  void _addNewEntry() {
    // Validate input
    if (_descriptionController.text.trim().isEmpty || _amountInputController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both description and amount')),
      );
      return;
    }
    
    final amount = double.tryParse(_amountInputController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final newEntry = OutcomeEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _descriptionController.text.trim(),
      amount: amount,
      date: _selectedDate,
    );

    setState(() {
      _outcomeEntries.add(newEntry);
      _amountControllers[newEntry.id] = TextEditingController(
        text: amount.toStringAsFixed(0)
      );
      _nameControllers[newEntry.id] = TextEditingController(text: newEntry.name);
      _dateControllers[newEntry.id] = TextEditingController(
          text: DateFormat('dd/MM').format(_selectedDate));
      
      // Clear input fields
      _descriptionController.clear();
      _amountInputController.clear();
    });
    
    _saveEntries();
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


  void _deleteEntryById(String entryId) {
    final entryIndex = _outcomeEntries.indexWhere((entry) => entry.id == entryId);
    if (entryIndex == -1) return; // Entry not found
    
    final entryToDelete = _outcomeEntries[entryIndex];
    
    setState(() {
      _outcomeEntries.removeAt(entryIndex);
      _nameControllers.remove(entryToDelete.id)?.dispose();
      _amountControllers.remove(entryToDelete.id)?.dispose();
      _dateControllers.remove(entryToDelete.id)?.dispose();
    });
    
    _saveEntries();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Entry deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                _outcomeEntries.insert(entryIndex, entryToDelete);
                _amountControllers[entryToDelete.id] = TextEditingController(
                    text: entryToDelete.amount > 0
                        ? entryToDelete.amount.toStringAsFixed(0)
                        : '');
                _nameControllers[entryToDelete.id] =
                    TextEditingController(text: entryToDelete.name);
                _dateControllers[entryToDelete.id] = TextEditingController(
                    text: DateFormat('dd/MM').format(entryToDelete.date));
              });
              _saveEntries();
            },
          ),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              // Date section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    const Text(
                      'Date:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(DateTime.now().year, 1, 1),
                          lastDate: DateTime(DateTime.now().year, 12, 31),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Input form section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Description field
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'Description',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Amount field
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _amountInputController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'Amount', 
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Add Expense button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _addNewEntry,
                        style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFE53E3E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Add Expense',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content area
              Expanded(
                child: _outcomeEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No expenses yet.',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add your first!',
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _outcomeEntries.length,
                        itemBuilder: (context, index) {
                          return _buildExpenseListItem(index);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseListItem(int index) {
    final entry = _outcomeEntries[index];
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 30,
        ),
      ),
      confirmDismiss: (direction) async {
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: const Text('Are you sure you want to delete this expense?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
        return confirmed ?? false;
      },
      onDismissed: (direction) {
        _deleteEntryById(entry.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Amount (left side in red)
              Text(
                NumberFormat('#,##0', 'en').format(entry.amount.round()),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              
              const Spacer(),
              
              // Description (Arabic text, center)
              Expanded(
                flex: 3,
                child: Text(
                  entry.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Date (DD/MM format)
              Text(
                DateFormat('dd/MM').format(entry.date),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(width: 24),
              
              // Row number (right side in red)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                 
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE53E3E),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _descriptionController.dispose();
    _amountInputController.dispose();
    for (var controller in _amountControllers.values) {
      controller.dispose();
    }
    for (var controller in _nameControllers.values) {
      controller.dispose();
    }
    for (var controller in _dateControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}