import 'dart:typed_data';
import 'package:coconut_vault/packages/bc-ur-dart/lib/cbor_lite.dart';
import 'package:coconut_vault/utils/conversion_util.dart';

class Cosigner {
  final String label; // 예: "Alice Tapsigner"
  final String masterFingerprintHex; // 8-hex, 예: A3B2EB70
  final String parentFingerprintHex; // 8-hex
  final Uint8List pubkey33; // 압축 공개키 33B
  final Uint8List chainCode32; // 체인코드 32B

  Cosigner({
    required this.label,
    required this.masterFingerprintHex,
    required this.parentFingerprintHex,
    required this.pubkey33,
    required this.chainCode32,
  });
}

/// 키스톤, 제이드 지갑에서 Wallet Export 시 사용하는 Legacy Account Descriptor 차용
/// 레거시 표준 문서는 온라인에서 찾지 못함. 키스톤과 제이드의 데이터를 활용
/// 코코넛 볼트는 Native Segwit만 지원
/// [param] coinType: mainnet=0, testnet=1
class LegacyAccountDescriptor {
  /// example
  /// {1: 2746411888, 2: [404(303({3: h'034D29046913C6B038311B6FCED327A8E2D9504A82510BBB92F9DAFA1DE598E466', 4: h'74963C6290A4C6C5BD66062432BA694BE8F05284B64451AB3CF7ACABC7315349', 6: 304({1: [84, true, 0, true, 0, true], 2: 2746411888, 3: 3}), 8: 2133551992}))]}
  static Uint8List buildSingleSigCbor({
    required String masterFingerprint,
    required String parentFingerprint,
    required Uint8List pubkey33,
    required Uint8List chainCode32,
    required int coinType,
    required int account,
  }) {
    final mfp = ConversionUtil.hexToInt(masterFingerprint); // 1: ..
    final parentFp = ConversionUtil.hexToInt(parentFingerprint); // 8: ...

    final enc = CBOREncoder();

    // 맵(2)
    enc.encodeMapSize(2);
    enc.encodeInteger(1);
    enc.encodeInteger(mfp);

    enc.encodeInteger(2);
    enc.encodeArraySize(1);

    // 404(303({...}))
    enc.encodeTagAndValue(CBORTag.majorSemantic, 404);
    enc.encodeTagAndValue(CBORTag.majorSemantic, 303);

    enc.encodeMapSize(4);

    // 3: pubkey
    enc.encodeInteger(3);
    enc.encodeBytes(pubkey33);

    // 4: chaincode
    enc.encodeInteger(4);
    enc.encodeBytes(chainCode32);

    // 6: 304({...})
    enc.encodeInteger(6);
    enc.encodeTagAndValue(CBORTag.majorSemantic, 304);
    enc.encodeMapSize(3);

    enc.encodeInteger(1);
    enc.encodeArraySize(6);
    enc.encodeInteger(84);
    enc.encodeBool(true);
    enc.encodeInteger(coinType);
    enc.encodeBool(true);
    enc.encodeInteger(account);
    enc.encodeBool(true);

    enc.encodeInteger(2);
    enc.encodeInteger(mfp);

    enc.encodeInteger(3);
    enc.encodeInteger(3);

    // 8: parent
    enc.encodeInteger(8);
    enc.encodeInteger(parentFp);

    //Logger.logLongString('--> buildSingleSigCbor: ${enc.getBytes().toString()}');
    return enc.getBytes();
  }

