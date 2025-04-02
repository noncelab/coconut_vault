import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/styles.dart';
import 'package:flutter/cupertino.dart';

/// bsms 카드에서 master fingerprint와 description으로 전달된 요소가 있는 경우
class SignerBsmsInfoCard extends StatelessWidget {
  final Bsms bsms;
  final double? width;

  const SignerBsmsInfoCard({super.key, required this.bsms, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? MediaQuery.of(context).size.width - 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: MyColors.white,
        boxShadow: const [
          BoxShadow(
            color: MyColors.transparentBlack_15,
            offset: Offset(4, 4),
            blurRadius: 30,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(
        20,
      ),
      child: RichText(
        text: TextSpan(
          text: "${bsms.version}\n${bsms.secretToken}\n[",
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.normal,
            fontSize: 12,
            height: 1.4,
            letterSpacing: 0.5,
            color: MyColors.black,
          ),
          children: <TextSpan>[
            TextSpan(
                text: bsms.signer!.masterFingerPrint, style: _boldTextStyle),
            TextSpan(
              text:
                  '/${bsms.signer!.path}]${bsms.signer!.extendedPublicKey.serialize()}\n',
            ),
            TextSpan(text: bsms.signer!.description, style: _boldTextStyle),
          ],
        ),
      ),
    );
  }
}

const _boldTextStyle = TextStyle(fontWeight: FontWeight.bold);
