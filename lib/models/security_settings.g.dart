// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SecuritySettingsAdapter extends TypeAdapter<SecuritySettings> {
  @override
  final int typeId = 5;

  @override
  SecuritySettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SecuritySettings(
      isPinEnabled: fields[0] as bool,
      isBiometricEnabled: fields[1] as bool,
      failedAttempts: fields[2] as int,
      lockoutUntil: fields[3] as DateTime?,
      lastUnlockedAt: fields[4] as DateTime?,
      pinSalt: fields[5] as String?,
      autoLockTimeout: fields[6] as int?,
      sessionStartTime: fields[7] as DateTime?,
      lastInteractionTime: fields[8] as DateTime?,
      sessionDuration: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SecuritySettings obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.isPinEnabled)
      ..writeByte(1)
      ..write(obj.isBiometricEnabled)
      ..writeByte(2)
      ..write(obj.failedAttempts)
      ..writeByte(3)
      ..write(obj.lockoutUntil)
      ..writeByte(4)
      ..write(obj.lastUnlockedAt)
      ..writeByte(5)
      ..write(obj.pinSalt)
      ..writeByte(6)
      ..write(obj.autoLockTimeout)
      ..writeByte(7)
      ..write(obj.sessionStartTime)
      ..writeByte(8)
      ..write(obj.lastInteractionTime)
      ..writeByte(9)
      ..write(obj.sessionDuration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecuritySettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
