// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BackupInfoAdapter extends TypeAdapter<BackupInfo> {
  @override
  final int typeId = 4;

  @override
  BackupInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BackupInfo(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      sizeBytes: fields[2] as int,
      deviceName: fields[3] as String,
      driveFileId: fields[4] as String,
      status: fields[5] as BackupStatus,
      errorMessage: fields[6] as String?,
      incomeEntriesCount: fields[7] as int,
      outcomeEntriesCount: fields[8] as int,
      isEncrypted: fields[9] as bool,
      encryptionIv: fields[10] as String?,
      encryptionTag: fields[11] as String?,
      isCompressed: fields[12] as bool,
      originalSize: fields[13] as int?,
      compressedSize: fields[14] as int?,
      compressionRatio: fields[15] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, BackupInfo obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.sizeBytes)
      ..writeByte(3)
      ..write(obj.deviceName)
      ..writeByte(4)
      ..write(obj.driveFileId)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.errorMessage)
      ..writeByte(7)
      ..write(obj.incomeEntriesCount)
      ..writeByte(8)
      ..write(obj.outcomeEntriesCount)
      ..writeByte(9)
      ..write(obj.isEncrypted)
      ..writeByte(10)
      ..write(obj.encryptionIv)
      ..writeByte(11)
      ..write(obj.encryptionTag)
      ..writeByte(12)
      ..write(obj.isCompressed)
      ..writeByte(13)
      ..write(obj.originalSize)
      ..writeByte(14)
      ..write(obj.compressedSize)
      ..writeByte(15)
      ..write(obj.compressionRatio);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BackupProgressAdapter extends TypeAdapter<BackupProgress> {
  @override
  final int typeId = 5;

  @override
  BackupProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BackupProgress(
      percentage: fields[0] as double,
      status: fields[1] as BackupStatus,
      currentAction: fields[2] as String,
      bytesTransferred: fields[3] as int,
      totalBytes: fields[4] as int,
      speedBytesPerSecond: fields[5] as double,
      estimatedCompletion: fields[6] as DateTime?,
      errorMessage: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BackupProgress obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.percentage)
      ..writeByte(1)
      ..write(obj.status)
      ..writeByte(2)
      ..write(obj.currentAction)
      ..writeByte(3)
      ..write(obj.bytesTransferred)
      ..writeByte(4)
      ..write(obj.totalBytes)
      ..writeByte(5)
      ..write(obj.speedBytesPerSecond)
      ..writeByte(6)
      ..write(obj.estimatedCompletion)
      ..writeByte(7)
      ..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RestoreProgressAdapter extends TypeAdapter<RestoreProgress> {
  @override
  final int typeId = 6;

  @override
  RestoreProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RestoreProgress(
      percentage: fields[0] as double,
      status: fields[1] as RestoreStatus,
      currentAction: fields[2] as String,
      bytesTransferred: fields[3] as int,
      totalBytes: fields[4] as int,
      errorMessage: fields[5] as String?,
      backupId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RestoreProgress obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.percentage)
      ..writeByte(1)
      ..write(obj.status)
      ..writeByte(2)
      ..write(obj.currentAction)
      ..writeByte(3)
      ..write(obj.bytesTransferred)
      ..writeByte(4)
      ..write(obj.totalBytes)
      ..writeByte(5)
      ..write(obj.errorMessage)
      ..writeByte(6)
      ..write(obj.backupId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestoreProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BackupSettingsAdapter extends TypeAdapter<BackupSettings> {
  @override
  final int typeId = 7;

  @override
  BackupSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BackupSettings(
      autoBackupEnabled: fields[0] as bool,
      frequency: fields[1] as BackupFrequency,
      lastBackupTime: fields[2] as DateTime?,
      nextScheduledBackup: fields[3] as DateTime?,
      backupOnWifiOnly: fields[4] as bool,
      includeImages: fields[5] as bool,
      googleAccountEmail: fields[6] as String?,
      maxBackupsToKeep: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BackupSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.autoBackupEnabled)
      ..writeByte(1)
      ..write(obj.frequency)
      ..writeByte(2)
      ..write(obj.lastBackupTime)
      ..writeByte(3)
      ..write(obj.nextScheduledBackup)
      ..writeByte(4)
      ..write(obj.backupOnWifiOnly)
      ..writeByte(5)
      ..write(obj.includeImages)
      ..writeByte(6)
      ..write(obj.googleAccountEmail)
      ..writeByte(7)
      ..write(obj.maxBackupsToKeep);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
