import 'package:flutter/widgets.dart';

class AddEntryIntent extends Intent {
  const AddEntryIntent();
}

class DeleteLastEntryIntent extends Intent {
  const DeleteLastEntryIntent();
}

class ClearAmountsIntent extends Intent {
  const ClearAmountsIntent();
}

class TabNavigationIntent extends Intent {
  final int tabIndex;
  const TabNavigationIntent(this.tabIndex);
}
