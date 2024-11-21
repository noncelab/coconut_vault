import 'dart:convert';
import 'dart:io';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/app.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/model/state/app_model.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/coconut/MultisigUtils.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class SignerScannerScreen extends StatefulWidget {
  final int? id;
  final bool isCopy;
  const SignerScannerScreen({super.key, this.id, this.isCopy = false});

  @override
  State<SignerScannerScreen> createState() => _SignerScannerScreenState();
}

class _SignerScannerScreenState extends State<SignerScannerScreen> {
  late AppModel _appModel;
  late VaultModel _vaultModel;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  QRViewController? controller;
  bool isCameraActive = false;
  bool isAlreadyVibrateScanFailed = false;
  bool _isProcessing = false;

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
    _appModel = Provider.of<AppModel>(context, listen: false);
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _appModel.showIndicator();
      await Future.delayed(const Duration(milliseconds: 1000));
      // fixme 추후 QRCodeScanner가 개선되면 QRCodeScanner 의 카메라 뷰 생성 완료된 콜백 찾아 progress hide 합니다. 현재는 1초 후 hide
      _appModel.hideIndicator();
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void onFailedScanning(String message) {
    String errorMessage;
    if (message.contains('Invalid Scheme')) {
      errorMessage = widget.isCopy
          ? '다중 서명 지갑에 포함된 키가 이 볼트에 없기 때문에 지갑을 가져올 수 없어요.'
          : '잘못된 QR이에요. 다시 시도해 주세요.';
    } else if (message.contains('Invalid address')) {
      errorMessage = '잘못된 주소 형식이에요. 다시 확인해 주세요.';
    } else if (message.contains('Invalid value')) {
      errorMessage =
          '잘못된 QR 코드예요.\n가져올 다중 서명 지갑의 정보 화면에서 "지갑 설정 정보 보기"에 나오는 QR 코드를 스캔해 주세요.';
    } else if (message.contains('Unsupported BSMS version')) {
      errorMessage = '지원되지 않는 BSMS 버전이에요. BSMS 1.0만 지원됩니다.';
    } else if (message.contains('Not support customized path')) {
      errorMessage =
          '커스텀 파생 경로는 지원되지 않아요. 허용된 경로는 "No path restrictions" 또는 "/0/*,/1/*"입니다.';
    } else {
      errorMessage = '[스캔 실패] $message';
    }

    showAlertDialog(
        context: context,
        content: errorMessage,
        onConfirmPressed: () {
          setState(() {
            _isProcessing = false;
          });
        });
  }

