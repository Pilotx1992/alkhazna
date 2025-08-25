import 'package:flutter/material.dart';

class IncomeRow extends StatefulWidget {
  final int index;
  final double amount;
  final String name;
  final Function(double) onAmountChanged;
  final Function(String) onNameChanged;
  final VoidCallback? onDelete;

  const IncomeRow({
    super.key,
    required this.index,
    required this.amount,
    required this.name,
    required this.onAmountChanged,
    required this.onNameChanged,
    this.onDelete,
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
    _amountFocusNode.addListener(_onFocusChange);
    _nameFocusNode.addListener(_onFocusChange);
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

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _amountFocusNode.removeListener(_onFocusChange);
    _nameFocusNode.removeListener(_onFocusChange);
    _amountFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color rowBackgroundColor =
        widget.index % 2 == 1
            ? Color.fromARGB(255, 225, 236, 247)
            : const Color(0xFFBBDEFB); // even rows
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: rowBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          // Amount field
          Expanded(
            flex: 2,
            child: TextField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.amount > 0 ? Colors.green[700] : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(color: Colors.grey),
                isDense: true,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                filled: true,
                fillColor: rowBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                widget.onAmountChanged(amount);
              },
            ),
          ),
          const SizedBox(width: 12),
          // Name field
          Expanded(
            flex: 6,
            child: TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Name',
                  hintStyle: const TextStyle(color: Colors.grey),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  filled: true,
                  fillColor: rowBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                onChanged: (value) {
                  widget.onNameChanged(value);
                },
            ),
          ),
          const SizedBox(width: 12),
          // Index (row number) - read-only
          Expanded(
            flex: 1,
            child: Text(
              '${widget.index}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}