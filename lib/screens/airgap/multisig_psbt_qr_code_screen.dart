import 'dart:async';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/hardware_wallet_type_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/services/blockchain_commons/ur_type.dart';
import 'package:coconut_vault/utils/bb_qr/bb_qr_encoder.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/animated_qr/animated_qr_view.dart';
import 'package:coconut_vault/widgets/animated_qr/view_data_handler/bc_ur_qr_view_handler.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum QrScanDensity { slow, normal, fast }

class PsbtQrCodeViewScreen extends StatefulWidget {
  final String multisigName;
  final String keyIndex;
  final String signedRawTx;
  final HardwareWalletType hardwareWalletType;
  final VoidCallback onNextPressed;

  const PsbtQrCodeViewScreen({
    super.key,
    required this.multisigName,
    required this.keyIndex,
    required this.signedRawTx,
    required this.hardwareWalletType,
    required this.onNextPressed,
  });

  @override
  State<PsbtQrCodeViewScreen> createState() => _PsbtQrCodeViewScreenState();
}

class _PsbtQrCodeViewScreenState extends State<PsbtQrCodeViewScreen> {
  late VisibilityProvider _visibilityProvider;
  late double _sliderValue;
  late QrScanDensity _qrScanDensity;
  late bool _isBbqrType;

  bool _isEnglish = true;
  int? _lastSnappedValue;

  int _currentBbqrIndex = 0;
  Timer? _bbqrTimer;
  List<String> _bbqrParts = [];

