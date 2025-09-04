import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/app_routes_params.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/model/exception/not_related_multisig_wallet_exception.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

enum MultisigBsmsImportType { add, copy }

// Usage:
// 1. home/vault_menu_bottom_sheet.dart,
// 2. vault_creation/multisig/signer_assignment_screen.dart
class MultisigBsmsScannerScreen extends StatefulWidget {
  final int? id;
  final MultisigBsmsImportType screenType;
  const MultisigBsmsScannerScreen({
    super.key,
    this.id,
    this.screenType = MultisigBsmsImportType.add,
  });

  @override
  State<MultisigBsmsScannerScreen> createState() => _MultisigBsmsScannerScreenState();
}

class _MultisigBsmsScannerScreenState extends State<MultisigBsmsScannerScreen> {
  static String wrongFormatMessage1 = t.errors.invalid_single_sig_qr_error;
  static String wrongFormatMessage2 = t.errors.invalid_multisig_qr_error;

  late WalletProvider _walletProvider;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  QRViewController? controller;
  StreamSubscription? _scanSubscription;
  bool isCameraActive = false;
  bool isAlreadyVibrateScanFailed = false;
  bool _isProcessing = false;
  bool _isSetScaffold = false;

  /// for hot reload (not work in prod)
  /// 카메라가 실행 중일 때 Hot reload로 인해 중단되는 문제를 해결하기 위해 사용
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  void initState() {
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    super.initState();
    _isSetScaffold = widget.screenType != MultisigBsmsImportType.add;
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
    controller?.dispose();
    super.dispose();
  }

  void onFailedScanning(String message) {
    showAlertDialog(
        context: context,
        content: message,
        onConfirmPressed: () {
          controller?.resumeCamera().then((_) {
            if (!mounted) return;
            setState(() {
              _isProcessing = false;
            });
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return _isSetScaffold
        ? Scaffold(
            appBar: CoconutAppBar.build(
              title: widget.screenType == MultisigBsmsImportType.copy
                  ? t.signer_scanner_screen.title1
                  : t.signer_scanner_screen.title2,
              context: context,
              isBottom: true,
              isBackButton: widget.screenType == MultisigBsmsImportType.copy,
            ),
            body: _buildStack(context),
          )
        : _buildStack(context);
  }

  Stack _buildStack(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: CoconutColors.white,
          child: QRView(
            key: qrKey,
            onQRViewCreated: !_isSetScaffold
                ? _onQRViewCreatedWhenScanSigner
                : _onQRViewCreatedWhenScanCoordinator,
            overlayMargin: !_isSetScaffold ? const EdgeInsets.only(top: 50) : EdgeInsets.zero,
            overlay: QrScannerOverlayShape(
                borderColor: CoconutColors.white,
                borderRadius: 8,
                borderLength: (MediaQuery.of(context).size.width < 400 ||
                        MediaQuery.of(context).size.height < 400)
                    ? 160.0
                    : MediaQuery.of(context).size.width * 0.9 / 2,
                borderWidth: 8,
                cutOutSize: (MediaQuery.of(context).size.width < 400 ||
                        MediaQuery.of(context).size.height < 400)
                    ? 320.0
                    : MediaQuery.of(context).size.width * 0.9),
            onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
          ),
        ),
        Container(
          height: !_isSetScaffold ? 50.1 : 0,
          color: CoconutColors.black.withOpacity(0.5),
        ),
        CustomTooltip.buildInfoTooltip(context,
            richText: RichText(
              text: TextSpan(
                style: CoconutTypography.body3_12,
                children: _getTooltipRichText(),
              ),
            ),
            isBackgroundWhite: false),
        Visibility(
          visible: _isProcessing,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(color: CoconutColors.black.withOpacity(0.3)),
            child: const Center(
              child: CircularProgressIndicator(
                color: CoconutColors.gray800,
              ),
            ),
          ),
        )
      ],
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errors.camera_permission_error)),
      );
    }
  }

  /// 다중서명지갑 생성 시 외부에서 Signer를 스캔합니다.
  void _onQRViewCreatedWhenScanSigner(QRViewController controller) {
    this.controller = controller;

    _scanSubscription = controller.scannedDataStream.listen((scanData) async {
      if (_isProcessing || scanData.code == null) return;

      controller.pauseCamera(); // only works in iOS

      if (!mounted) return;
      setState(() {
        _isProcessing = true;
      });

      try {
        // Signer 형식이 맞는지 체크
        Bsms.parseSigner(scanData.code!);
      } catch (e) {
        onFailedScanning(wrongFormatMessage1);
        return;
      }

      if (!mounted) return;
      Navigator.pop(context, scanData.code!);
      return;
    });
  }

  /// 다른 볼트에 있는 다중서명지갑을 복사합니다.
  void _onQRViewCreatedWhenScanCoordinator(QRViewController controller) {
    this.controller = controller;

    _scanSubscription = controller.scannedDataStream.listen((scanData) async {
      if (_isProcessing || scanData.code == null) return;

      // 다중서명지갑 '복사하기'
      assert(widget.id != null);

      controller.pauseCamera(); // only works in iOS

      if (!mounted) return;
      setState(() {
        _isProcessing = true;
      });

      MultisigImportDetail decodedData;
      String coordinatorBsms;
      Map<String, dynamic> decodedJson;
      // CoordinatorBSMS 형식이 맞는지 체크
      try {
        decodedJson = jsonDecode(scanData.code!);
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
        await _walletProvider.importMultisigVault(decodedData, widget.id!);
        assert(_walletProvider.isAddVaultCompleted);

        if (!mounted) return;
        //Logger.log('---> Homeroute = ${HomeScreenStatus().screenStatus}');
        Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false,
            arguments: VaultListNavArgs(isWalletAdded: true));
      } catch (e) {
        if (e is NotRelatedMultisigWalletException) {
          onFailedScanning(e.message);
          return;
        }

        onFailedScanning(e.toString());
      }
    });
  }

  List<TextSpan> _getTooltipRichText() {
    TextSpan buildTextSpan(String text, {bool isBold = false}) {
      return TextSpan(
        text: text,
        style: CoconutTypography.body2_14.copyWith(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          height: 1.2,
          color: CoconutColors.black,
        ),
      );
    }

    if (widget.screenType == MultisigBsmsImportType.copy) {
      return [
        TextSpan(
          text: t.signer_scanner_screen.guide1_1,
          style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black),
          children: <TextSpan>[
            buildTextSpan(t.signer_scanner_screen.guide1_2, isBold: true),
            buildTextSpan(
              t.signer_scanner_screen.guide1_3,
            ),
          ],
        ),
      ];
    } else if (widget.screenType == MultisigBsmsImportType.add) {
      return [
        TextSpan(
          text: t.signer_scanner_screen.guide2_1,
          style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black),
          children: <TextSpan>[
            buildTextSpan(
              t.signer_scanner_screen.guide2_2,
            ),
            buildTextSpan(t.signer_scanner_screen.guide2_3, isBold: true),
            buildTextSpan(
              t.signer_scanner_screen.guide2_4,
            ),
          ],
        ),
      ];
    } else {
      throw ArgumentError('[SignerScanner] ${widget.screenType}');
    }
  }
}
