import 'package:coconut_vault/widgets/animatedQR/animated_qr_data_handler.dart';
import 'package:coconut_vault/widgets/animatedQR/animated_qr_view.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';

class SignerQrBottomSheet extends StatefulWidget {
  final String multisigName;
  final String keyIndex;
  final String signedRawTx;

  const SignerQrBottomSheet({
    super.key,
    required this.multisigName,
    required this.keyIndex,
    required this.signedRawTx,
  });

  @override
  State<SignerQrBottomSheet> createState() => _SignerQrBottomSheetState();
}

class _SignerQrBottomSheetState extends State<SignerQrBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: MyBorder.defaultRadius,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar.buildWithClose(
          context: context,
          title: '서명 트랜잭션 내보내기',
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              color: MyColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 20),
                  CustomTooltip(
                    richText: RichText(
                      text: TextSpan(
                        text: '[1] ',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.4,
                          letterSpacing: 0.5,
                          color: MyColors.black,
                        ),
                        children: <TextSpan>[
                          const TextSpan(
                            text: "아래 QR 코드는 다음 화면에서 사용하실 수 있어요.\n",
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          const TextSpan(
                            text: "① ",
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          TextSpan(
                            text: widget.keyIndex,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text:
                                "번 키가 보관된 볼트에서 다중 서명 지갑 '${widget.multisigName} 지갑'을 선택 - ",
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          const TextSpan(
                            text: '다중 서명하기',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(
                            text: ' 화면 \n② 서명 절차 중',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          const TextSpan(
                            text: ' 서명 업데이트',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(
                            text: ' 화면',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    showIcon: true,
                    type: TooltipType.info,
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecorations.shadowBoxDecoration,
                    child: AnimatedQrView(
                      data: AnimatedQRDataHandler.splitData(widget.signedRawTx),
                      size: MediaQuery.of(context).size.width * 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
