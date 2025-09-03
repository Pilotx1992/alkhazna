import 'package:hive/hive.dart';

part 'outcome_entry.g.dart';

@HiveType(typeId: 1)
class OutcomeEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  OutcomeEntry({
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

  factory OutcomeEntry.fromJson(Map<String, dynamic> json) {
    return OutcomeEntry(
      id: json['id'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }
}
