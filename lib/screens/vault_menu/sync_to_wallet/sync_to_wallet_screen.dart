import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/vault_menu/sync_to_wallet/export_detail_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        title: t.sync_to_wallet_screen.title(name: _name),
        context: context,
      ),
      body: SafeArea(
        minimum: CoconutPadding.container,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CoconutToolTip(
                backgroundColor: CoconutColors.gray100,
                borderColor: CoconutColors.gray400,
                icon: SvgPicture.asset(
                  'assets/svg/circle-info.svg',
                  colorFilter: const ColorFilter.mode(
                    CoconutColors.black,
                    BlendMode.srcIn,
                  ),
                ),
                tooltipType: CoconutTooltipType.fixed,
                richText: RichText(
                  text: TextSpan(
                    style: CoconutTypography.body3_12,
                    children: _getTooltipRichText(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                  child: Container(
                      width: MediaQuery.of(context).size.width * 0.76,
                      decoration: CoconutBoxDecoration.shadowBoxDecoration,
                      child: QrImageView(
                        data: qrData,
                      ))),
              const SizedBox(height: 32),
              GestureDetector(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    color: CoconutColors.borderGray,
                  ),
                  child: Text(
                    t.sync_to_wallet_screen.view_detail,
                    style: CoconutTypography.body3_12.setColor(
                      CoconutColors.white,
                    ),
                  ),
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

  List<TextSpan> _getTooltipRichText() {
    return [
      TextSpan(
        text: t.sync_to_wallet_screen.guide1_1,
        style: CoconutTypography.body2_14_Bold.copyWith(height: 1.2, color: CoconutColors.black),
      ),
      TextSpan(
        text: t.sync_to_wallet_screen.guide1_2,
        style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black),
      ),
      TextSpan(
        text: t.sync_to_wallet_screen.guide1_3,
        style: CoconutTypography.body2_14_Bold.copyWith(height: 1.2, color: CoconutColors.black),
      ),
      TextSpan(
        text: t.sync_to_wallet_screen.guide1_4,
        style: CoconutTypography.body2_14.copyWith(height: 1.2, color: CoconutColors.black),
      ),
    ];
  }
}