  @override
  void initState() {
    super.initState();
    _visibilityProvider = Provider.of<VisibilityProvider>(context, listen: false);
    _isEnglish = _visibilityProvider.language == 'en';
    _isBbqrType = widget.hardwareWalletType == HardwareWalletType.coldcard;

    if (widget.hardwareWalletType == HardwareWalletType.coldcard) {
      _bbqrParts = BbQrEncoder().encodeBase64(widget.signedRawTx);
      _bbqrTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
        if (mounted) {
          setState(() {
            _currentBbqrIndex = (_currentBbqrIndex + 1) % _bbqrParts.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _bbqrTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //  (QR스캔성능)    일반 화면        갤폴드 접은 화면
    //     볼트           상                상
    //    키스톤           상                상
    //   시드사이너         상                하
    //    제이드          중상                하

    switch (widget.hardwareWalletType) {
      case HardwareWalletType.coconutVault:
      case HardwareWalletType.keystone3Pro:
        // 볼트와 키스톤은 스캔 성능이 우수하기 때문에 일반/좁은 화면 모두 _qrScanDensity: fast, padding: 16으로 설정
        _qrScanDensity = QrScanDensity.fast;
        break;
      case HardwareWalletType.seedSigner:
      case HardwareWalletType.jade:
        // 제이드는 카메라 성능 최악
        _qrScanDensity = QrScanDensity.slow;
        break;
      case HardwareWalletType.krux:
        _qrScanDensity = QrScanDensity.slow;
        break;
      default:
        _qrScanDensity = QrScanDensity.normal;
        break;
    }
    _sliderValue = _qrScanDensity.index * 5;
  }

  @override
  Widget build(BuildContext context) {
    final psbt = Psbt.parse(widget.signedRawTx);

    return ClipRRect(
      borderRadius: CoconutBorder.defaultRadius,
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(
          context: context,
          title: t.signer_qr_bottom_sheet.title(
            name:
                widget.hardwareWalletType.displayName +
                (_visibilityProvider.language == 'kr' && widget.hardwareWalletType == HardwareWalletType.keystone3Pro
                    ? '으'
                    : ''),
          ),
          isBottom: true,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  color: CoconutColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      CustomTooltip.buildInfoTooltip(
                        context,
                        richText: RichText(
                          text: TextSpan(style: CoconutTypography.body2_14, children: _getTooltipRichText()),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: CoconutBoxDecoration.shadowBoxDecoration,
                        child:
                            _isBbqrType && _bbqrParts.isNotEmpty
                                ? QrImageView(data: _bbqrParts[_currentBbqrIndex], version: QrVersions.auto)
                                : AnimatedQrView(
                                  key: ValueKey(_qrScanDensity),
                                  qrViewDataHandler: BcUrQrViewHandler(
                                    widget.signedRawTx,
                                    UrType.cryptoPsbt,
                                    maxFragmentLen: _getMaxFragmentLen(_qrScanDensity),
                                  ),
                                  qrScanDensity: _qrScanDensity,
                                  qrSize: MediaQuery.of(context).size.width * 0.8,
                                ),
                      ),
                      if (!_isBbqrType) ...[CoconutLayout.spacing_800h, _buildDensitySliderWidget(context)],
                      Container(height: 150),
                    ],
                  ),
                ),
              ),
              FixedBottomButton(
                onButtonClicked: () {
                  widget.onNextPressed();
                },
                subWidget: CoconutUnderlinedButton(
                  text: _isBbqrType ? t.signer_qr_bottom_sheet.view_ur : t.signer_qr_bottom_sheet.view_bbqr,
                  onTap: () {
                    if (_bbqrParts.isEmpty) {
                      _bbqrParts = BbQrEncoder().encodeBase64(widget.signedRawTx);
                    }
                    setState(() {
                      _isBbqrType = !_isBbqrType;
                    });
                  },
                ),
                text: t.next,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _getTooltipRichText() {
    final textStyle = CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black);
    final textStyleBold = CoconutTypography.body2_14_Bold.copyWith(height: 1.2, color: CoconutColors.black);

    if (_isEnglish) {
      switch (widget.hardwareWalletType) {
        case HardwareWalletType.coconutVault:
          return [
            TextSpan(text: t.signer_qr_bottom_sheet.vault_text1, style: textStyle),
            TextSpan(text: widget.keyIndex, style: textStyleBold),
            TextSpan(text: ',', style: textStyle),
            const TextSpan(text: '\n'),
            TextSpan(text: '1. ', style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.vault_text2, style: textStyleBold),
            const TextSpan(text: '\n'),
            TextSpan(text: '2. ', style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.vault_text3, style: textStyleBold),
          ];
        case HardwareWalletType.seedSigner:
          return [
            TextSpan(text: t.signer_qr_bottom_sheet.seedsigner_text0, style: textStyle),
            TextSpan(text: '1. ', style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.seedsigner_text1, style: textStyle),
            const TextSpan(text: '\n'),
            TextSpan(text: '2. ', style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.seedsigner_text2, style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.seedsigner_text3, style: textStyleBold),
            TextSpan(text: t.signer_qr_bottom_sheet.seedsigner_text4, style: textStyle),
          ];
        case HardwareWalletType.jade:
          return [
            TextSpan(text: t.signer_qr_bottom_sheet.jade_text0, style: textStyle),
            TextSpan(text: '1. ', style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.jade_text1, style: textStyle),
            const TextSpan(text: '\n'),
            TextSpan(text: '2. ', style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.jade_text2, style: textStyleBold),
            TextSpan(text: t.signer_qr_bottom_sheet.jade_text3, style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.jade_text4, style: textStyle),
          ];
        case HardwareWalletType.coldcard:
          return [
            TextSpan(text: t.signer_qr_bottom_sheet.coldcard_text0, style: textStyle),
            TextSpan(text: '1. ', style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.coldcard_text1, style: textStyleBold),
            const TextSpan(text: '\n'),
            TextSpan(text: '2. ', style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.coldcard_text2, style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.coldcard_text3, style: textStyleBold),
            TextSpan(text: t.signer_qr_bottom_sheet.coldcard_text4, style: textStyle),
          ];
        case HardwareWalletType.keystone3Pro:
          return [
            TextSpan(text: t.signer_qr_bottom_sheet.keystone_text0, style: textStyle),
            TextSpan(text: '1. ', style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.keystone_text1, style: textStyleBold),
            const TextSpan(text: '\n'),
            TextSpan(text: '2. ', style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.keystone_text2, style: textStyleBold),
            TextSpan(text: t.signer_qr_bottom_sheet.keystone_text3, style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.keystone_text4, style: textStyle),
          ];
        case HardwareWalletType.krux:
          return [
            TextSpan(text: t.signer_qr_bottom_sheet.krux_text0, style: textStyle),
            TextSpan(text: '1. ', style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.krux_text1, style: textStyleBold),
            const TextSpan(text: '\n'),
            TextSpan(text: '2. ', style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.krux_text2, style: textStyleBold),
            const TextSpan(text: '\n'),
            TextSpan(text: '3. ', style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.krux_text3, style: textStyleBold),
            const TextSpan(text: '\n'),
            TextSpan(text: '4. ', style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.krux_text4, style: textStyle),
            TextSpan(text: t.signer_qr_bottom_sheet.krux_text5, style: textStyleBold),
            TextSpan(text: t.signer_qr_bottom_sheet.krux_text6, style: textStyle),
          ];
        default:
          return [];
      }
    }
    switch (widget.hardwareWalletType) {
      case HardwareWalletType.coconutVault:
        return [
          TextSpan(text: widget.keyIndex, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.vault_text1, style: textStyle),
          TextSpan(text: ',', style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: '1. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.vault_text2, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: '2. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.vault_text3, style: textStyleBold),
        ];
      case HardwareWalletType.seedSigner:
        return [
          TextSpan(text: t.signer_qr_bottom_sheet.seedsigner_text0, style: textStyle),
          TextSpan(text: '1. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.seedsigner_text1, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: '2. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.seedsigner_text2, style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.seedsigner_text3, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.seedsigner_text4, style: textStyle),
        ];
      case HardwareWalletType.jade:
        return [
          TextSpan(text: t.signer_qr_bottom_sheet.jade_text0, style: textStyle),
          TextSpan(text: '1. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.jade_text1, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: '2. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.jade_text2, style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.jade_text3, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.jade_text4, style: textStyle),
        ];
      case HardwareWalletType.coldcard:
        return [
          TextSpan(text: t.signer_qr_bottom_sheet.coldcard_text0, style: textStyle),
          TextSpan(text: '1. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.coldcard_text1, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: '2. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.coldcard_text2, style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.coldcard_text3, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.coldcard_text4, style: textStyle),
        ];
      case HardwareWalletType.keystone3Pro:
        return [
          TextSpan(text: t.signer_qr_bottom_sheet.keystone_text0, style: textStyle),
          TextSpan(text: '1. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.keystone_text1, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: '2. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.keystone_text2, style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.keystone_text3, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.keystone_text4, style: textStyle),
        ];
      case HardwareWalletType.krux:
        return [
          TextSpan(text: t.signer_qr_bottom_sheet.krux_text0, style: textStyle),
          TextSpan(text: '1. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.krux_text1, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: '2. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.krux_text2, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: '3. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.krux_text3, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.select, style: textStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: '4. ', style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.krux_text4, style: textStyle),
          TextSpan(text: t.signer_qr_bottom_sheet.krux_text5, style: textStyleBold),
          TextSpan(text: t.signer_qr_bottom_sheet.krux_text6, style: textStyle),
        ];
      default:
        return [];
    }
  }

  int _getSnappedValue(double value) {
    if (value <= 2.5) return 0;
    if (value <= 7.5) return 5;
    return 10;
  }

  QrScanDensity _mapValueToDensity(int val) {
    switch (val) {
      case 0:
        return QrScanDensity.slow;
      case 5:
        return QrScanDensity.normal;
      case 10:
      default:
        return QrScanDensity.fast;
    }
  }

  /// QR 버전에 따른 maxFragmentLen 계산
  /// QR 버전별 최대 데이터 크기 (alphanumeric 모드, Error Correction Level M 기준):
  /// - Version 5: 약 108 characters = 864 bits
  /// - Version 7: 약 180 characters = 1440 bits (실제 최대: 1248 bits)
  /// - Version 9: 약 272 characters = 2176 bits
  /// UR 헤더 길이: 약 20-30자 (실제로는 더 클 수 있음)
  /// 데이터: Bytewords.minimal로 인코딩(1바이트 -> 2자)
  /// 안전 마진을 고려하여 보수적으로 설정
  int _getMaxFragmentLen(QrScanDensity density) {
    switch (density) {
      case QrScanDensity.fast:
        // Version 9: (272 - 30) / 2 = 121, 안전하게 80 사용
        return 80;
      case QrScanDensity.normal:
        // Version 7: 실제 최대 1248 bits, 약 156 characters
        // (156 - 35 헤더 여유) / 2 = 60.5, 더 보수적으로 40 사용
        return 40;
      case QrScanDensity.slow:
        // Version 5: (108 - 30) / 2 = 39, 실제 테스트 결과 940 bits > 864 bits 에러 발생
        // 더 보수적으로 20으로 설정하여 864 bits 제한을 확실히 준수
        return 20;
    }
  }

  Padding _buildDensitySliderWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              t.signer_qr_bottom_sheet.low_density_qr,
              style: CoconutTypography.body3_12,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: CoconutColors.gray400,
                inactiveTrackColor: CoconutColors.gray400,
                trackHeight: 8,
                thumbColor: CoconutColors.gray800,
                overlayColor: CoconutColors.gray700.withOpacity(0.2),
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                value: _sliderValue,
                min: 0,
                max: 10.0,
                divisions: 100,
                onChanged: (double value) {
                  setState(() {
                    _sliderValue = value;
                  });
                },
                onChangeEnd: (double value) {
                  final snapped = _getSnappedValue(value);
                  if (_lastSnappedValue != snapped) {
                    vibrateExtraLight();
                    _lastSnappedValue = snapped;
                  }
                  setState(() {
                    _sliderValue = snapped.toDouble();
                    _qrScanDensity = _mapValueToDensity(snapped);
                  });
                },
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              t.signer_qr_bottom_sheet.high_density_qr,
              style: CoconutTypography.body3_12,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
