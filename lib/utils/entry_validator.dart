class EntryValidator {
  static const double maxAmount = 999999999.99; // 9 digits before decimal
  static const int maxNameLength = 50;

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'الرجاء إدخال رقم صحيح';
    }

    if (amount < 0) {
      return 'لا يمكن أن يكون المبلغ سالباً';
    }

    if (amount > maxAmount) {
      return 'المبلغ كبير جداً';
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length > maxNameLength) {
      return 'الاسم طويل جداً';
    }

    return null;
  }

  static bool isValidAmount(String value) {
    return validateAmount(value) == null;
  }

  static bool isValidName(String value) {
    return validateName(value) == null;
  }
}
