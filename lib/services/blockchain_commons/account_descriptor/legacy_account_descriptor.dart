import 'dart:typed_data';
import 'package:coconut_vault/packages/bc-ur-dart/lib/cbor_lite.dart';
import 'package:coconut_vault/utils/conversion_util.dart';

/// 키스톤, 제이드 지갑에서 Wallet Export 시 사용하는 Legacy Account Descriptor 차용
/// 레거시 표준 문서는 온라인에서 찾지 못함. 키스톤과 제이드의 데이터를 활용
/// 코코넛 볼트는 Native Segwit만 지원
class LegacyAccountDescriptor {
  static Uint8List getLegacyAccountDescriptor(String masterFingerprint, String parentFingerprint,
      Uint8List extendedPubKey, Uint8List chainCode, bool isTestnet, bool isSingleSig) {
    if (isSingleSig) {
      return createForSingleSig(
          masterFingerprint, parentFingerprint, extendedPubKey, chainCode, isTestnet);
    } else {
      throw 'Not implemented';
    }
  }

  /// example
  /// {1: 2746411888, 2: [404(303({3: h'034D29046913C6B038311B6FCED327A8E2D9504A82510BBB92F9DAFA1DE598E466', 4: h'74963C6290A4C6C5BD66062432BA694BE8F05284B64451AB3CF7ACABC7315349', 6: 304({1: [84, true, 0, true, 0, true], 2: 2746411888, 3: 3}), 8: 2133551992}))]}
  static Uint8List createForSingleSig(String masterFingerprint, String parentFingerprint,
      Uint8List extendedPubKey, Uint8List chainCode, bool isTestnet) {
    final mfp = ConversionUtil.hexToInt(masterFingerprint); // 1: ..
    final parentMfp = ConversionUtil.hexToInt(parentFingerprint); // 8: ...

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
    enc.encodeBytes(extendedPubKey);

    // 4: chaincode
    enc.encodeInteger(4);
    enc.encodeBytes(chainCode);

    // 6: 304({...})
    enc.encodeInteger(6);
    enc.encodeTagAndValue(CBORTag.majorSemantic, 304);
    enc.encodeMapSize(3);

    enc.encodeInteger(1);
    enc.encodeArraySize(6);
    enc.encodeInteger(84);
    enc.encodeBool(true);
    enc.encodeInteger(isTestnet ? 1 : 0);
    enc.encodeBool(true);
    enc.encodeInteger(0);
    enc.encodeBool(true);

    enc.encodeInteger(2);
    enc.encodeInteger(mfp);

    enc.encodeInteger(3);
    enc.encodeInteger(3);

    // 8: parent
    enc.encodeInteger(8);
    enc.encodeInteger(parentMfp);

    return enc.getBytes();
  }
}
