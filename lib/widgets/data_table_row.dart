import 'package:flutter/material.dart';

class IncomeRow extends StatefulWidget {
  final int index;
  final double amount;
  final String name;
  final Function(double) onAmountChanged;
  final Function(String) onNameChanged;

  const IncomeRow({
    super.key,
    required this.index,
    required this.amount,
    required this.name,
    required this.onAmountChanged,
    required this.onNameChanged,
  });

  @override
  State<IncomeRow> createState() => _IncomeRowState();
}

class _IncomeRowState extends State<IncomeRow> {
  late TextEditingController _amountController;
  late TextEditingController _nameController;
  late FocusNode _amountFocusNode;
  late FocusNode _nameFocusNode;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.amount > 0 ? widget.amount.toStringAsFixed(0) : '',
    );
    _nameController = TextEditingController(text: widget.name);
    _amountFocusNode = FocusNode();
    _nameFocusNode = FocusNode();

    // Listen to focus changes to rebuild and show/hide borders
    _amountFocusNode.addListener(() => setState(() {}));
    _nameFocusNode.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(IncomeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _amountController.text = widget.amount > 0 ? widget.amount.toStringAsFixed(0) : '';
    }
    if (oldWidget.name != widget.name) {
      _nameController.text = widget.name;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _amountFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const rowBackgroundColor = Color(0xFFBBDEFB); // Light blue background

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: rowBackgroundColor, // Single solid background color
        borderRadius: BorderRadius.circular(12), // Rounded corners
      ),
      child: Row(
        children: [
          // Amount field - TextField that looks like plain text
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: rowBackgroundColor, // Background matches row
                border: _amountFocusNode.hasFocus
                    ? Border.all(color: Colors.green, width: 2) // Green border on focus
                    : Border.all(color: Colors.transparent), // Invisible border when not focused
                borderRadius: BorderRadius.circular(6),
              ),
              child: TextField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  // Green if value > 0, otherwise black
                  color: widget.amount > 0 ? Colors.green[700] : Colors.black,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none, // No visible border on TextField itself
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  hintText: '0',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onChanged: (value) {
                  final amount = double.tryParse(value) ?? 0;
                  widget.onAmountChanged(amount);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Name field - TextField that looks like plain text
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: rowBackgroundColor, // Background matches row
                border: _nameFocusNode.hasFocus
                    ? Border.all(color: Colors.green, width: 2) // Green border on focus
                    : Border.all(color: Colors.transparent), // Invisible border when not focused
                borderRadius: BorderRadius.circular(6),
              ),
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none, // No visible border on TextField itself
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  hintText: 'Enter name...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onChanged: (value) {
                  widget.onNameChanged(value);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Index - Read-only text aligned to the right
          Expanded(
            flex: 1,
            child: Text(
              '${widget.index}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.right, // Aligned to the right
            ),
          ),
        ],
      ),
    );
  }
}