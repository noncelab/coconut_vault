// bsms_scanner_base.dart
import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/app_lifecycle_state_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:coconut_vault/widgets/overlays/scanner_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

/// BSMS 스캐너 공통 베이스
abstract class BsmsScannerBase<T extends StatefulWidget> extends State<T> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  late VisibilityProvider visibilityProvider;
  late AppLifecycleStateProvider appLifecycleStateProvider;

  MobileScannerController? controller;
  bool isProcessing = false;

  /// 상단 어둡게 가리는 영역 높이 ??? (Signer: 50, Coordinator: 0) TODO: 뭔지 알아내기
  double get topMaskHeight => 50.0;

  /// AppBar 타이틀
  String get appBarTitle => t.bsms_scanner_screen.import_bsms;
  bool get useBottomAppBar => false;
  bool get showBackButton => true;
  bool get showBottomButton => false;
  List<IconButton> get icon => [
    IconButton(onPressed: () {}, icon: SvgPicture.asset('assets/svg/paste.svg', width: 18, height: 18)),
  ];

  /// 툴팁 RichText
  List<TextSpan> buildTooltipRichText(BuildContext context, VisibilityProvider visibilityProvider);

  /// 실제 스캔 정보 처리 로직
  void onBarcodeDetected(BarcodeCapture capture);

  /// 스캔 실패 시 다이얼로그 + 카메라 재시작
  void onFailedScanning(String message) {
    showAlertDialog(
      context: context,
      content: message,
      onConfirmPressed: () {
        controller?.start().then((_) {
          if (!mounted) return;
          setState(() {
            isProcessing = false;
          });
        });
      },
    );
  }

  void _onCameraStateChanged() {
    if (controller!.value.isInitialized) {
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

    controller = MobileScannerController()..addListener(_onCameraStateChanged);

    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   await Future.delayed(const Duration(milliseconds: 1000));
    //   // fixme 추후 QRCodeScanner가 개선되면 QRCodeScanner 의 카메라 뷰 생성 완료된 콜백 찾아 progress hide 합니다. 현재는 1초 후 hide
    //   if (!mounted) return;
    //   setState(() {
    //     isProcessing = false;
    //   });
    // });
  }

  @override
  void dispose() {
    controller?.removeListener(_onCameraStateChanged);
    controller?.dispose();
    if (appLifecycleStateProvider.ignoredOperations.contains(AppLifecycleOperations.cameraAuthRequest)) {
      appLifecycleStateProvider.endOperation(AppLifecycleOperations.cameraAuthRequest);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CoconutAppBar.build(
        title: appBarTitle,
        backgroundColor: CoconutColors.white,
        context: context,
        isBackButton: showBackButton,
        isBottom: useBottomAppBar,
        actionButtonList: icon,
      ),
      body: SafeArea(top: false, child: _buildStack(context)),
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
            setState(() {
              isProcessing = true;
            });
            onBarcodeDetected(capture);
          },
        ),
        const ScannerOverlay(),
        Container(height: topMaskHeight, color: CoconutColors.black.withValues(alpha: 0.5)),
        CustomTooltip.buildInfoTooltip(
          context,
          richText: RichText(
            text: TextSpan(
              style: CoconutTypography.body2_14,
              children: buildTooltipRichText(context, visibilityProvider),
            ),
          ),
          isBackgroundWhite: false,
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
}
