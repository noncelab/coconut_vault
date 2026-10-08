import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/text/mfp_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 지갑을 가져올 때 패스프레이즈를 바이트로 바꾸는 방식
enum PassphraseEncoding {
  /// BIP39 표준. 패스프레이즈를 NFKD로 정규화한다.
  nfkd,

  /// 정규화하지 않은 UTF-8. 정규화 도입 이전 코코넛 볼트가 쓰던 방식이다.
  legacyUtf8,
}

/// NFKD 정규화로 패스프레이즈가 바뀌는 경우, 두 방식으로 파생한 지갑 중 복원할 지갑을 고르게 한다.
/// 선택한 [PassphraseEncoding]을 반환하고, 닫으면 null을 반환한다.
class PassphraseWalletSelectionBottomSheet extends StatefulWidget {
  final String nfkdMasterFingerprint;
  final String legacyMasterFingerprint;
  final String lastUnnormalizedVersion;

  const PassphraseWalletSelectionBottomSheet({
    super.key,
    required this.nfkdMasterFingerprint,
    required this.legacyMasterFingerprint,
    required this.lastUnnormalizedVersion,
  });

  @override
  State<PassphraseWalletSelectionBottomSheet> createState() => _PassphraseWalletSelectionBottomSheetState();
}

class _PassphraseWalletSelectionBottomSheetState extends State<PassphraseWalletSelectionBottomSheet> {
  PassphraseEncoding _selected = PassphraseEncoding.nfkd;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        title: t.passphrase_wallet_selection.title,
        context: context,
        onBackPressed: null,
        isBottom: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sizes.size16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.passphrase_wallet_selection.description,
                  style: CoconutTypography.body2_14.setColor(CoconutColors.gray800),
                ),
                CoconutLayout.spacing_400h,
                _buildOption(
                  encoding: PassphraseEncoding.nfkd,
                  masterFingerprint: widget.nfkdMasterFingerprint,
                  description: t.passphrase_wallet_selection.option_standard,
                ),
                Divider(color: CoconutColors.black.withValues(alpha: 0.12), height: 1),
                _buildOption(
                  encoding: PassphraseEncoding.legacyUtf8,
                  masterFingerprint: widget.legacyMasterFingerprint,
                  description: t.passphrase_wallet_selection.option_legacy(version: widget.lastUnnormalizedVersion),
                ),
              ],
            ),
          ),
          FixedBottomButton(
            text: t.confirm,
            onButtonClicked: () => Navigator.pop(context, _selected),
            isVisibleAboveKeyboard: false,
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required PassphraseEncoding encoding,
    required String masterFingerprint,
    required String description,
  }) {
    final isSelected = _selected == encoding;
    return GestureDetector(
      key: ValueKey('passphrase-encoding-${encoding.name}'),
      onTap: () => setState(() => _selected = encoding),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: Sizes.size20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MfpText(
                    mfp: masterFingerprint,
                    style: CoconutTypography.heading4_18_NumberBold.setColor(CoconutColors.black),
                  ),
                  CoconutLayout.spacing_100h,
                  Text(description, style: CoconutTypography.body3_12.setColor(CoconutColors.gray700)),
                ],
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: Sizes.size8),
                child: SvgPicture.asset(
                  'assets/svg/check.svg',
                  colorFilter: const ColorFilter.mode(CoconutColors.black, BlendMode.srcIn),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
