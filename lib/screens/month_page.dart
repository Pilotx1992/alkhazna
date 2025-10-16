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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              backgroundColor: colorScheme.surface,
              appBar: AppBar(
                backgroundColor: colorScheme.surface,
                elevation: 0,
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$month $year',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                bottom: TabBar(
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                  indicatorColor: colorScheme.primary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: colorScheme.outline.withAlpha((0.2 * 255).round()),
                  labelStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: theme.textTheme.labelLarge,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.attach_money, size: 22),
                      text: 'Income',
                      iconMargin: const EdgeInsets.only(bottom: 4),
                    ),
                    Tab(
                      icon: Icon(Icons.shopping_cart_outlined, size: 22),
                      text: 'Expenses',
                      iconMargin: const EdgeInsets.only(bottom: 4),
                    ),
                    Tab(
                      icon: Icon(Icons.account_balance_wallet_outlined, size: 22),
                      text: 'Balance',
                      iconMargin: const EdgeInsets.only(bottom: 4),
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
