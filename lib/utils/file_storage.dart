import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FileStorage {
  static Future<String> saveFile({
    required String fileName,
    required String content,
    String? subDirectory,
  }) async {
    final directory = await _getStorageDirectory(subDirectory);
    final file = File(path.join(directory.path, fileName));
    await file.writeAsString(content);
    return file.path;
  }

  static Future<List<String>> getFileList({String? subDirectory}) async {
    try {
      final directory = await _getStorageDirectory(subDirectory);
      if (!await directory.exists()) {
        return [];
      }

      final List<FileSystemEntity> entities = await directory.list().toList();
      return entities.whereType<File>().map((entity) => entity.path).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<String> readFile({
    required String fileName,
    String? subDirectory,
  }) async {
    final directory = await _getStorageDirectory(subDirectory);
    final file = File(path.join(directory.path, fileName));

    if (!await file.exists()) {
      throw FileSystemException('File not found', file.path);
    }

    return await file.readAsString();
  }

  static Future<Directory> _getStorageDirectory(String? subDirectory) async {
    final appDir = await getApplicationDocumentsDirectory();
    if (subDirectory == null) {
      return appDir;
    }

    final directory = Directory(path.join(appDir.path, subDirectory));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  static Future<void> deleteFile({
    required String fileName,
    String? subDirectory,
  }) async {
    final directory = await _getStorageDirectory(subDirectory);
    final file = File(path.join(directory.path, fileName));

    if (await file.exists()) {
      await file.delete();
    }
  }
}
