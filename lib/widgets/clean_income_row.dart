import 'package:flutter/material.dart';

class CleanIncomeRow extends StatefulWidget {
  final int index;
  final double amount;
  final String name;
  final Function(double) onAmountChanged;
  final Function(String) onNameChanged;

  const CleanIncomeRow({
    super.key,
    required this.index,
    required this.amount,
    required this.name,
    required this.onAmountChanged,
    required this.onNameChanged,
  });

  @override
  State<CleanIncomeRow> createState() => _CleanIncomeRowState();
}

class _CleanIncomeRowState extends State<CleanIncomeRow> {
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

    // Listen to focus changes to trigger rebuilds
    _amountFocusNode.addListener(() => setState(() {}));
    _nameFocusNode.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(CleanIncomeRow oldWidget) {
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
        color: rowBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Amount field (TextField looking like plain text)
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: rowBackgroundColor, // Match row background
                border: _amountFocusNode.hasFocus
                    ? Border.all(color: Colors.green, width: 2)
                    : Border.all(color: Colors.transparent), // Invisible border
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
                  color: widget.amount > 0 ? Colors.green[700] : Colors.black, // Green if > 0, black otherwise
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none, // No visible border
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
          
          // Name field (TextField looking like plain text)
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: rowBackgroundColor, // Match row background
                border: _nameFocusNode.hasFocus
                    ? Border.all(color: Colors.green, width: 2)
                    : Border.all(color: Colors.transparent), // Invisible border
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
                  border: InputBorder.none, // No visible border
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
          
          // Index (read-only text, right-aligned)
          Expanded(
            flex: 1,
            child: Text(
              '${widget.index}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.right, // Right-aligned
            ),
          ),
        ],
      ),
    );
  }
}