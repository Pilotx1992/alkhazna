import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

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
  DateTime date; // للترتيب في الشاشة (أول يوم في الشهر)

  @HiveField(4)
  DateTime? createdAt; // تاريخ الدفع/الإضافة الفعلي (يظهر في PDF)

  @HiveField(5)
  DateTime? updatedAt; // تاريخ آخر تحديث (للـ Smart Merge)

  @HiveField(6)
  int version; // رقم الإصدار (للـ Conflict Resolution)

  IncomeEntry({
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

  factory IncomeEntry.fromJson(Map<String, dynamic> json) {
    // Legacy backup compatibility: generate UUID if missing
    final id = json['id'] as String? ?? 'inc_${const Uuid().v4()}';
    final name = json['name'] as String? ?? 'Unknown';
    final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;

    return IncomeEntry(
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
  IncomeEntry copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
  }) {
    return IncomeEntry(
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
