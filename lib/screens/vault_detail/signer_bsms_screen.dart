import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/widgets/multisig/card/signer_bsms_info_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SignerBsmsScreen extends StatefulWidget {
  final int id;

  const SignerBsmsScreen({super.key, required this.id});

  @override
  State<SignerBsmsScreen> createState() => _SignerBsmsScreenState();
}

class _SignerBsmsScreenState extends State<SignerBsmsScreen> {
  String qrData = '';
  late String _name;

  @override
  void initState() {
    super.initState();
    final model = Provider.of<VaultModel>(context, listen: false);
    final vaultListItem = model.getVaultById(widget.id);
    _name = vaultListItem.name;

    try {
      qrData = (vaultListItem.coconutVault as SingleSignatureVault)
          .getSignerBsms(AddressType.p2wsh, _name);
    } catch (_) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
                content: const Text("내보내기 실패"),
                actions: <CupertinoDialogAction>[
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('확인'),
                  ),
                ]);
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.white,
      appBar: CustomAppBar.build(
          title: _name, context: context, hasRightIcon: false, isBottom: true),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
              ),
              CustomTooltip(
                  type: TooltipType.info,
                  showIcon: true,
                  richText: RichText(
                    text: const TextSpan(
                      text: '다른 볼트',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.4,
                        letterSpacing: 0.5,
                        color: MyColors.black,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '에서 다중 서명 지갑을 생성 중이시군요! 다른 볼트에서 ',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: '가져오기 + 버튼',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '을 누른 후 나타난 가져오기 화면에서, 아래 ',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: 'QR 코드를 스캔',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '해 주세요.',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 32),
              Center(
                  child: Container(
                      width: MediaQuery.of(context).size.width * 0.76,
                      decoration: BoxDecorations.shadowBoxDecoration,
                      child: QrImageView(
                        data: qrData,
                      ))),
              const SizedBox(height: 32),
              Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width - 50,
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      '내보낼 정보',
                      style: Styles.body2Bold,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  SignerBsmsInfoCard(bsms: BSMS.parseSigner(qrData))
                ],
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
