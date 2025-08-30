import 'package:flutter/material.dart';
import '../widgets/clean_income_row.dart';

// Data model
class IncomeData {
  double amount;
  String name;
  
  IncomeData({required this.amount, required this.name});
}

class CleanIncomeExample extends StatefulWidget {
  const CleanIncomeExample({super.key});

  @override
  State<CleanIncomeExample> createState() => _CleanIncomeExampleState();
}

class _CleanIncomeExampleState extends State<CleanIncomeExample> {
  // Sample data - replace with your actual data source
  List<IncomeData> incomeList = [
    IncomeData(amount: 2000, name: 'تامر محمود سليم'),
    IncomeData(amount: 0, name: 'تامر عبدالرحمن'),
    IncomeData(amount: 2000, name: 'احمد ابو الصفا محمود'),
    IncomeData(amount: 0, name: 'احمد مجدي'),
    IncomeData(amount: 2000, name: 'علي سليمان'),
    IncomeData(amount: 2000, name: 'محمد جمال عبدالشافي'),
    IncomeData(amount: 0, name: 'ايهاب سيد اسماعيل'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('September 2025'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header section with total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  'Total: ${_calculateTotal().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
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
                  icon: const Icon(Icons.keyboard_arrow_up, color: Colors.grey),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.format_list_bulleted, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // Column headers
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
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // List of income rows using ListView.builder
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 80,
                left: 16,
                right: 16,
              ),
              itemCount: incomeList.length,
              itemBuilder: (context, index) {
                return CleanIncomeRow(
                  index: index + 1,
                  amount: incomeList[index].amount,
                  name: incomeList[index].name,
                  onAmountChanged: (newAmount) {
                    setState(() {
                      incomeList[index].amount = newAmount;
                    });
                    // Here you would typically save to your storage/database
                    
                  },
                  onNameChanged: (newName) {
                    setState(() {
                      incomeList[index].name = newName;
                    });
                    // Here you would typically save to your storage/database
                    
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            incomeList.add(IncomeData(amount: 0, name: ''));
          });
        },
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  double _calculateTotal() {
    return incomeList.fold(0.0, (sum, item) => sum + item.amount);
  }
}