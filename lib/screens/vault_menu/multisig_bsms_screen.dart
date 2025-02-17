import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/clipboard_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MultisigBsmsScreen extends StatefulWidget {
  final int id;

  const MultisigBsmsScreen({super.key, required this.id});

  @override
  State<MultisigBsmsScreen> createState() => _MultisigBsmsScreenState();
}

class _MultisigBsmsScreenState extends State<MultisigBsmsScreen> {
  late String qrData;
  List<int> outSideWalletIdList = [];

  @override
  void initState() {
    super.initState();
    final model = Provider.of<WalletProvider>(context, listen: false);
    final vaultListItem =
        model.getVaultById(widget.id) as MultisigVaultListItem;
    String coordinatorBsms = vaultListItem.coordinatorBsms ??
        (vaultListItem.coconutVault as MultisignatureVault)
            .getCoordinatorBsms();
    Map<String, dynamic> walletSyncString =
        jsonDecode(vaultListItem.getWalletSyncString());

    Map<String, String> namesMap = {};
    for (var signer in vaultListItem.signers) {
      namesMap[signer.keyStore.masterFingerprint] = signer.name!;
    }

    qrData = jsonEncode(MultisigImportDetail(
      name: walletSyncString['name'],
      colorIndex: walletSyncString['colorIndex'],
      iconIndex: walletSyncString['iconIndex'],
      namesMap: namesMap,
      coordinatorBsms: coordinatorBsms,
    ));

    _getOutsideWalletIdList(vaultListItem);
  }

  void _getOutsideWalletIdList(MultisigVaultListItem item) {
    for (MultisigSigner signer in item.signers) {
      if (signer.innerVaultId == null) {
        outSideWalletIdList.add(signer.id + 1);
      }
    }
  }

  _showMultiSigDetail() {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: ClipRRect(
        borderRadius: MyBorder.defaultRadius,
        child: Scaffold(
          backgroundColor: MyColors.white,
          appBar: AppBar(
            title: Text(t.multi_sig_bsms_screen.bottom_sheet.title),
            centerTitle: true,
            backgroundColor: MyColors.white,
            titleTextStyle: Styles.body1Bold,
            toolbarTextStyle: Styles.body1Bold,
            leading: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: MyColors.darkgrey,
                size: 22,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: SingleChildScrollView(
            child: ClipboardButton(
              text: qrData,
              toastMessage: t.multi_sig_bsms_screen.bottom_sheet.info_copied,
            ),
          ),
        ),
      ),
    );
  }

  String _generateOutsideWalletDescription(List<int> idList,
      {bool isAnd = false}) {
    if (idList.length == 1) {
      return t.multi_sig_bsms_screen.gen1(first: idList.first);
    }
    if (isAnd) {
      return t.multi_sig_bsms_screen
          .gen2(first: idList.first, last: idList.last);
    }
    return t.multi_sig_bsms_screen.gen3(first: idList.first, last: idList.last);
  }

  @override
  Widget build(BuildContext context) {
    final qrWidth = MediaQuery.of(context).size.width * 0.76;
    return Scaffold(
      backgroundColor: MyColors.white,
      appBar: CustomAppBar.build(
        title: t.multi_sig_bsms_screen.title,
        context: context,
        hasRightIcon: false,
        isBottom: false,
        onBackPressed: () {
          Navigator.pop(context);
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Description
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 4,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _description(t.multi_sig_bsms_screen.text1),
                  const SizedBox(height: 4),
                  if (outSideWalletIdList.isEmpty) ...[
                    _description(t.multi_sig_bsms_screen.text2),
                    const SizedBox(height: 4),
                    _description(t.multi_sig_bsms_screen.text3),
                  ] else ...{
                    _description(t.multi_sig_bsms_screen.text4(
                        gen: _generateOutsideWalletDescription(
                            outSideWalletIdList,
                            isAnd: true))),
                    const SizedBox(height: 4),
                    _description(t.multi_sig_bsms_screen.text5(
                        gen: _generateOutsideWalletDescription(
                            outSideWalletIdList))),
                  }
                ],
              ),
            ),

            Center(
                child: Container(
                    width: qrWidth,
                    decoration: BoxDecorations.shadowBoxDecoration,
                    child: QrImageView(
                      data: qrData,
                    ))),
            const SizedBox(
              height: 30,
            ),
            // TODO: 상세 정보 보기
            GestureDetector(
              onTap: _showMultiSigDetail,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: MyColors.borderGrey,
                ),
                child: Text(
                  t.multi_sig_bsms_screen.view_detail,
                  style: Styles.body2.copyWith(color: MyColors.white),
                ),
              ),
            ),
            const SizedBox(
              height: 100,
            ),
          ],
        ),
      ),
    );
  }

  Widget _description(String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '•',
          style: Styles.body1.copyWith(
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Styles.body1.copyWith(
                fontSize: 14,
              ),
              children: _parseDescription(description),
            ),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _parseDescription(String description) {
    // ** 로 감싸져 있는 문구 볼트체 적용
    List<TextSpan> spans = [];
    description.split("**").asMap().forEach((index, part) {
      spans.add(
        TextSpan(
          text: part,
          style: index.isEven
              ? Styles.body1.copyWith(fontSize: 14)
              : Styles.body1
                  .copyWith(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
    });
    return spans;
  }
}
