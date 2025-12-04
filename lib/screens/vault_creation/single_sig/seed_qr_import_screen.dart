import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/providers/app_lifecycle_state_provider.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/seed_qr_confirmation_screen.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// mobile_scanner 이슈로
/// 이 화면만 qr_code_scanner_plus 사용
class SeedQrImportScreen extends StatefulWidget {
  final MultisigSigner? externalSigner;
  final int? multisigVaultIdOfExternalSigner;
  const SeedQrImportScreen({super.key, this.externalSigner, this.multisigVaultIdOfExternalSigner});

  @override
  State<SeedQrImportScreen> createState() => _SeedQrImportScreenState();
}

class _SeedQrImportScreenState extends State<SeedQrImportScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isNavigating = false;
  bool _isProcessing = false;
  Barcode? result;
  late AppLifecycleStateProvider _appLifecycleStateProvider;

  @override
  void initState() {
    super.initState();
    _appLifecycleStateProvider = Provider.of<AppLifecycleStateProvider>(context, listen: false);
    _appLifecycleStateProvider.startOperation(AppLifecycleOperations.cameraAuthRequest, ignoreNotify: true);
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  void dispose() {
    if (_appLifecycleStateProvider.ignoredOperations.contains(AppLifecycleOperations.cameraAuthRequest)) {
      _appLifecycleStateProvider.endOperation(AppLifecycleOperations.cameraAuthRequest);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        context: context,
        title: t.seed_qr_import_screen.title,
        backgroundColor: CoconutColors.white,
      ),
      body: Stack(
        children: [
          _buildQrView(context),
          CustomTooltip.buildInfoTooltip(
            context,
            richText: RichText(
              text: TextSpan(
                style: CoconutTypography.body2_14,
                children: [
                  TextSpan(
                    text: t.seed_qr_import_screen.guide,
                    style: CoconutTypography.body2_14.copyWith(height: 1.3, color: CoconutColors.black),
                  ),
                ],
              ),
            ),
            paddingTop: 20,
            isBackgroundWhite: false,
          ),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea =
        (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400)
            ? 320.0
            : MediaQuery.of(context).size.width * 0.85;

    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        overlayColor: CoconutColors.black.withValues(alpha: 0.45),
        borderColor: CoconutColors.white,
        borderRadius: 10,
        borderLength: scanArea * 0.5,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    List<String>? words;
    controller.scannedDataStream.listen((scanData) {
      if (_isNavigating || _isProcessing) return;
      _isProcessing = true;

      try {
        if (scanData.code == null && scanData.rawBytes != null) {
          words = _decodeCompactQR(scanData.rawBytes!);
        } else if (scanData.code != null && scanData.rawBytes != null) {
          words = _decodeStandardQR(scanData.code!);
        }
      } catch (e) {
        if (e is FormatException && e.message.contains('Invalid radix-10 number')) {
          words = _decodeCompactQR(scanData.rawBytes!);
          if (words == null) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) {
                  return CoconutPopup(
                    title: t.seed_qr_import_screen.format_error_title,
                    description: t.seed_qr_import_screen.format_error_message,
                    onTapRight: () {
                      _isProcessing = false;
                      Navigator.of(context).pop();
                    },
                  );
                },
              );
            }
          }
        } else {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) {
                return CoconutPopup(
                  title: t.seed_qr_import_screen.error_title,
                  description: '${t.seed_qr_import_screen.error_message}: $e',
                  onTapRight: () {
                    _isProcessing = false;
                    Navigator.of(context).pop();
                  },
                );
              },
            );
          }
          return;
        }
      }

      if (words != null && (words!.length == 12 || words!.length == 24)) {
        if (mounted) {
          _isNavigating = true;
          // 1. 네비게이션하기 전 카메라 끄기
          controller.pauseCamera();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SeedQrConfirmationScreen(
                    scannedData: utf8.encode(words!.join(' ')),
                    externalSigner: widget.externalSigner,
                    multisigVaultIdOfExternalSigner: widget.multisigVaultIdOfExternalSigner,
                  ),
            ),
          ).then((_) {
            // 2. 돌아왔을 때 카메라 재개하기
            if (mounted) {
              controller.resumeCamera();
            }
            setState(() {
              _isNavigating = false;
              _isProcessing = false;
            });
          });
        }
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    _appLifecycleStateProvider.endOperation(AppLifecycleOperations.cameraAuthRequest);
  }

  List<String> _decodeStandardQR(String data) {
    final words = <String>[];
    final indexes = <int>[];
    for (var i = 0; i < data.length; i += 4) {
      final idx = int.parse(data.substring(i, i + 4));
      indexes.add(idx);
      words.add(wordList[idx]);
    }
    return words;
  }

  List<String>? _decodeCompactQR(List<int> bytes) {
    var wordCount = 0;
    try {
      wordCount = _detectMnemonicWords(bytes);
    } catch (e) {
      return null;
    }
    // 12-word: 128 bits, 24-word: 256 bits
    List<int> usefulBits = _getUsefulBits(bytes, wordCount);

    // 12-word: 132 bits (checksum: 4 bits), 24-word: 264 bits (checksum: 8 bits)
    int expectedLength = wordCount == 12 ? 132 : 264;

    // 부족한 비트 0으로 채우고 초과하는 비트는 자름
    List<int> paddedBits = List.from(usefulBits);
    while (paddedBits.length < expectedLength) {
      paddedBits.add(0);
    }
    if (paddedBits.length > expectedLength) {
      paddedBits = paddedBits.sublist(0, expectedLength);
    }

    // 11 bit로 끊어 인덱스 계산
    final indices = <int>[];
    List<String> words = [];
    for (var i = 0; i < paddedBits.length; i += 11) {
      final index = _bitsToInt(paddedBits.sublist(i, i + 11));
      indices.add(index);
      words.add(wordList[index]);
    }

    // 체크섬 계산
    int checksum = _computeChecksum(paddedBits, wordCount);
    // 마지막 단어 인덱스 계산
    int lastIndex = indices[indices.length - 1] + checksum;

    words.replaceRange(words.length - 1, words.length, [wordList[lastIndex]]);
    return words;
  }

  int _detectMnemonicWords(List<int> rawBytes) {
    final len = rawBytes.length;

    // CompactSeedQR 규칙
    // - 12-word: 약 16~20 bytes / 실제 132 bits ≈ 17 bytes + padding
    // - 24-word: 약 32~36 bytes / 실제 264 bits ≈ 33 bytes + padding
    if (len <= 20) {
      return 12;
    } else if (len <= 36) {
      return 24;
    } else {
      throw ArgumentError("Unsupported CompactSeedQR length: $len (must be 12 or 24 words)");
    }
  }

  List<int> _getUsefulBits(List<int> bytes, int wordCount) {
    final bits = <int>[];
    for (final b in bytes) {
      for (int i = 7; i >= 0; i--) {
        // MSB-first
        bits.add((b >> i) & 1);
      }
    }

    if (bits.length < 3 * 8) {
      throw Exception('Invalid QR data: too short');
    }

    if (wordCount == 12) {
      if (bits[0] == 0 &&
          bits[1] == 1 &&
          bits[2] == 0 &&
          bits[3] == 0 &&
          bits[4] == 0 &&
          bits[5] == 0 &&
          bits[6] == 0 &&
          bits[7] == 1 &&
          bits[8] == 0 &&
          bits[9] == 0 &&
          bits[10] == 0 &&
          bits[11] == 0 &&
          bits[bits.length - 12] == 0 &&
          bits[bits.length - 11] == 0 &&
          bits[bits.length - 10] == 0 &&
          bits[bits.length - 9] == 0 &&
          bits[bits.length - 8] == 1 &&
          bits[bits.length - 7] == 1 &&
          bits[bits.length - 6] == 1 &&
          bits[bits.length - 5] == 0 &&
          bits[bits.length - 4] == 1 &&
          bits[bits.length - 3] == 1 &&
          bits[bits.length - 2] == 0 &&
          bits[bits.length - 1] == 0) {
        return bits.sublist(12, bits.length - 12);
      }
    }

    if (wordCount == 24) {
      if (bits[0] == 0 &&
          bits[1] == 1 &&
          bits[2] == 0 &&
          bits[3] == 0 &&
          bits[4] == 0 &&
          bits[5] == 0 &&
          bits[6] == 1 &&
          bits[7] == 0 &&
          bits[8] == 0 &&
          bits[9] == 0 &&
          bits[10] == 0 &&
          bits[11] == 0 &&
          bits[bits.length - 4] == 0 &&
          bits[bits.length - 3] == 0 &&
          bits[bits.length - 2] == 0 &&
          bits[bits.length - 1] == 0) {
        return bits.sublist(12, bits.length - 4);
      }
    }

    return bits.sublist(12);
  }

  int _bitsToInt(List<int> bits) {
    var val = 0;
    for (final bit in bits) {
      val = (val << 1) | bit;
    }
    return val;
  }

  int _computeChecksum(List<int> bits, int wordCount) {
    int entropyLength = wordCount == 12 ? 128 : 256;
    int checksumLength = wordCount == 12 ? 4 : 8;

    int entropyBytesLength = entropyLength ~/ 8; // 128/8=16, 256/8=32
    Uint8List entropyBytes = Uint8List(entropyBytesLength);
    for (int i = 0; i < entropyLength; i++) {
      int byteIndex = i ~/ 8;
      entropyBytes[byteIndex] |= bits[i] << (7 - (i % 8));
    }

    Digest hash = sha256.convert(entropyBytes);
    int mask = (1 << checksumLength) - 1; // 4비트면 0x0F, 8비트면 0xFF
    int checksum = (hash.bytes[0] >> (8 - checksumLength)) & mask;
    return checksum;
  }
}
