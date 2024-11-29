import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

enum SignerScannerScreenType { add, copy, sign }

class SignerScannerScreen extends StatefulWidget {
  final int? id;
  final SignerScannerScreenType screenType;
  const SignerScannerScreen({
    super.key,
    this.id,
    this.screenType = SignerScannerScreenType.add,
  });

  @override
  State<SignerScannerScreen> createState() => _SignerScannerScreenState();
}

class _SignerScannerScreenState extends State<SignerScannerScreen> {
  static String wrongFormatMessage1 = '잘못된 QR이에요. 다시 시도해 주세요.';
  static String wrongFormatMessage2 =
      '잘못된 QR이예요.\n가져올 다중 서명 지갑의 정보 화면에서 "지갑 설정 정보 보기"에 나오는 QR 코드를 스캔해 주세요.';

  late VaultModel _vaultModel;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  QRViewController? controller;
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
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  void initState() {
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    super.initState();
    _isSetScaffold = widget.screenType != SignerScannerScreenType.add;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 1000));
      // fixme 추후 QRCodeScanner가 개선되면 QRCodeScanner 의 카메라 뷰 생성 완료된 콜백 찾아 progress hide 합니다. 현재는 1초 후 hide
      setState(() {
        _isProcessing = false;
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void onFailedScanning(String message) {
    showAlertDialog(
        context: context,
        content: message,
        onConfirmPressed: () {
          controller!.resumeCamera().then((_) {
            setState(() {
              _isProcessing = false;
            });
          });
        });
  }

  // Future<void> _stopCamera() async {
  //   if (controller != null) {
  //     await controller?.pauseCamera();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return _isSetScaffold
        ? Scaffold(
            appBar: CustomAppBar.build(
              title: widget.screenType == SignerScannerScreenType.copy
                  ? '다중 서명 지갑 가져오기'
                  : '외부 지갑 서명하기',
              context: context,
              hasRightIcon: false,
              isBottom: true,
            ),
            body: _buildStack(context),
          )
        : _buildStack(context);
  }

  Stack _buildStack(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: MyColors.white,
          child: QRView(
            key: qrKey,
            onQRViewCreated: !_isSetScaffold
                ? _onQRViewCreatedWhenScanSigner
                : _onQRViewCreatedWhenScanCoordinator,
            overlayMargin: !_isSetScaffold
                ? const EdgeInsets.only(top: 50)
                : EdgeInsets.zero,
            overlay: QrScannerOverlayShape(
                borderColor: MyColors.white,
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
          color: MyColors.transparentBlack_50,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: CustomTooltip(
            richText: _infoRichText(),
            showIcon: true,
            type: TooltipType.info,
          ),
        ),
        Visibility(
          visible: _isProcessing,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration:
                const BoxDecoration(color: MyColors.transparentBlack_30),
            child: const Center(
              child: CircularProgressIndicator(
                color: MyColors.darkgrey,
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
        const SnackBar(content: Text('카메라 권한이 없습니다.')),
      );
    }
  }

  /// 다중서명지갑 생성 시 외부에서 Signer를 스캔합니다.
  void _onQRViewCreatedWhenScanSigner(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) async {
      if (_isProcessing || scanData.code == null) return;

      controller.pauseCamera();
      setState(() {
        _isProcessing = true;
      });

      try {
        // Signer 형식이 맞는지 체크
        BSMS.parseSigner(scanData.code!);
      } catch (e) {
        onFailedScanning(wrongFormatMessage1);
        return;
      }

      Navigator.pop(context, scanData.code!);
      return;
    });
  }

  /// 다른 볼트에 있는 다중서명지갑을 복사합니다.
  void _onQRViewCreatedWhenScanCoordinator(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) async {
      if (_isProcessing || scanData.code == null) return;

      // 다중서명지갑 '복사하기'
      assert(widget.id != null);

      controller.pauseCamera();

      setState(() {
        _isProcessing = true;
      });

      VaultListItemBase vaultListItem = _vaultModel.getVaultById(widget.id!);
      Map<String, dynamic> decodedData;
      String name, coordinatorBsms;
      int colorIndex, iconIndex;
      // CoordinatorBSMS 형식이 맞는지 체크
      try {
        decodedData = jsonDecode(scanData.code!);
        name = decodedData['name'];
        colorIndex = decodedData['colorIndex'];
        iconIndex = decodedData['iconIndex'];
        coordinatorBsms = decodedData['coordinatorBSMS'];
        BSMS.parseCoordinator(coordinatorBsms);
      } catch (e) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Unsupported BSMS version')) {
          onFailedScanning('지원하지 않는 BSMS 버전이에요. BSMS 1.0만 지원됩니다.');
        } else if (errorMessage.contains('Not support customized path')) {
          onFailedScanning('커스텀 파생 경로는 지원되지 않아요.');
        } else {
          onFailedScanning(wrongFormatMessage2);
        }
        return;
      }

      if (_vaultModel.isMultisigVaultDuplicated(coordinatorBsms)) {
        onFailedScanning('이미 등록된 다중 서명 지갑입니다.');
        return;
      }

      try {
        // 이 지갑이 위 멀티시그 지갑의 일부인지 확인하기, 아닌 경우 alert
        MultisignatureVault multisigVault =
            MultisignatureVault.fromCoordinatorBsms(coordinatorBsms);
        // 이 지갑의 signerBsms, isolate 실행
        int signerIndex = await _vaultModel.getSignerIndexAsync(
            multisigVault, vaultListItem as SinglesigVaultListItem);

        //Logger.log('signerIndex = $signerIndex');
        if (signerIndex == -1) {
          onFailedScanning('이 지갑을 키로 사용한 다중 서명 지갑이 아닙니다.');
          return;
        }

        // multisigVault 가져오기, isolate 실행
        await _vaultModel.importMultisigVaultAsync(
            name, colorIndex, iconIndex, coordinatorBsms);

        assert(_vaultModel.isAddVaultCompleted);

        //Logger.log('---> Homeroute = ${HomeScreenStatus().screenStatus}');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (Route<dynamic> route) => false,
        );
      } catch (error) {
        onFailedScanning(error.toString());
      }
    });
  }

  RichText _infoRichText() {
    TextSpan buildTextSpan(String text, {bool isBold = false}) {
      return TextSpan(
        text: text,
        style: Styles.body1.merge(
          TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            height: 20.8 / 16,
            letterSpacing: -0.01,
          ),
        ),
      );
    }

    if (widget.screenType == SignerScannerScreenType.copy) {
      return RichText(
        text: TextSpan(
          text: '다른 볼트에서 만든 다중 서명 지갑을 추가할 수 있어요. 추가 하시려는 다중 서명 지갑의 ',
          style: Styles.body1.merge(
            const TextStyle(
              height: 20.8 / 16,
              letterSpacing: -0.01,
            ),
          ),
          children: <TextSpan>[
            buildTextSpan('지갑 설정 정보 ', isBold: true),
            buildTextSpan('화면에 나타나는 QR 코드를 스캔해 주세요.'),
          ],
        ),
      );
    } else if (widget.screenType == SignerScannerScreenType.sign) {
      return RichText(
        text: TextSpan(
          text: '외부 지갑 서명하기 텍스트',
          style: buildTextSpan('외부 지갑 서명하기 텍스트', isBold: true).style,
          children: <TextSpan>[
            buildTextSpan('TODO'),
          ],
        ),
      );
    } else {
      return RichText(
        text: TextSpan(
          text: '키를 보관 중인 볼트',
          style: buildTextSpan('키를 보관 중인 볼트', isBold: true).style,
          children: <TextSpan>[
            buildTextSpan('에서 QR 코드를 생성해야 해요. 홈 화면 - '),
            buildTextSpan('다중 서명 키로 사용하기', isBold: true),
            buildTextSpan('를 선택해 주세요. 화면에 보이는 QR 코드를 스캔합니다.'),
          ],
        ),
      );
    }
  }
}
