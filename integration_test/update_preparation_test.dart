import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:coconut_vault/utils/coconut/update_preparation.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/constants/secure_storage_keys.dart';

/// 백업 데이터 암호화/복호화 및 파일 저장 기능 테스트
///
/// 실행 명령어:
/// ```bash
/// # 디버그 모드 (기본)
/// flutter test integration_test/update_preparation_test.dart --flavor regtest
/// # release 모드
/// flutter test integration_test/update_preparation_test.dart --flavor regtest --release
/// ```
///
/// 자세한 내용은 README.md 참고
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UpdatePreparation Integration Tests', () {
    tearDown(() async {
      // 각 테스트 후 암호화된 파일들과 저장된 키 삭제
      await UpdatePreparation.deleteAllEncryptedFiles();
      await SecureStorageRepository().delete(key: SecureStorageKeys.kAes256Key);
    });

    testWidgets('Full backup process test', (tester) async {
      // Given
      const testData = '''
      [{"id":1,"name":"111111","colorIndex":0,"iconIndex":0,"vaultType":"singleSignature","secret":{"mnemonic":"symptom hen guide profit step wave decade long inflict quiz rug practice","passphrase":""},"passphrase":null,"linkedMultisigInfo":{"3":0,"4":1},"signerBsms":"BSMS 1.0\n00\n[8A2A58CE/48'/1'/0'/2']Vpub5mh3sv4fojqGuedoauYuNMNe5iThMY6VvdazeQWkdyQNVbszbaopZ6B1EsqPfuevfQPgmwkKcbdsQ8qnCBuVHEHz8G9MY9JHrpk81GQuUUd\n111111"},{"id":2,"name":"22222","colorIndex":0,"iconIndex":0,"vaultType":"singleSignature","secret":{"mnemonic":"finger story abstract parade analyst pencil throw rookie before birth broom bless swim legend skate credit video tortoise half swim pulse reject nominee blouse","passphrase":"zzz"},"passphrase":null,"linkedMultisigInfo":{"3":1},"signerBsms":"BSMS 1.0\n00\n[E4371CB7/48'/1'/0'/2']Vpub5n5zHLd4mJm4DuSsyQh1be4inAcBVTmmpVxUZX7fbd3zPuazDgzwJebQcANgepjCXb7Doe5aopn7seRin74ax48igtpBhcmWEwQDk7rLbtw\n22222"},{"id":3,"name":"33333","colorIndex":4,"iconIndex":0,"vaultType":"multiSignature","signers":rage:{"id":0,"innerVaultId":1,"name":"111111","iconIndex":0,"colorIndex":0,"signerBsms":"BSMS 1.0\n00\n[8A2A58CE/48'/1'/0'/2']Vpub5mh3sv4fojqGuedoauYuNMNe5iThMY6VvdazeQWkdyQNVbszbaopZ6B1EsqPfuevfQPgmwkKcbdsQ8qnCBuVHEHz8G9MY9JHrpk81GQuUUd\n111111","memo":null,"keyStore":"{\"fingerprint\":\"8A2A58CE\",\"hdWallet\":\"{\\"publicKey\\":\\"02f278734c3e2ca6805ab0710fe8ef509570eae42bd17777fca039127359d34680\\",\\"chainCode\\":\\"03b74945b5affd75e29c1c6cca66c3598c6aeb27742207ac7c50812ec831e0c8\\"}\",\"extendedPublicKey\":\"Vpub5mh3sv4fojqGuedoauYuNMNe5iThMY6VvdazeQWkdyQNVbszbaopZ6B1EsqPfuevfQPgmwkKcbdsQ8qnCBuVHEHz8G9MY9JHrpk81GQuUUd\"}"},{"id":1,"innerVaultId":2,"name":"22222","iconIndex":0,"colorIndex":0,"signerBsms":"BSMS 1.0\n00\n[E4371CB7/48'/1'/0'/2']Vpub5n5zHLd4mJm4DuSsyQh1be4inAcBVTmmpVxUZX7fbd3zPuazDgzwJebQcANgepjCXb7Doe5aopn7seRin74ax48igtpBhcmWEwQDk7rLbtw\n22222","memo":null,"keyStore":"{\"fingerprint\":\"E4371CB7\",\"hdWallet\":\"{\\"publicKey\\":\\"020ae3d20b33e50f19feffc102bf3a7cb96f0b616dd8cbb55355337aa6c2c81bea\\",\\"chainCode\\":\\"d5a6a024a257b645f8ff7d0ab7a0ed64cc690a68fb314f4746eb028d80a72070\\"}\",\"extendedPublicKey\":\"Vpub5n5zHLd4mJm4DuSsyQh1be4inAcBVTmmpVxUZX7fbd3zPuazDgzwJebQcANgepjCXb7Doe5aopn7seRin74ax48igtpBhcmWEwQDk7rLbtw\"}"}],"coordinatorBsms":"BSMS 1.0\nwsh(sortedmulti(2,[8A2A58CE/48'/1'/0'/2']Vpub5mh3sv4fojqGuedoauYuNMNe5iThMY6VvdazeQWkdyQNVbszbaopZ6B1EsqPfuevfQPgmwkKcbdsQ8qnCBuVHEHz8G9MY9JHrpk81GQuUUd/<0;1>/,[E4371CB7/48'/1'/0'/2']Vpub5n5zHLd4mJm4DuSsyQh1be4inAcBVTmmpVxUZX7fbd3zPuazDgzwJebQcANgepjCXb7Doe5aopn7seRin74ax48igtpBhcmWEwQDk7rLbtw/<0;1>/))#ufjhskus\n/0/,/1/\nbcrt1q4fkg8w5rw6pzz0cs0kcw7n86qph6wksuvvs78lrd5h96r7wq48qsrkrtcg","requiredSignatureCount":2},{"id":4,"name":"44444","colorIndex":3,"iconIndex":0,"vaultType":"multiSignature","signers":rage:{"id":0,"innerVaultId":null,"name":"iancol","iconIndex":null,"colorIndex":null,"signerBsms":"BSMS 1.0\n00\n[7BCA66CA/48'/1'/0'/2']Vpub5my53f6xJLRG7p9G9h5JkgomZhp8hmJSTd6otwNxgW68dxrvZFK8uD85wCFHT3B2ZRQBCwV3g8gcWrzhXszFnfnkFeQTnENipzDB8mjpXA4\niancol","memo":"hhh","keyStore":"{\"fingerprint\":\"7BCA66CA\",\"hdWallet\":\"{\\"publicKey\\":\\"035a6a41fcae7180daa89a1cfeead477a0c80ed1d3731aad8d64077f18d73d13b8\\",\\"chainCode\\":\\"521039585f6263c06908e291a4458c7f2bf137d8803c4f5a9d84cbf8ad7a8f49\\"}\",\"extendedPublicKey\":\"Vpub5my53f6xJLRG7p9G9h5JkgomZhp8hmJSTd6otwNxgW68dxrvZFK8uD85wCFHT3B2ZRQBCwV3g8gcWrzhXszFnfnkFeQTnENipzDB8mjpXA4\"}"},{"id":1,"innerVaultId":1,"name":"111111","iconIndex":0,"colorIndex":0,"signerBsms":"BSMS 1.0\n00\n[8A2A58CE/48'/1'/0'/2']Vpub5mh3sv4fojqGuedoauYuNMNe5iThMY6VvdazeQWkdyQNVbszbaopZ6B1EsqPfuevfQPgmwkKcbdsQ8qnCBuVHEHz8G9MY9JHrpk81GQuUUd\n111111","memo":null,"keyStore":"{\"fingerprint\":\"8A2A58CE\",\"hdWallet\":\"{\\"publicKey\\":\\"02f278734c3e2ca6805ab0710fe8ef509570eae42bd17777fca039127359d34680\\",\\"chainCode\\":\\"03b74945b5affd75e29c1c6cca66c3598c6aeb27742207ac7c50812ec831e0c8\\"}\",\"extendedPublicKey\":\"Vpub5mh3sv4fojqGuedoauYuNMNe5iThMY6VvdazeQWkdyQNVbszbaopZ6B1EsqPfuevfQPgmwkKcbdsQ8qnCBuVHEHz8G9MY9JHrpk81GQuUUd\"}"}],"coordinatorBsms":"BSMS 1.0\nwsh(sortedmulti(2,[7BCA66CA/48'/1'/0'/2']Vpub5my53f6xJLRG7p9G9h5JkgomZhp8hmJSTd6otwNxgW68dxrvZFK8uD85wCFHT3B2ZRQBCwV3g8gcWrzhXszFnfnkFeQTnENipzDB8mjpXA4/<0;1>/,[8A2A58CE/48'/1'/0'/2']Vpub5mh3sv4fojqGuedoauYuNMNe5iThMY6VvdazeQWkdyQNVbszbaopZ6B1EsqPfuevfQPgmwkKcbdsQ8qnCBuVHEHz8G9MY9JHrpk81GQuUUd/<0;1>/))#dgfd9lmx\n/0/,/1/\nbcrt1q6mscnngp9da2khf4u7jq3ejulpzfgvslkjtckc3q726wrq0dhg7qz30y2e","requiredSignatureCount":2}]
      ''';

      // When: 데이터 암호화 및 저장
      final savedPath = await UpdatePreparation.encryptAndSave(data: testData);
      expect(savedPath, isNotEmpty);

      // And: 저장된 데이터 복호화 및 검증
      final decryptedData = await UpdatePreparation.readAndDecrypt();
      expect(decryptedData, testData);
    });
  });
}
