import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

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

  @HiveField(4)
  DateTime? createdAt; // تاريخ الإضافة الفعلي

  @HiveField(5)
  DateTime? updatedAt; // تاريخ آخر تحديث (للـ Smart Merge)

  @HiveField(6)
  int version; // رقم الإصدار (للـ Conflict Resolution)

  OutcomeEntry({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    this.createdAt,
    this.updatedAt,
    this.version = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'date': date.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'version': version,
      };
      
  Map<String, dynamic> toMap() => toJson();

  factory OutcomeEntry.fromJson(Map<String, dynamic> json) {
    // Legacy backup compatibility: generate UUID if missing
    final id = json['id'] as String? ?? 'out_${const Uuid().v4()}';
    final name = json['name'] as String? ?? 'Unknown';
    final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;

    return OutcomeEntry(
      id: id,
      name: name,
      amount: amount,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      version: json['version'] as int? ?? 1,
    );
  }

  /// Update entry and increment version
  void update() {
    updatedAt = DateTime.now();
    version++;
  }

  /// Create copy with changes
  OutcomeEntry copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
  }) {
    return OutcomeEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}
