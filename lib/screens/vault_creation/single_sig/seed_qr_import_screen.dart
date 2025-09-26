import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/seed_qr_confirmation_screen.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:coconut_vault/widgets/overlays/scanner_overlay.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SeedQrImportScreen extends StatefulWidget {
  const SeedQrImportScreen({super.key});

  @override
  State<SeedQrImportScreen> createState() => _SeedQrImportScreenState();
}

class _SeedQrImportScreenState extends State<SeedQrImportScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  MobileScannerController? _controller;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (_controller != null) {
      _controller!.pause();
      _controller!.start();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(context: context, title: t.seed_qr_import_screen.title),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onQRViewCreated),
          const ScannerOverlay(),
          CustomTooltip.buildInfoTooltip(
            context,
            richText: RichText(
              text: TextSpan(
                style: CoconutTypography.body3_12,
                children: [
                  TextSpan(
                    text: t.seed_qr_import_screen.guide,
                    style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black),
                  ),
                ],
              ),
            ),
            isBackgroundWhite: false,
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(BarcodeCapture capture) {
    final codes = capture.barcodes;
    if (codes.isEmpty) return;

    final barcode = codes.first;

    if (_isNavigating) return;
    var words = <String>[];

    try {
      if (barcode.rawValue == null && barcode.rawBytes != null) {
        words = _decodeCompactQR(barcode.rawBytes!);
      } else if (barcode.rawValue != null && barcode.rawBytes != null) {
        words = _decodeStandardQR(barcode.rawValue!);
      }
    } catch (e) {
      // FormatException: Invalid radix-10 number 인 경우, rawBytes로 파싱
      if (e is FormatException && e.message.contains('Invalid radix-10 number')) {
        words = _decodeCompactQR(barcode.rawBytes!);
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) {
              return CoconutPopup(
                title: t.seed_qr_import_screen.error_title,
                description: '${t.seed_qr_import_screen.error_message}: $e',
                leftButtonText: t.cancel,
                rightButtonText: t.confirm,
                onTapRight: () => Navigator.of(context).pop(),
              );
            },
          );
        }
        return;
      }
    }

    if (words.length == 12 || words.length == 24) {
      if (mounted) {
        _isNavigating = true;

        // 1. 네비게이션하기 전 카메라 끄기
        _controller?.pause();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SeedQrConfirmationScreen(scannedData: utf8.encode(words.join(' ')))),
        ).then((_) {
          // 2. 돌아왔을 때 카메라 재개하기
          if (mounted) {
            _controller?.start();
          }
          setState(() {
            _isNavigating = false;
          });
        });
      }
    }
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

  List<String> _decodeCompactQR(List<int> bytes) {
    final wordCount = _detectMnemonicWords(bytes);
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
