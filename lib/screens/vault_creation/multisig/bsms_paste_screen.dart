import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';

class BSMSPasteScreen extends StatefulWidget {
  const BSMSPasteScreen({super.key});

  @override
  State<BSMSPasteScreen> createState() => _BSMSPasteScreenState();
}

class _BSMSPasteScreenState extends State<BSMSPasteScreen> {
  final FocusNode _bsmsFocusNode = FocusNode();
  final TextEditingController _bsmsController = TextEditingController();
  String _bsms = '';
  bool _bsmsObscured = false;

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
                onButtonClicked: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.bsmsPaste);
                },
                text: t.complete,
                showGradient: false,
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
      ],
    );
  }
}
