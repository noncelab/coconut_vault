import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/vault_menu/sync_to_wallet/export_detail_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SyncToWalletScreen extends StatefulWidget {
  final int id;

  const SyncToWalletScreen({super.key, required this.id});

  @override
  State<SyncToWalletScreen> createState() => _SyncToWalletScreenState();
}

class _SyncToWalletScreenState extends State<SyncToWalletScreen> {
  String qrData = '';
  String pubString = '';
  late String _name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.white,
      appBar: CustomAppBar.build(
          title: t.sync_to_wallet_screen.title(name: _name),
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
                  text: TextSpan(
                    text: t.sync_to_wallet_screen.guide1_1,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      height: 1.4,
                      letterSpacing: 0.5,
                      color: MyColors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: t.sync_to_wallet_screen.guide1_2,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      TextSpan(
                        text: t.sync_to_wallet_screen.guide1_3,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: t.sync_to_wallet_screen.guide1_4,
                        style: const TextStyle(
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
              GestureDetector(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    color: MyColors.borderGrey,
                  ),
                  child: Text(t.sync_to_wallet_screen.view_detail,
                      style: Styles.caption.merge(const TextStyle(color: MyColors.white))),
                ),
                onTap: () {
                  MyBottomSheet.showBottomSheet_90(
                      context: context,
                      child: ExportDetailScreen(
                        exportDetail: qrData,
                      ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final vaultListItem = walletProvider.getVaultById(widget.id);
    _name = vaultListItem.name;

    try {
      qrData = vaultListItem.getWalletSyncString();
    } catch (_) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
                content: Text(t.errors.export_error),
                actions: <CupertinoDialogAction>[
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(t.confirm),
                  ),
                ]);
          });
    }
  }
}
