import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/not_related_multisig_wallet_exception.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/multisig/import_coordinator_bsms_view_model.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/bip/multisig_normalizer.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/coordinator_bsms_qr_data_handler.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CoordinatorBsmsPasteScreen extends StatefulWidget {
  const CoordinatorBsmsPasteScreen({super.key});

  @override
  State<CoordinatorBsmsPasteScreen> createState() => _CoordinatorBsmsPasteScreenState();
}

class _CoordinatorBsmsPasteScreenState extends State<CoordinatorBsmsPasteScreen> {
  final FocusNode _bsmsFocusNode = FocusNode();
  final TextEditingController _bsmsController = TextEditingController();

  final CoordinatorBsmsQrDataHandler _handler = CoordinatorBsmsQrDataHandler();
  late final ImportCoordinatorBsmsViewModel _viewModel;

  String _bsms = '';
  bool _bsmsObscured = false;
  bool _isProcessing = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bsmsController.addListener(() {
      setState(() {
        _bsms = _bsmsController.text;
        if (_errorMessage != null) {
          _errorMessage = null;
        }
      });
    });

    _viewModel = ImportCoordinatorBsmsViewModel(
      Provider.of<WalletProvider>(context, listen: false),
      Provider.of<WalletCreationProvider>(context, listen: false),
    );
  }

  @override
  void dispose() {
    _bsmsFocusNode.dispose();
    _bsmsController.dispose();
    super.dispose();
  }

  Future<void> _onCompletePressed() async {
    final inputData = _bsms.trim();
    if (inputData.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null; // 로직 시작 전 기존 에러 문구 초기화
    });

    try {
      // 1. 핸들러 초기화 및 데이터 주입
      _handler.reset();
      _handler.joinData(inputData);

      // 포맷 확인
      if (!_handler.isCompleted()) {
        throw Exception("Incomplete data");
      }

      final result = _handler.result;
      if (result == null) {
        throw Exception("Null result");
      }

      // 2. Normalizer 추출
      final normalizedMultisigConfig = MultisigNormalizer.fromCoordinatorResult(result);

      // 3. 멀티시그 유효성 검사
      final int m = normalizedMultisigConfig.requiredCount;
      final int n = normalizedMultisigConfig.signerBsms.length;
      final bool isValidMultisig = n >= 2 && m > 0 && m <= n;

      if (isValidMultisig) {
        final creationProvider = Provider.of<WalletCreationProvider>(context, listen: false);

        creationProvider.resetAll();
        creationProvider.setQuorumRequirement(m, n);

        List<MultisigSigner> signers =
            normalizedMultisigConfig.signerBsms.asMap().entries.map((entry) {
              int index = entry.key;
              String bsmsString = entry.value;
              KeyStore generatedKeyStore = KeyStore.fromSignerBsms(bsmsString);

              return MultisigSigner(
                id: 0,
                keyStore: generatedKeyStore,
                signerBsms: bsmsString,
                name: 'Signer ${index + 1}',
                innerVaultId: null,
              );
            }).toList();

        creationProvider.setSigners(signers);

        int colorIndex = 0;
        int iconIndex = 0;

        if (result is Map<String, dynamic>) {
          if (result.containsKey('colorIndex')) {
            colorIndex =
                result['colorIndex'] is int ? result['colorIndex'] : int.tryParse(result['colorIndex'].toString()) ?? 0;
          }
          if (result.containsKey('iconIndex')) {
            iconIndex =
                result['iconIndex'] is int ? result['iconIndex'] : int.tryParse(result['iconIndex'].toString()) ?? 0;
          }
        }

        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.vaultNameSetup,
          arguments: {'name': normalizedMultisigConfig.name, 'colorIndex': colorIndex, 'iconIndex': iconIndex},
        );
      } else {
        throw Exception("Invalid multisig logic");
      }
    } catch (e) {
      Logger.error(e);

      if (mounted) {
        setState(() {
          _errorMessage = t.bsms_paste_screen.error_message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(title: t.bsms_scanner_screen.import_multisig_wallet, context: context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter, // Stack 영역 내에서 상단 중앙 정렬
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 필요한 만큼만 높이를 차지
                  crossAxisAlignment: CrossAxisAlignment.center, // 내부 텍스트를 중앙 정렬
                  children: [
                    Text(
                      t.bsms_paste_screen.import_bsms,
                      textAlign: TextAlign.center,
                      style: CoconutTypography.body2_14_Bold,
                    ),
                    const SizedBox(height: 8.0), // 두 텍스트 사이에 간격을 추가
                    _buildBSMSTextField(),
                  ],
                ),
              ),
              Positioned(
                bottom:
                    FixedBottomButton.fixedBottomButtonDefaultBottomPadding +
                    FixedBottomButton.fixedBottomButtonDefaultHeight +
                    12,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.coordinatorBsmsConfigScanner);
                    },
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        t.bsms_paste_screen.back_scan,
                        style: const TextStyle(decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                ),
              ),
              FixedBottomButton(
                onButtonClicked: _onCompletePressed,
                text: t.complete,
                showGradient: false,
                isActive: _bsms.isNotEmpty && !_isProcessing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBSMSTextField() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            child: CoconutTextField(
              focusNode: _bsmsFocusNode,
              controller: _bsmsController,
              onChanged: (_) {},
              maxLines: 5,
              isLengthVisible: false,
              obscureText: _bsmsObscured,
            ),
          ),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _errorMessage!,
              style: CoconutTypography.body3_12.copyWith(color: CoconutColors.red, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
