import 'package:coconut_vault/model/data/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/screens/pin_check_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class MultiSignatureScreen extends StatefulWidget {
  final String id;
  final String sendAddress;
  final String bitcoinString;
  const MultiSignatureScreen({
    super.key,
    required this.id,
    required this.sendAddress,
    required this.bitcoinString,
  });

  @override
  State<MultiSignatureScreen> createState() => _MultiSignatureScreenState();
}

class _MultiSignatureScreenState extends State<MultiSignatureScreen> {
  // late AppModel _appModel;
  late VaultModel _vaultModel;
  late MultisigVaultListItem _multisigVault;
  late List<bool> _signers;
  int _requiredSignatureCount = 0;

  @override
  void initState() {
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    super.initState();
    _multisigVault =
        _vaultModel.getVaultById(int.parse(widget.id)) as MultisigVaultListItem;
    _signers = List<bool>.filled(_multisigVault.signers.length, false);
    _requiredSignatureCount = _multisigVault.requiredSignatureCount;

    // TODO: sign()

    // final vaultBaseItem = _vaultModel.getVaultById(widget.id);
    // final multiVaultItem = vaultBaseItem as MultisigVaultListItem;
    // final multiVault = multiVaultItem.coconutVault as MultisignatureVault;
    // if (_isMultisig) {
    //   for (var signer in multiVaultItem.signers) {
    //     if (signer.innerVaultId != null) {
    //       final singleVaultItem = _vaultModel.getVaultById(signer.innerVaultId!) as SinglesigVaultListItem;
    //       final index = singleVaultItem.multisigKey?['${widget.id}'];
    //       final singleVault = singleVaultItem.coconutVault as SingleSignatureVault;
    //       multiVault.bindSeedToKeyStore(singleVault.keyStore.seed, index);
    //     }
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.lightgrey,
      appBar: AppBar(
        title: const Text('서명하기', style: Styles.body1),
        backgroundColor: MyColors.lightgrey,
        titleTextStyle:
            Styles.navHeader.merge(const TextStyle(color: MyColors.black)),
        leading: IconButton(
          icon: SvgPicture.asset('assets/svg/back.svg'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: GestureDetector(
              onTap: () {
                // TODO 서명완료 후 이동
                // Navigator.pushNamed(context, '/signed-transaction',
                //     arguments: {'id': int.parse(widget.id)});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: _signers.where((item) => item).length >=
                          _requiredSignatureCount
                      ? MyColors.black19
                      : MyColors.grey219,
                ),
                child: Center(
                  child: Text('다음',
                      style: Styles.caption.copyWith(color: MyColors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            margin: const EdgeInsets.only(top: 8),
            duration: const Duration(seconds: 1),
            child: LinearProgressIndicator(
              value: _signers.where((item) => item).length /
                  _requiredSignatureCount,
              minHeight: 6,
              backgroundColor: MyColors.transparentBlack_06,
              borderRadius: _signers.where((item) => item).length >=
                      _requiredSignatureCount
                  ? BorderRadius.zero
                  : const BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6)),
              valueColor: const AlwaysStoppedAnimation<Color>(MyColors.black),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              _requiredSignatureCount <= _signers.where((item) => item).length
                  ? '서명을 완료했습니다'
                  : '${_requiredSignatureCount - _signers.where((item) => item).length}개의 서명이 필요합니다',
              style: Styles.body2Bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 32, left: 20, right: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '보낼 주소',
                      style: Styles.body2.copyWith(color: MyColors.grey57),
                    ),
                    Text(
                      TextUtils.truncateNameMax25(widget.sendAddress),
                      style: Styles.body1,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '보낼 수량',
                      style: Styles.body2.copyWith(color: MyColors.grey57),
                    ),
                    Text(
                      '${widget.bitcoinString} BTC',
                      style: Styles.body1,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 32, left: 20, right: 20),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _multisigVault.signers.length,
              itemBuilder: (context, index) {
                final length = _multisigVault.signers.length - 1;
                final name = _multisigVault.signers[index].name ?? '';
                final iconIndex = _multisigVault.signers[index].iconIndex ?? 0;
                final colorIndex =
                    _multisigVault.signers[index].colorIndex ?? 0;
                final isVaultKey =
                    _multisigVault.signers[index].innerVaultId != null;

                return Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(index == 0 ? 19 : 0),
                      topRight: Radius.circular(index == 0 ? 19 : 0),
                      bottomLeft: Radius.circular(index == length ? 19 : 0),
                      bottomRight: Radius.circular(index == length ? 19 : 0),
                    ),
                    color: MyColors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: 10,
                          right: 10,
                          top: index == 0 ? 22 : 18,
                          bottom: index == length ? 22 : 18,
                        ),
                        child: Row(
                          children: [
                            Text('${index + 1}번 키 -', style: Styles.body1),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isVaultKey ? 10 : 12),
                                  decoration: BoxDecoration(
                                    color: isVaultKey
                                        ? BackgroundColorPalette[colorIndex]
                                        : MyColors.grey236,
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: SvgPicture.asset(
                                    isVaultKey
                                        ? CustomIcons.getPathByIndex(iconIndex)
                                        : 'assets/svg/download.svg',
                                    colorFilter: ColorFilter.mode(
                                      isVaultKey
                                          ? ColorPalette[colorIndex]
                                          : MyColors.black,
                                      BlendMode.srcIn,
                                    ),
                                    width: isVaultKey ? 20 : 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(name, style: Styles.body2),
                              ],
                            ),
                            const Spacer(),
                            if (_signers[index]) ...{
                              Row(
                                children: [
                                  Text(
                                    '서명완료',
                                    style: Styles.body1Bold.copyWith(
                                        fontSize: 12, color: Colors.black),
                                  ),
                                  const SizedBox(width: 4),
                                  SvgPicture.asset(
                                    'assets/svg/circle-check.svg',
                                    width: 12,
                                  ),
                                ],
                              ),
                            } else if (_requiredSignatureCount >
                                _signers.where((item) => item).length) ...{
                              GestureDetector(
                                onTap: () {
                                  if (isVaultKey) {
                                    MyBottomSheet.showBottomSheet_90(
                                      context: context,
                                      child: CustomLoadingOverlay(
                                        child: PinCheckScreen(
                                          screenStatus:
                                              PinCheckScreenStatus.info,
                                          isDeleteScreen: true,
                                          onComplete: () async {
                                            setState(() {
                                              Navigator.pop(context);
                                              _signers[index] = true;
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  } else {
                                    // TODO: 외부지갑 검증 구현
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: MyColors.white,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                        color: MyColors.black19, width: 1),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '서명',
                                      style: Styles.caption.copyWith(
                                          color: MyColors
                                              .black19), // 텍스트 색상도 검정으로 변경
                                    ),
                                  ),
                                ),
                              ),
                            },
                          ],
                        ),
                      ),
                      if (index < length) ...{
                        const Divider(color: MyColors.divider, height: 1),
                      }
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
