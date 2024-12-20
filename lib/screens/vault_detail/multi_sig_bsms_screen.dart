import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/multisig_import_detail.dart';
import 'package:coconut_vault/model/data/multisig_signer.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/clipboard_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MultiSigBsmsScreen extends StatefulWidget {
  final int id;

  const MultiSigBsmsScreen({super.key, required this.id});

  @override
  State<MultiSigBsmsScreen> createState() => _MultiSigBsmsScreenState();
}

class _MultiSigBsmsScreenState extends State<MultiSigBsmsScreen> {
  late String qrData;
  List<int> outSideWalletIdList = [];

  @override
  void initState() {
    super.initState();
    final model = Provider.of<VaultModel>(context, listen: false);
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
            title: const Text('지갑 상세 정보'),
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
              toastMessage: '지갑 상세 정보가 복사됐어요',
            ),
          ),
        ),
      ),
    );
  }

  String _generateOutsideWalletDescription(List<int> idList,
      {bool isAnd = false}) {
    if (idList.length == 1) return '${idList.first}번';
    if (isAnd) {
      return '${idList.first}번과 ${idList.last}번';
    }

    return '${idList.first}번 또는 ${idList.last}번';
  }

  @override
  Widget build(BuildContext context) {
    final qrWidth = MediaQuery.of(context).size.width * 0.76;
    return Scaffold(
      backgroundColor: MyColors.white,
      appBar: CustomAppBar.build(
        title: '지갑 설정 정보',
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
                  _description(
                      '안전한 다중 서명 지갑 관리를 위한 표준에 따라 지갑 설정 정보를 관리하고 공유합니다.'),
                  const SizedBox(height: 4),
                  if (outSideWalletIdList.isEmpty) ...[
                    _description('모든 키가 볼트에 저장되어 있습니다.'),
                    const SizedBox(height: 4),
                    _description(
                        '같은 키를 보관하고 있는 다른 볼트에서도 이 QR을 읽어 다중 서명 지갑을 추가할 수 있습니다.'),
                  ] else ...{
                    _description(
                        '이 다중 서명 지갑에 지정된 **${_generateOutsideWalletDescription(outSideWalletIdList, isAnd: true)}** 키의 니모닉 문구는 현재 다른 볼트에 있습니다.'),
                    const SizedBox(height: 4),
                    _description(
                        '**${_generateOutsideWalletDescription(outSideWalletIdList)}** 키 보관 지갑 - **다중 서명 지갑 가져오기**에서 아래 QR 코드를 읽어 주세요. 다중 서명 트랜잭션에 **${_generateOutsideWalletDescription(outSideWalletIdList)}** 키로 서명하기 위해 이 절차가 반드시 필요합니다.'),
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
                  '상세 정보 보기',
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
