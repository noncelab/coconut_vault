import 'package:coconut_vault/constants/secure_storage_keys.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/secure_key_generator.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:coconut_vault/utils/aes_crypto.dart';
import 'package:coconut_vault/utils/file_storage.dart';
import 'package:path/path.dart' as path;
import 'package:coconut_vault/utils/isolate_handler.dart';

class UpdatePreparation {
  static const String directory = 'backup';

  /// 백업 파일의 기본 이름 형식
  static const String fileNameFormat = 'coconut_backup_%s.bak';
  static final RegExp regex = RegExp(r'^coconut_backup_.*\.bak$');

  static Future<String> encryptAndSave({required String data}) async {
    await clearUpdatePreparationStorage();

    // Isolate를 사용하여 키 생성과 암호화 수행
    final encryptor = IsolateHandler<String, Map<String, String>>((String data) => _encrypt(data));
    final result = await encryptor.execute(data);

    // 암호화된 데이터와 IV를 ':' 로 구분하여 저장
    final fileContent = '${result['iv']}:${result['encrypted']}';

    final timestamp = DateTime.now().toIso8601String();
    final fileName = fileNameFormat.replaceAll('%s', timestamp);

    final savedPath = await FileStorage.saveFile(fileName: fileName, content: fileContent, subDirectory: directory);

    // 암호화에 사용한 key를 저장
    await SecureStorageRepository().write(key: SecureStorageKeys.kAes256Key, value: result['key'] as String);

    await validatePreparationState();
    return savedPath;
  }

  static Future<String> readAndDecrypt() async {
    await validatePreparationState();
    final file = await _getEncryptedFiles();
    final fileContent = await FileStorage.readFile(fileName: path.basename(file.first), subDirectory: directory);

    // IV와 암호화된 데이터 분리
    final parts = fileContent.split(':');
    if (parts.length != 2) {
      throw const FormatException('Invalid encrypted file format');
    }

    Logger.log('keyString: ${await SecureStorageRepository().read(key: SecureStorageKeys.kAes256Key)}');

    // 복호화
    final decryptedData = Aes256Crypto.decryptWithIvCbc(
      encryptedData: {'encrypted': parts[1], 'iv': parts[0]},
      key: encrypt.Key.fromBase64(await SecureStorageRepository().read(key: SecureStorageKeys.kAes256Key) ?? ''),
    );

    return decryptedData;
  }

  static Future<List<String>> _getEncryptedFiles() async {
    final files = await FileStorage.getFileList(subDirectory: directory);
    return files;
  }

  static Future<void> clearUpdatePreparationStorage() async {
    final files = await _getEncryptedFiles();
    for (final file in files) {
      await FileStorage.deleteFile(fileName: file, subDirectory: directory);
    }

    await SecureStorageRepository().delete(key: SecureStorageKeys.kAes256Key);
  }

  static Future<void> validatePreparationState() async {
    final files = await _getEncryptedFiles();
    if (files.length != 1) {
      throw AssertionError('Invalid number of encrypted files: ${files.length}');
    }

    if (!regex.hasMatch(path.basename(files.first))) {
      throw FormatException('Invalid encrypted file format: ${path.basename(files.first)}');
    }

    if (await SecureStorageRepository().read(key: SecureStorageKeys.kAes256Key) == null) {
      throw AssertionError('Aes256Key is not found');
    }
  }

  /// 데이터 암호화를 수행하는 메소드
  static Map<String, String> _encrypt(String data) {
    final String keyString = SecureKeyGenerator.generateSecureKeyWithEntropy();
    final encrypt.Key key = encrypt.Key.fromBase64(keyString);

    final encryptedData = Aes256Crypto.encryptWithIvCbc(data: data, key: key);

    return {...encryptedData, 'key': keyString};
  }

  /// 암호화된 데이터가 준비되었는지 확인하는 메소드, 복원 가능 상태 인지 확인
  static Future<bool> isRestorationPrepared() async {
    try {
      await UpdatePreparation.validatePreparationState();
      return true;
    } catch (_) {
      return false;
    }
  }
}
