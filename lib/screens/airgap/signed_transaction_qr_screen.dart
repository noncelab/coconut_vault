import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/services/blockchain_commons/ur_type.dart';
import 'package:coconut_vault/widgets/adaptive_qr_image.dart';
import 'package:coconut_vault/widgets/animated_qr/view_data_handler/bc_ur_qr_view_handler.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/tooltip/custom_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignedTransactionQrScreen extends StatefulWidget {
  final String? tooltipText;

  const SignedTransactionQrScreen({super.key, this.tooltipText});

  @override
  State<SignedTransactionQrScreen> createState() => _SignedTransactionQrScreenState();
}

class _SignedTransactionQrScreenState extends State<SignedTransactionQrScreen> {
  late SignProvider _signProvider;
  late bool isRawTransaction;
  late String? _signedPsbtBase64;
  late String? _signedRawTxHexString;
  late List<TextSpan> _tooltipRichText;

  @override
  void initState() {
    super.initState();
    _signProvider = Provider.of<SignProvider>(context, listen: false);
    _signedPsbtBase64 = _signProvider.signedPsbtBase64;
    _signedRawTxHexString = _signProvider.signedRawTxHexString;
    assert(
      (_signedPsbtBase64 == null && _signedRawTxHexString != null) ||
          (_signedPsbtBase64 != null && _signedRawTxHexString == null),
    );
    isRawTransaction = _signedRawTxHexString != null;
    _tooltipRichText = _getTooltipRichText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        title: t.signed_tx,
        context: context,
        onBackPressed: () {
          _onFinishing();
        },
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CustomTooltip.buildInfoTooltip(
                    context,
                    richText: RichText(text: TextSpan(style: CoconutTypography.body3_12, children: _tooltipRichText)),
                  ),
                  const SizedBox(height: 40),
                  AdaptiveQrImage(
                    qrViewDataHandler:
                        !isRawTransaction
                            ? BcUrQrViewHandler(_signedPsbtBase64!, UrType.cryptoPsbt, maxFragmentLen: 40)
                            : null,
                    qrData: isRawTransaction ? _signedRawTxHexString! : null,
                  ),
                  CoconutLayout.spacing_2500h,
                ],
              ),
            ),
            FixedBottomButton(
              text: t.complete,
              onButtonClicked: () {
                _onFinishing();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onFinishing() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CoconutPopup(
          languageCode: context.read<VisibilityProvider>().appLanguage.code,
          titlePadding: const EdgeInsets.only(top: 24, bottom: 12, left: 16, right: 16),
          title: t.alert.finish_signing.title,
          description: t.alert.finish_signing.description,
          onTapRight: () {
            _signProvider.resetAll();
            Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
          },
          onTapLeft: () {
            Navigator.pop(context);
          },
          leftButtonText: t.no,
          rightButtonText: t.yes,
        );
      },
    );
  }

  List<TextSpan> _getTooltipRichText() {
    final String text;
    if (widget.tooltipText != null) {
      text = widget.tooltipText!;
    } else {
      switch (_signProvider.vaultType) {
        case WalletType.singleSignature:
        case WalletType.taproot:
          text = t.signed_transaction_qr_screen.guide_single_sig(name: _signProvider.walletName!);
        case WalletType.multiSignature:
          text = t.signed_transaction_qr_screen.guide_multisig;
        default:
          text = '';
      }
    }
    return [TextSpan(text: text, style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black))];
  }
}
