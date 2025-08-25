import 'package:flutter/material.dart';
import '../widgets/income_row.dart';

// Example data model
class IncomeItem {
  String id;
  double amount;
  String name;

  IncomeItem({required this.id, required this.amount, required this.name});
}

class IncomeRowExample extends StatefulWidget {
  const IncomeRowExample({super.key});

  @override
  State<IncomeRowExample> createState() => _IncomeRowExampleState();
}

class _IncomeRowExampleState extends State<IncomeRowExample> {
  // Sample data
  List<IncomeItem> incomeItems = [
    IncomeItem(id: '1', amount: 2000, name: 'تامر محمود سليم'),
    IncomeItem(id: '2', amount: 0, name: 'تامر عبدالرحمن'),
    IncomeItem(id: '3', amount: 2000, name: 'احمد ابو الصفا محمود'),
    IncomeItem(id: '4', amount: 0, name: 'احمد مجدي'),
    IncomeItem(id: '5', amount: 2000, name: 'علي سليمان'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income Row Example'),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
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
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // List of income rows
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 80,
                left: 16,
                right: 16,
              ),
              itemCount: incomeItems.length,
              itemBuilder: (context, index) {
                final item = incomeItems[index];
                
                return IncomeRow(
                  index: index + 1,
                  amount: item.amount,
                  name: item.name,
                  onAmountChanged: (newAmount) {
                    setState(() {
                      item.amount = newAmount;
                    });
                    // Save to storage here if needed
                    print('Amount changed for ${item.name}: $newAmount');
                  },
                  onNameChanged: (newName) {
                    setState(() {
                      item.name = newName;
                    });
                    // Save to storage here if needed
                    print('Name changed to: $newName');
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
            incomeItems.add(
              IncomeItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                amount: 0,
                name: '',
              ),
            );
          });
        },
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}