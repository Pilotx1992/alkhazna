// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'income_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IncomeEntryAdapter extends TypeAdapter<IncomeEntry> {
  @override
  final int typeId = 0;

  @override
  IncomeEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IncomeEntry(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      createdAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, IncomeEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
