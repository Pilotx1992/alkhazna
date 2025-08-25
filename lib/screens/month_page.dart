import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'income_screen.dart';
import 'outcome_screen.dart';
import 'balance_screen.dart';
import '../utils/keyboard_intents.dart';

class MonthPage extends StatelessWidget {
  final String month;
  final int year;

  const MonthPage({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTabController(
        length: 3,
        child: Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit1):
                const TabNavigationIntent(0),
            LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit2):
                const TabNavigationIntent(1),
            LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit3):
                const TabNavigationIntent(2),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              TabNavigationIntent: CallbackAction<TabNavigationIntent>(
                onInvoke: (intent) =>
                    DefaultTabController.of(context).animateTo(intent.tabIndex),
              ),
            },
            child: Scaffold(
              backgroundColor: Colors.grey[100],
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Text(
                  '$month $year',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                bottom: TabBar(
                  labelColor: const Color(0xFF2196F3),
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: const Color(0xFF2196F3),
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.attach_money),
                      text: 'Income',
                    ),
                    Tab(
                      icon: Icon(Icons.shopping_cart_outlined),
                      text: 'Expenses',
                    ),
                    Tab(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      text: 'Balance',
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  IncomeScreen(month: month, year: year),
                  OutcomeScreen(month: month, year: year),
                  BalanceScreen(month: month, year: year),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
