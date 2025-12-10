import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/hardware_wallet_type_enum.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/packages/bc-ur-dart/lib/ur_decoder.dart';
import 'package:coconut_vault/utils/bb_qr/bb_qr_decoder.dart';
import 'package:coconut_vault/utils/bip/signer_bsms.dart';
import 'package:coconut_vault/utils/ur_bytes_converter.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/i_qr_scan_data_handler.dart';

class SignerBsmsQrDataHandler implements IQrScanDataHandler {
  final HardwareWalletType? hardwareWalletType;
  URDecoder _urDecoder;
  BbQrDecoder _bbQrDecoder;

  StringBuffer? _textBuffer;

  SignerBsmsQrDataHandler({this.hardwareWalletType = HardwareWalletType.coconutVault})
    : _urDecoder = URDecoder(),
      _bbQrDecoder = BbQrDecoder();

  @override
  dynamic get result {
    switch (hardwareWalletType) {
      case HardwareWalletType.keystone3Pro:
      case HardwareWalletType.jade:
        return UrBytesConverter.convertToMap(_urDecoder.result);
      case HardwareWalletType.coldcard:
        if (!_bbQrDecoder.isComplete) return null;
        if (_bbQrDecoder.dataType == 'J') {
          return _bbQrDecoder.parseJson();
        }
        return _bbQrDecoder.getCombinedText();
      case HardwareWalletType.seedSigner:
      case HardwareWalletType.krux:
      case HardwareWalletType.coconutVault:
        print('result: ${_textBuffer?.toString()}');
        return _textBuffer?.toString();
      default:
        return null;
    }
  }

  @override
  double get progress {
    switch (hardwareWalletType) {
      case HardwareWalletType.keystone3Pro:
      case HardwareWalletType.jade:
        return _urDecoder.estimatedPercentComplete();
      case HardwareWalletType.coldcard:
        return _bbQrDecoder.progress;
      case HardwareWalletType.seedSigner:
      case HardwareWalletType.krux:
      case HardwareWalletType.coconutVault:
        return isCompleted() ? 1.0 : 0.0;
      default:
        return 0.0;
    }
  }

  @override
  bool joinData(String data) {
    if (!validateFormat(data)) {
      return false;
    }

    switch (hardwareWalletType) {
      case HardwareWalletType.keystone3Pro:
      case HardwareWalletType.jade:
        return _urDecoder.receivePart(data);
      case HardwareWalletType.coldcard:
        return _bbQrDecoder.receivePart(data);
      case HardwareWalletType.seedSigner:
      case HardwareWalletType.krux:
      case HardwareWalletType.coconutVault:
        _textBuffer ??= StringBuffer();
        _textBuffer!.write(data);
        return true;
      default:
        return false;
    }
  }

  @override
  bool validateFormat(String data) {
    final normalized = data.trim().toLowerCase();

    try {
      switch (hardwareWalletType) {
        case HardwareWalletType.keystone3Pro:
        case HardwareWalletType.jade:
          return normalized.startsWith('ur:crypto-account/');
        case HardwareWalletType.coldcard:
          return normalized.startsWith('b\$');
        case HardwareWalletType.coconutVault:
          try {
            SignerBsms.parse(data.trim());
            return true;
          } catch (_) {
            return false;
          }
        case HardwareWalletType.seedSigner:
        case HardwareWalletType.krux:
          return _isValidSignerDescriptor(data.trim());
        default:
          return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  bool isCompleted() {
    switch (hardwareWalletType) {
      case HardwareWalletType.keystone3Pro:
      case HardwareWalletType.jade:
        return _urDecoder.isComplete();
      case HardwareWalletType.coldcard:
        return _bbQrDecoder.isComplete;
      case HardwareWalletType.coconutVault:
      case HardwareWalletType.seedSigner:
      case HardwareWalletType.krux:
        return _textBuffer != null && _textBuffer!.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  void reset() {
    _urDecoder = URDecoder();
    _bbQrDecoder = BbQrDecoder();
    _textBuffer = null;
  }

  bool _isValidSignerDescriptor(String input) {
    final match = RegExp(
      r'^\['
      r'([0-9a-fA-F]{8})'
      r'/'
      r'([^\]]+)'
      r'\]'
      r'([A-Za-z0-9]+)$',
    ).firstMatch(input.trim());

    if (match == null) {
      throw FormatException('Invalid signer descriptor format: $input');
    }

    final mfp = match.group(1)!;
    final path = match.group(2)!;
    final xpub = match.group(3)!;
    try {
      _validateFingerprint(mfp);
      _validateDerivationPath(path);
      _validateXpubPrefix(xpub);
    } catch (e) {
      rethrow;
    }

    return true;
  }

  void _validateFingerprint(String mfp) {
    final pattern = RegExp(r'^[0-9A-F]{8}$');
    if (!pattern.hasMatch(mfp.toUpperCase())) {
      throw FormatException('Invalid master fingerprint (must be 8-hex): $mfp');
    }
  }

  bool _validateDerivationPath(String path) {
    final pathSegments = path.split('/');
    final purpose = pathSegments[0];
    if (purpose != '48\'' && purpose != '48h' && purpose != '48H') {
      throw FormatException('Master fingerprint must start with 48\' or 48h or 48H: $path');
    }
    final coin = pathSegments[1];
    if (NetworkType.currentNetworkType.isTestnet
        ? coin != '1\'' && coin != '1h' && coin != '1H'
        : coin != '0\'' && coin != '0h' && coin != '0H') {
      throw FormatException('Network mismatch: $path');
    }
    final account = pathSegments[2];
    if (account != '0\'' && account != '0h' && account != '0H') {
      throw FormatException('Account must be 0\' or 0h or 0H: $path');
    }
    final scriptType = pathSegments[3];
    if (scriptType != '2\'' && scriptType != '2h' && scriptType != '2H') {
      throw FormatException('Change must be 2\' or 2h or 2H: $path');
    }
    return true;
  }

  void _validateXpubPrefix(String xpub) {
    final isMainnet = NetworkType.currentNetworkType == NetworkType.mainnet;

    final lower = xpub.toLowerCase();

    // Mainnet p2wsh prefixes
    const mainnetPrefixes = ['xpub', 'zpub', 'Zpub'];

    // Testnet p2wsh prefixes
    const testnetPrefixes = ['tpub', 'vpub', 'Vpub'];

    final validPrefixes = isMainnet ? mainnetPrefixes : testnetPrefixes;

    final match = validPrefixes.any((p) => lower.startsWith(p.toLowerCase()));

    if (!match) {
      throw FormatException('Invalid extended key prefix for ${isMainnet ? "mainnet" : "testnet"}: $xpub');
    }
  }
}
