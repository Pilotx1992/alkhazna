import 'package:flutter/material.dart';
import '../widgets/data_table_row.dart';

// Simple data model
class RowData {
  double amount;
  String name;
  
  RowData({required this.amount, required this.name});
}

class DataTableExample extends StatefulWidget {
  const DataTableExample({super.key});

  @override
  State<DataTableExample> createState() => _DataTableExampleState();
}

class _DataTableExampleState extends State<DataTableExample> {
  // Sample data list
  List<RowData> dataList = [
    RowData(amount: 2000, name: 'تامر محمود سليم'),
    RowData(amount: 0, name: 'تامر عبدالرحمن'),
    RowData(amount: 2000, name: 'احمد ابو الصفا محمود'),
    RowData(amount: 0, name: 'احمد مجدي'),
    RowData(amount: 2000, name: 'علي سليمان'),
    RowData(amount: 2000, name: 'محمد جمال عبدالشافي'),
    RowData(amount: 0, name: 'ايهاب سيد اسماعيل'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Income Data Table'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Header row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                // Total display
                Text(
                  'Total: ${_calculateTotal().toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                // Action buttons
                IconButton(
                  icon: const Icon(Icons.file_download, color: Colors.grey),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // Column headers
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
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
                SizedBox(width: 12),
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
                SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // Data rows using ListView.builder
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dataList.length,
              itemBuilder: (context, index) {
                return IncomeRow(
                  index: index + 1, // Row number starts from 1
                  amount: dataList[index].amount,
                  name: dataList[index].name,
                  onAmountChanged: (newAmount) {
                    setState(() {
                      dataList[index].amount = newAmount;
                    });
                    // Here you would save to your database/storage
                    debugPrint('Amount changed for row ${index + 1}: $newAmount');
                  },
                  onNameChanged: (newName) {
                    setState(() {
                      dataList[index].name = newName;
                    });
                    // Here you would save to your database/storage
                    debugPrint('Name changed for row ${index + 1}: $newName');
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRow,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _addNewRow() {
    setState(() {
      dataList.add(RowData(amount: 0, name: ''));
    });
  }

  double _calculateTotal() {
    return dataList.fold(0.0, (sum, item) => sum + item.amount);
  }
}

// Example of how to use in main.dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Income Row Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: const DataTableExample(),
    );
  }
}