  Future<void> _stopCamera() async {
    if (controller != null) {
      await controller?.pauseCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isCopy
        ? Scaffold(
            appBar: CustomAppBar.build(
              title: '다중 서명 지갑 가져오기',
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
            onQRViewCreated: _onQRViewCreated,
            overlayMargin: !widget.isCopy
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
          height: !widget.isCopy ? 50.1 : 0,
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

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) async {
      if (_isProcessing || scanData.code == null) return;
      debugPrint(scanData.code!);
      debugPrint(scanData.code!.contains('\n').toString());

      if (!widget.isCopy) {
        // 외부에서 키 가져오기
        setState(() {
          _isProcessing = true;
        });
        try {
          // Signer 형식이 맞는지 체크, 형식에 벗어나면 Exception이 날라옵니다.
          BSMS.parseSigner(scanData.code!);
        } catch (e) {
          onFailedScanning('Invalid Scheme');
          _appModel.hideIndicator();
          return;
        }

        Navigator.pop(context, scanData.code!);
        return;
      }

      // 다중 서명 지갑 가져오기
      if (widget.id == null) return;

      setState(() {
        _isProcessing = true;
      });
      VaultListItemBase vaultListItem = _vaultModel.getVaultById(widget.id!);
      Map<String, dynamic> decodedData;
      String coordinatorBsms;
      try {
        // CoordinatorBSMS 형식이 맞는지 체크, 형식에 벗어나면 Exception이 날라옵니다.

        // CoordinatorBsms와 getWalletSync()의 데이터를 분리하기 위해 아래 문자열 기준으로 분리 했습니다.
        // 변경이 필요하면 MultiSigBsmsScreen의 qrData도 함께 변경해 주어야 합니다.
        decodedData = jsonDecode(scanData.code!);
        coordinatorBsms = decodedData['coordinatorBSMS'];
        BSMS.parseCoordinator(coordinatorBsms);
      } catch (e) {
        print('e ======= : ${e.toString()}');
        if (e.toString().contains('Invalid address')) {
          onFailedScanning('Invalid address');
        } else if (e.toString().contains('Invalid value')) {
          onFailedScanning('Invalid value');
        } else if (e.toString().contains('Unsupported BSMS version')) {
          onFailedScanning('Unsupported BSMS version');
        } else if (e.toString().contains('Not support customized path')) {
          onFailedScanning('Not support customized path');
        } else if (e.toString().contains('is not a subtype')) {
          onFailedScanning('Invalid value');
        }
        _appModel.hideIndicator();

        return;
      }
      // 이 지갑이 키로 사용된 멀티시그지갑의 coordinatorBsms = decodedCoordinatorBsms
      debugPrint('-----------------------\n$coordinatorBsms');
      // 이 지갑이 이미 포함된 멀티시그 지갑이 아닌지 확인하기, 포함된 경우 alert
      if (_vaultModel.isMultisigVaultDuplicated(coordinatorBsms)) {
        showAlertDialog(
            context: context,
            content: '이미 등록된 다중 서명 지갑입니다.',
            onConfirmPressed: () {
              setState(() {
                _isProcessing = false;
              });
            });
        _appModel.hideIndicator();

        return;
      }

      // 이 지갑이 위 멀티시그 지갑의 일부인지 확인하기, 아닌 경우 alert
      MultisignatureVault multisigVault =
          MultisignatureVault.fromCoordinatorBsms(coordinatorBsms);
      // 이 지갑의 signerBsms, isolate 실행
      int signerIndex = await _vaultModel.getSignerIndexAsync(
          multisigVault, vaultListItem as SinglesigVaultListItem);

      debugPrint('signerIndex = $signerIndex');
      if (signerIndex == -1) {
        showAlertDialog(
            context: context,
            content: '이 키가 포함된 다중 서명 지갑이 아닙니다.',
            onConfirmPressed: () {
              setState(() {
                _isProcessing = false;
              });
            });
        _appModel.hideIndicator();

        return;
      }

      // multisigVault 가져오기, isolate 실행
      await _vaultModel.importMultisigVaultAsync(decodedData['name'],
          decodedData['colorIndex'], decodedData['iconIndex'], coordinatorBsms);

      if (_vaultModel.isAddVaultCompleted) {
        _appModel.hideIndicator();
        Logger.log('finish creating vault. return to home.');
        Logger.log('Homeroute = ${HomeScreenStatus().screenStatus}');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  RichText _infoRichText() {
    return widget.isCopy
        ? RichText(
            text: TextSpan(
              text: '다른 볼트에서 만든 다중 서명 지갑을 추가할 수 있어요. 추가 하시려는 다중 서명 지갑의 ',
              style: Styles.body1.merge(
                const TextStyle(
                  height: 20.8 / 16,
                  letterSpacing: -0.01,
                ),
              ),
              children: <TextSpan>[
                TextSpan(
                  text: '지갑 설정 정보 ',
                  style: Styles.body1.merge(
                    const TextStyle(
                      fontWeight: FontWeight.bold,
                      height: 20.8 / 16,
                      letterSpacing: -0.01,
                    ),
                  ),
                ),
                TextSpan(
                  text: '화면에 나타나는 QR 코드를 스캔해 주세요.',
                  style: Styles.body1.merge(
                    const TextStyle(
                      height: 20.8 / 16,
                      letterSpacing: -0.01,
                    ),
                  ),
                ),
              ],
            ),
          )
        : RichText(
            text: TextSpan(
              text: '키를 보관 중인 볼트',
              style: Styles.body1.merge(
                const TextStyle(
                  fontWeight: FontWeight.bold,
                  height: 20.8 / 16,
                  letterSpacing: -0.01,
                ),
              ),
              children: <TextSpan>[
                TextSpan(
                  text: '에서 QR 코드를 생성해야 해요. 홈 화면 - 내보내기 화면에서 ',
                  style: Styles.body1.merge(
                    const TextStyle(
                      height: 20.8 / 16,
                      letterSpacing: -0.01,
                    ),
                  ),
                ),
                TextSpan(
                  text: '다른 볼트에서 다중 서명 키로 사용',
                  style: Styles.body1.merge(
                    const TextStyle(
                      fontWeight: FontWeight.bold,
                      height: 20.8 / 16,
                      letterSpacing: -0.01,
                    ),
                  ),
                ),
                TextSpan(
                  text: '을 선택해 주세요. 화면에 보이는 QR 코드를 스캔합니다.',
                  style: Styles.body1.merge(
                    const TextStyle(
                      height: 20.8 / 16,
                      letterSpacing: -0.01,
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
