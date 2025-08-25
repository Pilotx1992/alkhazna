import 'package:hive/hive.dart';
import 'income_entry.dart';
import 'outcome_entry.dart';

class IncomeEntryListAdapter extends TypeAdapter<List<IncomeEntry>> {
  @override
  final int typeId = 2;

  @override
  List<IncomeEntry> read(BinaryReader reader) {
    final length = reader.readInt32();
    final List<IncomeEntry> list = [];
    for (var i = 0; i < length; i++) {
      list.add(reader.read() as IncomeEntry);
    }
    return list;
  }

  @override
  void write(BinaryWriter writer, List<IncomeEntry> obj) {
    writer.writeInt32(obj.length);
    obj.forEach(writer.write);
  }
}

class OutcomeEntryListAdapter extends TypeAdapter<List<OutcomeEntry>> {
  @override
  final int typeId = 3;

  @override
  List<OutcomeEntry> read(BinaryReader reader) {
    final length = reader.readInt32();
    final List<OutcomeEntry> list = [];
    for (var i = 0; i < length; i++) {
      list.add(reader.read() as OutcomeEntry);
    }
    return list;
  }

  @override
  void write(BinaryWriter writer, List<OutcomeEntry> obj) {
    writer.writeInt32(obj.length);
    obj.forEach(writer.write);
  }
}
