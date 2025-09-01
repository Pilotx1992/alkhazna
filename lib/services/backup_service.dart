
import 'dart:io';
import 'dart:typed_data';

import 'package:al_khazna/services/storage_service.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/digests/sha256.dart';

class BackupService {
  encrypt.Key _deriveKey(String password, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, 1000, 32));
    return encrypt.Key(
        derivator.process(Uint8List.fromList(password.codeUnits)));
  }

  Future<bool> createBackup(BuildContext context, {Function(String)? onProgress}) async {
    try {
      if (await _requestPermission()) {
        onProgress?.call('Getting password...');
        // ignore: use_build_context_synchronously
        final password = await _getPasswordFromUser(context, 'Create Backup');
        if (!context.mounted) return false;
        if (password == null || password.isEmpty) return false;

        onProgress?.call('Collecting data files...');
        final appDir = await getApplicationDocumentsDirectory();
        final archive = Archive();
        final dir = Directory(appDir.path);
        final baseDirPath = dir.path;
        final allFiles = dir.listSync(recursive: true).whereType<File>().toList();
        
        for (int i = 0; i < allFiles.length; i++) {
          final entity = allFiles[i];
          final relativePath = entity.path.substring(baseDirPath.length + 1);
          archive.addFile(ArchiveFile(
              relativePath, entity.lengthSync(), entity.readAsBytesSync()));
          onProgress?.call('Processing files... ${i + 1}/${allFiles.length}');
        }

        onProgress?.call('Compressing data...');
        final outputZip = ZipEncoder().encode(archive);

        onProgress?.call('Encrypting backup...');
        final salt = encrypt.IV.fromSecureRandom(8).bytes;
        final key = _deriveKey(password, salt);
        final iv = encrypt.IV.fromSecureRandom(16);

        final encrypter = encrypt.Encrypter(encrypt.AES(key));
        final encrypted = encrypter.encryptBytes(outputZip, iv: iv);

        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final fileName = 'alkhazna_backup_$timestamp.alk';

        onProgress?.call('Saving backup file...');
        final String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save your backup file',
          fileName: fileName,
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(salt + iv.bytes + encrypted.bytes);
          if (!context.mounted) return false;
          onProgress?.call('Backup completed successfully!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backup created successfully!\nSaved: ${file.path.split('\\').last}')),
          );
          return true;
        }
      }
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
      return false;
    }
    return false;
  }

  Future<bool> restoreBackup(BuildContext context, {String? path, Function(String)? onProgress}) async {
    try {
      if (await _requestPermission()) {
        String? backupFilePath = path;
        if (backupFilePath == null) {
          onProgress?.call('Selecting backup file...');
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['alk'],
          );
          if (result != null) {
            backupFilePath = result.files.single.path!;
          }
        }

        if (backupFilePath != null) {
          if (!context.mounted) return false;
          onProgress?.call('Getting password...');
          final password =
              await _getPasswordFromUser(context, 'Restore Backup');
          if (password == null || password.isEmpty) return false;

          onProgress?.call('Reading backup file...');
          final file = File(backupFilePath);
          final fileBytes = await file.readAsBytes();

          final salt = fileBytes.sublist(0, 8);
          final ivBytes = fileBytes.sublist(8, 24);
          final encryptedBytes = fileBytes.sublist(24);

          onProgress?.call('Decrypting backup...');
          final key = _deriveKey(password, salt);
          final iv = encrypt.IV(ivBytes);

          final encrypter = encrypt.Encrypter(encrypt.AES(key));
          final decryptedBytes =
              encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: iv);

          onProgress?.call('Extracting backup contents...');
          final archive = ZipDecoder().decodeBytes(decryptedBytes);

          onProgress?.call('Verifying backup integrity...');
          // Verify backup integrity in a temporary directory
          final tempDir = await getTemporaryDirectory();
          final tempRestorePath = '${tempDir.path}/restore_temp';
          final tempRestoreDir = Directory(tempRestorePath);
          if (tempRestoreDir.existsSync()) {
            tempRestoreDir.deleteSync(recursive: true);
          }
          tempRestoreDir.createSync(recursive: true);

          bool isValid = false;
          final totalFiles = archive.files.where((f) => f.isFile).length;
          int processedFiles = 0;
          
          for (final file in archive.files) {
            if (file.isFile) {
              final outputPath = '$tempRestorePath/${file.name}';
              File(outputPath)
                ..createSync(recursive: true)
                ..writeAsBytesSync(file.content as List<int>);
              if (file.name.contains(StorageService.incomeBoxName) ||
                  file.name.contains(StorageService.outcomeBoxName)) {
                isValid = true;
              }
              processedFiles++;
              onProgress?.call('Verifying backup... $processedFiles/$totalFiles');
            }
          }

          if (!isValid) {
            if (!context.mounted) return false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Restore failed: Backup file is invalid or corrupted.')),
            );
            return false;
          }

          onProgress?.call('Backing up current data...');
          // Backup current data before overwriting
          final appDir = await getApplicationDocumentsDirectory();
          final backupOfCurrentData =
              '${tempDir.path}/current_data_backup.zip';
          final archiveCurrent = Archive();
          if(appDir.existsSync()){
            final currentFiles = appDir.listSync(recursive: true).whereType<File>().toList();
            for (int i = 0; i < currentFiles.length; i++) {
              final entity = currentFiles[i];
              final relativePath =
                  entity.path.substring(appDir.path.length + 1);
              archiveCurrent.addFile(ArchiveFile(relativePath,
                  entity.lengthSync(), entity.readAsBytesSync()));
              onProgress?.call('Backing up current data... ${i + 1}/${currentFiles.length}');
            }
            final zipEncoder = ZipEncoder();
            final encodedArchive = zipEncoder.encode(archiveCurrent);
            File(backupOfCurrentData).writeAsBytesSync(encodedArchive);
          }

          onProgress?.call('Preparing for restore...');
          // Close Hive, clear data, and restore from temp
          await Hive.close();
          if(appDir.existsSync()){
            appDir.deleteSync(recursive: true);
          }
          appDir.createSync(recursive: true);

          onProgress?.call('Restoring data files...');
          final restoreFiles = Directory(tempRestorePath).listSync(recursive: true).whereType<File>().toList();
          for (int i = 0; i < restoreFiles.length; i++) {
            final file = restoreFiles[i];
            final relativePath = file.path.substring(tempRestorePath.length + 1);
            final newPath = '${appDir.path}/$relativePath';
            File(newPath).createSync(recursive: true);
            file.copySync(newPath);
            onProgress?.call('Restoring data files... ${i + 1}/${restoreFiles.length}');
          }
          
          tempRestoreDir.deleteSync(recursive: true);
          onProgress?.call('Restore completed successfully!');


          // ignore: use_build_context_synchronously
          await _showRestartDialog(context);
          if (!context.mounted) return false;
          return true;
        }
      }
    } catch (e) {
      if (!context.mounted) return false;
      
      // Try to rollback to the previously backed up current data
      try {
        final tempDir = await getTemporaryDirectory();
        final backupOfCurrentData = '${tempDir.path}/current_data_backup.zip';
        final backupFile = File(backupOfCurrentData);
        
        if (backupFile.existsSync()) {
          final appDir = await getApplicationDocumentsDirectory();
          
          // Clear corrupted data
          if (appDir.existsSync()) {
            appDir.deleteSync(recursive: true);
          }
          appDir.createSync(recursive: true);
          
          // Restore from backup
          final backupBytes = await backupFile.readAsBytes();
          final archive = ZipDecoder().decodeBytes(backupBytes);
          
          for (final file in archive.files) {
            if (file.isFile) {
              final outputPath = '${appDir.path}/${file.name}';
              File(outputPath)
                ..createSync(recursive: true)
                ..writeAsBytesSync(file.content as List<int>);
            }
          }
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Restore failed: $e\nYour original data has been recovered.')),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Restore failed: $e\nWarning: Unable to recover original data.')),
            );
          }
        }
      } catch (rollbackError) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restore failed: $e\nRollback failed: $rollbackError')),
          );
        }
      }
      
      return false;
    }
    return false;
  }

  Future<String?> _getPasswordFromUser(BuildContext context, String title) async {
    final passwordController = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(passwordController.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRestartDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restore Complete'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('The restore process is complete.'),
                Text('Please restart the application for the changes to take effect.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      try {
        // First try to request multiple permissions
        Map<Permission, PermissionStatus> statuses = await [
          Permission.storage,
          Permission.manageExternalStorage,
        ].request();
        
        // Check if any of the permissions were granted
        bool hasStoragePermission = statuses[Permission.storage]?.isGranted == true || 
                                   statuses[Permission.manageExternalStorage]?.isGranted == true;
        
        if (!hasStoragePermission) {
          // If not granted, try to open app settings
          openAppSettings();
          return false;
        }
        
        return hasStoragePermission;
      } catch (e) {
        // If permission check fails, still try to proceed
        // Some emulators don't require explicit permissions
        return true;
      }
    }
    return true;
  }
}
