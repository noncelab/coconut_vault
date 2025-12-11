// bsms_scanner_base.dart
import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/app_lifecycle_state_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:coconut_vault/widgets/overlays/scanner_overlay.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

/// BSMS 스캐너 공통 베이스
abstract class BsmsScannerBase<T extends StatefulWidget> extends State<T> {
  final String wrongFormatMessage = t.coordinator_bsms_config_scanner_screen.error_message;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  late VisibilityProvider visibilityProvider;
  late AppLifecycleStateProvider appLifecycleStateProvider;

  MobileScannerController? controller;
  bool isProcessing = false;

  final ValueNotifier<double> _progressNotifier = ValueNotifier(0.0);
  bool showProgressBar = false;
  bool _isScanningExtraData = false;

  /// AppBar 타이틀
  String get appBarTitle => t.bsms_scanner_screen.import_bsms;
  bool get useBottomAppBar => false;
  bool get showBackButton => true;
  bool get showBottomButton => false;

  /// 툴팁 RichText
  List<TextSpan> buildTooltipRichText(BuildContext context, VisibilityProvider visibilityProvider);

  /// 실제 스캔 정보 처리 로직
  void onBarcodeDetected(BarcodeCapture capture);

  /// 스캔 실패 시 다이얼로그 + 카메라 재시작
  Future<void> onFailedScanning(String message) async {
    if (!isProcessing) {
      // INFO: 꼭 로딩 UI가 보일 필요는 없지만 프롬프트가 닫히기 전까지 onBarcodeDetected 방지
      isProcessing = true;
    }
    await showAlertDialog(
      context: context,
      content: message,
      onConfirmPressed: () {
        if (!mounted) return;
        if (isProcessing) {
          setState(() {
            isProcessing = false;
          });
        }
      },
    );
  }

  void updateScanProgress(double progress) {
    _progressNotifier.value = progress;
    setState(() {
      showProgressBar = true;
      _isScanningExtraData = progress > 0.98;
    });
  }

  /// [추가] 프로그레스 바 초기화 및 숨김
  void resetScanProgress() {
    _progressNotifier.value = 0;
    setState(() {
      _isScanningExtraData = false;
      if (showProgressBar) {
        showProgressBar = false;
      }
    });
  }

  void _onCameraStateChanged() {
    if (controller?.value.isInitialized ?? false) {
      appLifecycleStateProvider.endOperation(AppLifecycleOperations.cameraAuthRequest);

      if (isProcessing) {
        setState(() {
          isProcessing = false; // 카메라 준비되면 로딩 off
        });
      }
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pause();
    } else if (Platform.isIOS) {
      controller?.start();
    }
  }

  @override
  void initState() {
    super.initState();
    visibilityProvider = Provider.of<VisibilityProvider>(context, listen: false);
    appLifecycleStateProvider = Provider.of<AppLifecycleStateProvider>(context, listen: false);
    appLifecycleStateProvider.startOperation(AppLifecycleOperations.cameraAuthRequest, ignoreNotify: true);

    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   await Future.delayed(const Duration(milliseconds: 1000));
    //   // fixme 추후 QRCodeScanner가 개선되면 QRCodeScanner 의 카메라 뷰 생성 완료된 콜백 찾아 progress hide 합니다. 현재는 1초 후 hide
    //   if (!mounted) return;
    //   setState(() {
    //     isProcessing = false;
    //   });
    // });

    controller = MobileScannerController(
      // 1. 중복 인식 방지
      detectionSpeed: DetectionSpeed.noDuplicates,
      // 2. 해상도를 HD급 이상으로 설정
      cameraResolution: const Size(1280, 720),
    )..addListener(_onCameraStateChanged);
  }

  @override
  void dispose() {
    _progressNotifier.dispose();
    controller?.removeListener(_onCameraStateChanged);
    controller?.dispose();
    if (appLifecycleStateProvider.ignoredOperations.contains(AppLifecycleOperations.cameraAuthRequest)) {
      appLifecycleStateProvider.endOperation(AppLifecycleOperations.cameraAuthRequest);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomLoadingOverlay(
      child: Scaffold(
        appBar: CoconutAppBar.build(
          title: appBarTitle,
          backgroundColor: CoconutColors.white,
          context: context,
          isBackButton: showBackButton,
          isBottom: useBottomAppBar,
        ),
        body: SafeArea(top: false, child: _buildStack(context)),
      ),
    );
  }

  Stack _buildStack(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            if (isProcessing) return;
            if (!mounted) return;
            onBarcodeDetected(capture);
          },
        ),
        const ScannerOverlay(),

        _buildProgressOverlay(context),

        CustomTooltip.buildInfoTooltip(
          context,
          richText: RichText(
            text: TextSpan(
              style: CoconutTypography.body2_14,
              children: buildTooltipRichText(context, visibilityProvider),
            ),
          ),
          isBackgroundWhite: false,
          paddingTop: 20,
        ),
        _buildLoadingOverlay(context),
        if (showBottomButton)
          FixedBottomButton(
            onButtonClicked: () {
              Navigator.pushReplacementNamed(context, AppRoutes.bsmsPaste);
            },
            text: t.bsms_scanner_base.paste,
            showGradient: false,
            backgroundColor: CoconutColors.white,
            textColor: CoconutColors.black,
          ),
      ],
    );
  }

  Widget _buildLoadingOverlay(BuildContext context) {
    return AnimatedOpacity(
      opacity: isProcessing ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !isProcessing,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(color: CoconutColors.black.withValues(alpha: 0.3)),
          child: const Center(child: CircularProgressIndicator(color: CoconutColors.gray800)),
        ),
      ),
    );
  }

  Widget _buildProgressOverlay(BuildContext context) {
    final scanAreaSize =
        (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400)
            ? 320.0
            : MediaQuery.of(context).size.width * 0.85;

    final scanAreaTop = (MediaQuery.of(context).size.height - scanAreaSize) / 2;
    final scanAreaBottom = scanAreaTop + scanAreaSize;

    return Stack(
      children: [
        Positioned(
          top: scanAreaBottom - 24,
          left: 0,
          right: 0,
          child: Visibility(
            visible: showProgressBar,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CoconutLayout.spacing_1300w,
                if (!_isScanningExtraData) ...[_buildProgressBar(), CoconutLayout.spacing_300w, _buildProgressText()],
                if (_isScanningExtraData) Expanded(child: _buildReadingExtraText()),
                CoconutLayout.spacing_1300w,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadingExtraText() {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Text(
        textAlign: TextAlign.center,
        t.coconut_qr_scanner.reading_extra_data, // strings.g.dart에 해당 키가 있어야 합니다.
        style: CoconutTypography.body2_14_Bold.setColor(CoconutColors.white),
      ),
    );
  }

  Widget _buildProgressText() {
    return ValueListenableBuilder<double>(
      valueListenable: _progressNotifier,
      builder: (context, value, _) {
        return SizedBox(
          width: 35,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: Text(
              textAlign: TextAlign.center,
              "${(value * 100).toInt()}%",
              style: CoconutTypography.body2_14_Bold.setColor(CoconutColors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth;
          return Stack(
            children: [
              Container(
                width: maxWidth,
                height: 8,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  color: CoconutColors.gray350,
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _progressNotifier,
                builder: (context, value, _) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: maxWidth * _progressNotifier.value,
                    height: 6,
                    margin: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      color: Colors.black, // 기존 코드의 디자인 유지
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
