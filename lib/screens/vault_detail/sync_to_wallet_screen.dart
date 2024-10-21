import 'package:coconut_vault/screens/vault_detail/export_detail_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/model/vault_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SyncToWalletScreen extends StatefulWidget {
  final String id;

  const SyncToWalletScreen({super.key, required this.id});

  @override
  State<SyncToWalletScreen> createState() => _SyncToWalletScreenState();
}

class _SyncToWalletScreenState extends State<SyncToWalletScreen> {
  String qrData = '';
  late String _name;

  @override
  void initState() {
    super.initState();
    final model = Provider.of<VaultModel>(context, listen: false);
    final vaultListItem = model.getVaultById(int.parse(widget.id));
    _name = vaultListItem.name;

    try {
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
                  richText: RichText(
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
                  })
            ],
          ),
        ),
      ),
    );
  }
}
