import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/screens/vault_detail/export_detail_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SyncToWalletScreen extends StatefulWidget {
  final String id;
  final bool isMultiSignatureSync;

  const SyncToWalletScreen(
      {super.key, required this.id, this.isMultiSignatureSync = false});

  @override
  State<SyncToWalletScreen> createState() => _SyncToWalletScreenState();
}

class _SyncToWalletScreenState extends State<SyncToWalletScreen> {
  String qrData = '';
  String pubString = '';
  late String _name;

  @override
  void initState() {
    super.initState();
    final model = Provider.of<VaultModel>(context, listen: false);
    final vaultListItem = model.getVaultById(int.parse(widget.id));
    _name = vaultListItem.name;

    try {
      if (widget.isMultiSignatureSync) {
        qrData =
            vaultListItem.coconutVault.getSignerBsms(AddressType.p2wsh, _name);
        if (qrData.isNotEmpty) {
          if (qrData.contains('Vpub')) {
            pubString = qrData.substring(qrData.indexOf('Vpub'));
          }
          if (qrData.contains('Xpub')) {
            pubString = qrData.substring(qrData.indexOf('Xpub'));
          }
          if (qrData.contains('Zpub')) {
            pubString = qrData.substring(qrData.indexOf('Zpub'));
          }
          pubString = pubString.substring(0, pubString.indexOf('\n'));
        }

        debugPrint(qrData);
        debugPrint(pubString);
        return;
      }
      qrData = vaultListItem.getWalletSyncString();
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
          title: '$_name 내보내기',
          context: context,
          hasRightIcon: false,
          isBottom: true),
      body: SafeArea(
        minimum: Paddings.container,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomTooltip(
                type: TooltipType.info,
                showIcon: true,
                richText: widget.isMultiSignatureSync
                    ? RichText(
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
                      )
                    : RichText(
                        text: const TextSpan(
                          text: '월렛',
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
                              text: '에서 + 버튼을 누르고, 아래 ',
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
                              text: '해 주세요. 안전한 보기 전용 지갑을 사용하실 수 있어요.',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              Center(
                  child: Container(
                      width: MediaQuery.of(context).size.width * 0.76,
                      decoration: BoxDecorations.shadowBoxDecoration,
                      child: QrImageView(
                        data: qrData,
                      ))),
              const SizedBox(height: 32),
              if (!widget.isMultiSignatureSync)
                GestureDetector(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                      color: MyColors.borderGrey,
                    ),
                    child: Text('상세 정보 보기',
                        style: Styles.caption
                            .merge(const TextStyle(color: MyColors.white))),
                  ),
                  onTap: () {
                    MyBottomSheet.showBottomSheet_90(
                        context: context,
                        child: ExportDetailScreen(
                          exportDetail: qrData,
                        ));
                  },
                ),
              if (widget.isMultiSignatureSync)
                Column(
                  children: [
                    const Text(
                      '내보낼 정보',
                      style: Styles.body2Bold,
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Container(
                      width: double.infinity,
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
                        30,
                      ),
                      // TODO: 내보낼 정보 배치
                      child: Text(pubString),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}
