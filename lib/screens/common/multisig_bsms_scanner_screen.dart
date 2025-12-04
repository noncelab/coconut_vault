import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/app_routes_params.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/model/exception/not_related_multisig_wallet_exception.dart';
import 'package:coconut_vault/providers/app_lifecycle_state_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:coconut_vault/widgets/overlays/scanner_overlay.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

enum MultisigBsmsImportType { add, copy }

// Usage:
// MultisigBsmsImportType.copy(다중 서명 지갑 가져오기) from  [home/vault_menu_bottom_sheet.dart]
// MultisigBsmsImportType.add(signer 할당) from [vault_creation/multisig/signer_assignment_screen.dart]
class MultisigBsmsScannerScreen extends StatefulWidget {
  final int? id;
  final MultisigBsmsImportType screenType;
  const MultisigBsmsScannerScreen({super.key, this.id, this.screenType = MultisigBsmsImportType.add});

  @override
  State<MultisigBsmsScannerScreen> createState() => _MultisigBsmsScannerScreenState();
}

class _MultisigBsmsScannerScreenState extends State<MultisigBsmsScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  static String wrongFormatMessage1 = t.errors.invalid_single_sig_qr_error;
  static String wrongFormatMessage2 = t.errors.invalid_multisig_qr_error;

  late WalletProvider _walletProvider;
  late VisibilityProvider _visibilityProvider;
  late AppLifecycleStateProvider _appLifecycleStateProvider;

  MobileScannerController? _controller;
  StreamSubscription? _scanSubscription;
  bool isCameraActive = false;
  bool isAlreadyVibrateScanFailed = false;
  bool _isProcessing = false;
  bool _isSignerAssignmentContext = false;

  /// for hot reload (not work in prod)
  /// 카메라가 실행 중일 때 Hot reload로 인해 중단되는 문제를 해결하기 위해 사용
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _controller?.pause();
    } else if (Platform.isIOS) {
      _controller?.start();
    }
  }

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _visibilityProvider = Provider.of<VisibilityProvider>(context, listen: false);
    _isSignerAssignmentContext = widget.screenType == MultisigBsmsImportType.add;
    _appLifecycleStateProvider = Provider.of<AppLifecycleStateProvider>(context, listen: false);
    _appLifecycleStateProvider.startOperation(AppLifecycleOperations.cameraAuthRequest, ignoreNotify: true);
    _controller = MobileScannerController()..addListener(_onCameraStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 1000));
      // fixme 추후 QRCodeScanner가 개선되면 QRCodeScanner 의 카메라 뷰 생성 완료된 콜백 찾아 progress hide 합니다. 현재는 1초 후 hide
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _controller?.removeListener(_onCameraStateChanged);
    _controller?.dispose();
    if (_appLifecycleStateProvider.ignoredOperations.contains(AppLifecycleOperations.cameraAuthRequest)) {
      _appLifecycleStateProvider.endOperation(AppLifecycleOperations.cameraAuthRequest);
    }
    super.dispose();
  }

  void onFailedScanning(String message) {
    showDialog(
      context: context,
      builder:
          (context) => CoconutPopup(
            title: t.errors.scan_error_title,
            description: message,
            rightButtonText: t.confirm,
            onTapRight: () {
              Navigator.pop(context);
              if (!mounted) return;
              setState(() {
                _isProcessing = false;
              });
            },
          ),
    );
  }

  void _onCameraStateChanged() {
    if (_controller!.value.isInitialized) {
      _appLifecycleStateProvider.endOperation(AppLifecycleOperations.cameraAuthRequest);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CoconutAppBar.build(
        title:
            _isSignerAssignmentContext
                ? t.bsms_scanner_screen.import_bsms
                : t.bsms_scanner_screen.import_multisig_wallet,
        context: context,
        isBottom: true,
        isBackButton: widget.screenType == MultisigBsmsImportType.copy,
      ),
      body: _buildStack(context),
    );
  }

  Stack _buildStack(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _isSignerAssignmentContext ? _onQRViewCreatedWhenScanSigner : _onQRViewCreatedWhenScanCoordinator,
        ),
        const ScannerOverlay(),
        Container(height: _isSignerAssignmentContext ? 50.1 : 0, color: CoconutColors.black.withValues(alpha: 0.5)),
        CustomTooltip.buildInfoTooltip(
          context,
          richText: RichText(text: TextSpan(style: CoconutTypography.body2_14, children: _getTooltipRichText())),
          isBackgroundWhite: false,
        ),
        Visibility(
          visible: _isProcessing,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(color: CoconutColors.black.withValues(alpha: 0.3)),
            child: const Center(child: CircularProgressIndicator(color: CoconutColors.gray800)),
          ),
        ),
      ],
    );
  }

  /// 다중서명지갑 생성 시 외부에서 Signer를 스캔합니다.
  void _onQRViewCreatedWhenScanSigner(BarcodeCapture capture) {
    if (_isProcessing) return;

    if (!mounted) return;
    setState(() {
      _isProcessing = true;
    });

    final codes = capture.barcodes;
    if (codes.isEmpty) return;

    final barcode = codes.first;
    if (barcode.rawValue == null) return;

    final scanData = barcode.rawValue!;

    try {
      // Signer 형식이 맞는지 체크
      Bsms.parseSigner(scanData);
    } catch (e) {
      onFailedScanning(wrongFormatMessage1);
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, scanData);
    return;
  }

  /// 다른 볼트에 있는 다중서명지갑을 복사합니다.
  void _onQRViewCreatedWhenScanCoordinator(BarcodeCapture capture) async {
    if (_isProcessing) return;

    if (!mounted) return;
    setState(() {
      _isProcessing = true;
    });

    final codes = capture.barcodes;
    if (codes.isEmpty) return;

    final barcode = codes.first;
    if (barcode.rawValue == null) return;

    final scanData = barcode.rawValue!;
    MultisigImportDetail decodedData;
    String coordinatorBsms;
    Map<String, dynamic> decodedJson;
    // CoordinatorBSMS 형식이 맞는지 체크
    try {
      decodedJson = jsonDecode(scanData);
      decodedData = MultisigImportDetail.fromJson(decodedJson);
      coordinatorBsms = decodedData.coordinatorBsms;
      Bsms.parseCoordinator(coordinatorBsms);
    } catch (e) {
      onFailedScanning(wrongFormatMessage2);
      return;
    }

    if (_walletProvider.findMultisigWalletByCoordinatorBsms(coordinatorBsms) != null) {
      onFailedScanning(t.errors.duplicate_multisig_registered_error);
      return;
    }

    try {
      // multisigVault 가져오기, isolate 실행
      final vault = await _walletProvider.importMultisigVault(decodedData, widget.id!);
      assert(_walletProvider.isAddVaultCompleted);

      if (!mounted) return;
      //Logger.log('---> Homeroute = ${HomeScreenStatus().screenStatus}');
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (Route<dynamic> route) => false,
        arguments: VaultHomeNavArgs(addedWalletId: vault.id),
      );
    } catch (e) {
      if (e is NotRelatedMultisigWalletException) {
        onFailedScanning(e.message);
        return;
      }
      onFailedScanning(e.toString());
    }
  }

  List<TextSpan> _getTooltipRichText() {
    TextSpan buildTextSpan(String text, {bool isBold = false}) {
      return TextSpan(
        text: text,
        style: CoconutTypography.body2_14.copyWith(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: CoconutColors.black,
        ),
      );
    }

    if (widget.screenType == MultisigBsmsImportType.copy) {
      switch (_visibilityProvider.language) {
        case 'en':
          return [
            TextSpan(
              text: t.bsms_scanner_screen.guide1_1,
              style: CoconutTypography.body2_14.setColor(CoconutColors.black),
              children: <TextSpan>[
                buildTextSpan(' ${t.bsms_scanner_screen.guide1_2}'),
                buildTextSpan('\n'),
                buildTextSpan('1. '),
                buildTextSpan(t.bsms_scanner_screen.select),
                buildTextSpan(t.bsms_scanner_screen.guide1_3, isBold: true),
                buildTextSpan('\n'),
                buildTextSpan('2. '),
                buildTextSpan(t.bsms_scanner_screen.select),
                buildTextSpan(t.bsms_scanner_screen.guide1_4),
                buildTextSpan('\n'),
                buildTextSpan('3. '),
                buildTextSpan(t.bsms_scanner_screen.guide1_5),
              ],
            ),
          ];
        case 'kr':
        default:
          return [
            TextSpan(
              text: t.bsms_scanner_screen.guide1_1,
              style: CoconutTypography.body2_14.setColor(CoconutColors.black),
              children: <TextSpan>[
                buildTextSpan(' ${t.bsms_scanner_screen.guide1_2}'),
                buildTextSpan('\n'),
                buildTextSpan('1. '),
                buildTextSpan(t.bsms_scanner_screen.guide1_3, isBold: true),
                buildTextSpan(t.bsms_scanner_screen.select),
                buildTextSpan('\n'),
                buildTextSpan('2. '),
                buildTextSpan(t.bsms_scanner_screen.guide1_4),
                buildTextSpan(t.bsms_scanner_screen.select),
                buildTextSpan('\n'),
                buildTextSpan('3. '),
                buildTextSpan(t.bsms_scanner_screen.guide1_5),
              ],
            ),
          ];
      }
    } else if (widget.screenType == MultisigBsmsImportType.add) {
      switch (_visibilityProvider.language) {
        case 'en':
          return [
            TextSpan(
              text: t.bsms_scanner_screen.coconut_vault.guide2_1,
              style: CoconutTypography.body2_14.setColor(CoconutColors.black),
              children: <TextSpan>[
                buildTextSpan('\n'),
                buildTextSpan('1. '),
                buildTextSpan(t.bsms_scanner_screen.select),
                buildTextSpan(t.bsms_scanner_screen.coconut_vault.guide2_2),
                buildTextSpan('\n'),
                buildTextSpan('2. '),
                buildTextSpan(t.bsms_scanner_screen.select),
                buildTextSpan(t.bsms_scanner_screen.coconut_vault.guide2_3, isBold: true),
                buildTextSpan('\n'),
                buildTextSpan(t.bsms_scanner_screen.coconut_vault.guide2_4),
              ],
            ),
          ];
        case 'kr':
        default:
          return [
            TextSpan(
              text: t.bsms_scanner_screen.coconut_vault.guide2_1,
              style: CoconutTypography.body2_14.setColor(CoconutColors.black),
              children: <TextSpan>[
                buildTextSpan('\n'),
                buildTextSpan('1. '),
                buildTextSpan(t.bsms_scanner_screen.coconut_vault.guide2_2),
                buildTextSpan(t.bsms_scanner_screen.select),
                buildTextSpan('\n'),
                buildTextSpan('2. '),
                buildTextSpan(t.bsms_scanner_screen.coconut_vault.guide2_3, isBold: true),
                buildTextSpan(t.bsms_scanner_screen.select),
                buildTextSpan('\n'),
                buildTextSpan(t.bsms_scanner_screen.coconut_vault.guide2_4),
              ],
            ),
          ];
      }
    } else {
      throw ArgumentError('[SignerScanner] ${widget.screenType}');
    }
  }
}