  /// example
  /// 401(407({1: 1, 2: [303({2: false, 3: h'034D29046913C6B038311B6FCED327A8E2D9504A82510BBB92F9DAFA1DE598E466', 4: h'74963C6290A4C6C5BD66062432BA694BE8F05284B64451AB3CF7ACABC7315349', 5: 305({1: 0, 2: 0}), 6: 304({1: [84, true, 0, true, 0, true], 2: 2746411888, 3: 3}), 8: 2133551992, 9: "noncelab1"}), 303({2: false, 3: h'029F95823802EAE9516A1B4316930DC003347251252F8A9B23FC1467EC5CAE84F8', 4: h'3439D61F48CB4B26A50BE64BFD579A4E704A903FF103FC33A8F719CB2812C698', 5: 305({1: 0, 2: 0}), 6: 304({1: [84, true, 0, true, 0, true], 2: 150316302, 3: 3}), 8: 1124271743, 9: "hidden"})]}))
  /// INFO: 305({1: 0, 2: 0}) 👉 1:0 | parent fingerprint = 0, 즉 master에서 직접 파생 / 2:0 | child index = 0
  /// INFO: 위 예제는 넌척에서 추출한 데이터인데, 지갑의 derivation path를 84'/0'/0'로 보여주고 있음. 48'/0'/0'/2가 표준이다
  static Uint8List buildMultisigCbor({
    required int requiredSignature,
    required int coinType,
    int account = 0,
    required List<Cosigner> cosigners, // N명의 cosigner
  }) {
    // --- sanity checks ---
    if (requiredSignature <= 0 || requiredSignature > cosigners.length) {
      throw ArgumentError('m must be in 1..N (N = cosigners.length)');
    }
    for (final c in cosigners) {
      if (c.masterFingerprintHex.length != 8 || c.parentFingerprintHex.length != 8) {
        throw ArgumentError('fingerprint hex must be 8 hex chars (4 bytes)');
      }
      if (c.pubkey33.length != 33) {
        throw ArgumentError('compressed public key must be 33 bytes');
      }
      if (c.chainCode32.length != 32) {
        throw ArgumentError('chain code must be 32 bytes');
      }
    }

    final enc = CBOREncoder();

    // ───────────────────────────────────────────────────────────────
    // 401( 407({ 1: m, 2: [ 303({...}), 303({...}), ... ] }) )
    // ───────────────────────────────────────────────────────────────
    enc.encodeTagAndValue(CBORTag.majorSemantic, 401); // outer
    enc.encodeTagAndValue(CBORTag.majorSemantic, 407); // container
    enc.encodeMapSize(2);

    enc.encodeInteger(1);
    enc.encodeInteger(requiredSignature);

    enc.encodeInteger(2);
    enc.encodeArraySize(cosigners.length);

    for (final c in cosigners) {
      final mfp = ConversionUtil.hexToInt(c.masterFingerprintHex);
      final parentFp = ConversionUtil.hexToInt(c.parentFingerprintHex);

      // 303({ ... }) : account entry
      enc.encodeTagAndValue(CBORTag.majorSemantic, 303);
      enc.encodeMapSize(7); // 아래 8개 키를 넣음: 2,3,4,5,6,8,9

      // 2: false  → 단일서명 지갑이 아님
      enc.encodeInteger(2);
      enc.encodeBool(false);

      // 3: pubkey (33B)
      enc.encodeInteger(3);
      enc.encodeBytes(c.pubkey33);

      // 4: chaincode (32B)
      enc.encodeInteger(4);
      enc.encodeBytes(c.chainCode32);

      // 5: 305({1:0, 2:0})  → key origin(부모/차일드) 기본값
      enc.encodeInteger(5);
      enc.encodeTagAndValue(CBORTag.majorSemantic, 305);
      enc.encodeMapSize(2);
      enc.encodeInteger(1);
      enc.encodeInteger(0); // parentFP=0 (루트)
      enc.encodeInteger(2);
      enc.encodeInteger(0); // child=0

      // 6: 304({1:[48', coin', account', 2'], 2:mfp, 3:4})
      // BIP48 P2WSH: m/48'/coin'/account'/2'
      enc.encodeInteger(6);
      enc.encodeTagAndValue(CBORTag.majorSemantic, 304);
      enc.encodeMapSize(3);

      // 6.1: path encoding
      enc.encodeInteger(1);
      const int pathArraySize = 8;
      enc.encodeArraySize(pathArraySize);
      enc.encodeInteger(48);
      enc.encodeBool(true); // 48'
      enc.encodeInteger(coinType);
      enc.encodeBool(true); // coin'
      enc.encodeInteger(account);
      enc.encodeBool(true); // account'
      enc.encodeInteger(2);
      enc.encodeBool(true); // 2'  (BIP48: p2wsh)

      // 6.2: source/master fingerprint
      enc.encodeInteger(2);
      enc.encodeInteger(mfp);

      // 6.3: depth = 4  (48'/coin'/account'/2')
      enc.encodeInteger(3);
      enc.encodeInteger(pathArraySize ~/ 2); // 6.1 (path encoding ArraySize / 2)

      // 8: parent fingerprint
      enc.encodeInteger(8);
      enc.encodeInteger(parentFp);

      // 9: label
      enc.encodeInteger(9);
      enc.encodeText(c.label);
    }

    /// for print
    // final bytes = enc.getBytes();
    // final bytesStr = bytes.toString();
    // const chunkSize = 100;

    // Logger.log('--> buildMultisigCbor length: ${bytesStr.length}');
    // for (var i = 0; i < bytesStr.length; i += chunkSize) {
    //   final end = (i + chunkSize < bytesStr.length) ? i + chunkSize : bytesStr.length;
    //   Logger.logLongString(
    //       '--> buildMultisigCbor chunk ${i ~/ chunkSize + 1}: ${bytesStr.substring(i, end)}');
    // }

    // Logger.logLongString(ConversionUtil.bytesToHex(bytes));
    return enc.getBytes();
  }
}
