// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 4;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String,
      username: fields[1] as String,
      email: fields[2] as String,
      passwordHash: fields[3] as String,
      createdAt: fields[4] as DateTime,
      lastLoginAt: fields[5] as DateTime,
      biometricEnabled: fields[6] as bool,
      googleAccountId: fields[7] as String?,
      backupGoogleAccountEmail: fields[8] as String?,
      profileImageUrl: fields[9] as String?,
      isFirstTime: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.passwordHash)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastLoginAt)
      ..writeByte(6)
      ..write(obj.biometricEnabled)
      ..writeByte(7)
      ..write(obj.googleAccountId)
      ..writeByte(8)
      ..write(obj.backupGoogleAccountEmail)
      ..writeByte(9)
      ..write(obj.profileImageUrl)
      ..writeByte(10)
      ..write(obj.isFirstTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
