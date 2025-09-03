import 'package:hive/hive.dart';

part 'income_entry.g.dart';

@HiveType(typeId: 0)
class IncomeEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  IncomeEntry({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'date': date.toIso8601String(),
      };
      
  Map<String, dynamic> toMap() => toJson();

  factory IncomeEntry.fromJson(Map<String, dynamic> json) {
    return IncomeEntry(
      id: json['id'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }
}
