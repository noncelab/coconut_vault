import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/screens/pin_check_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multi_sig/signer_qr_bottom_sheet.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class SinglesigSignScreen extends StatefulWidget {
  final int id;
  final String psbtBase64;
  final String sendAddress;
  final String bitcoinString;
  const SinglesigSignScreen({
    super.key,
    required this.id,
    required this.psbtBase64,
    required this.sendAddress,
    required this.bitcoinString,
  });

  @override
  State<SinglesigSignScreen> createState() => _SinglesigSignScreenState();
}

class _SinglesigSignScreenState extends State<SinglesigSignScreen> {
  late VaultModel _vaultModel;
  late SinglesigVaultListItem _wallet;
  late SingleSignatureVault _coconutVault;
  late List<bool> _signersApproved;
  //bool _isSigned;
  final int _requiredSignatureCount = 1;
  bool _showLoading = false;
  bool _isProgressCompleted = false;

  @override
  void initState() {
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    super.initState();
    _wallet = _vaultModel.getVaultById(widget.id) as SinglesigVaultListItem;
    _coconutVault = _wallet.coconutVault as SingleSignatureVault;
    _signersApproved = List<bool>.filled(1, false);
    //_vaultModel.signedRawTx = _checkSignedPsbt(widget.psbtBase64);
  }

  _signStep1(bool isVaultKey, int index) async {
    if (isVaultKey) {
      MyBottomSheet.showBottomSheet_90(
        context: context,
        child: CustomLoadingOverlay(
          child: PinCheckScreen(
            screenStatus: PinCheckScreenStatus.info,
            isDeleteScreen: true,
            onComplete: () {
              Navigator.pop(context);
              _signStep2(index);
            },
          ),
        ),
      );
    } else {
      //_showQrBottomSheet(index);
    }
  }

  _signStep2(int index) async {
    try {
      setState(() {
        _showLoading = true;
      });

      var secret = await _vaultModel.getSecret(_wallet.id);
      final seed =
          Seed.fromMnemonic(secret.mnemonic, passphrase: secret.passphrase);
      _coconutVault.keyStore.seed = seed;

      final signedTx = _coconutVault.addSignatureToPsbt(widget.psbtBase64);

      _vaultModel.signedRawTx = signedTx;
      if (_vaultModel.signedRawTx == null) {
        if (mounted) {
          throw 'signedRawTx is null.';
        }
      }

      _updateSignState(index);
    } catch (_) {
      if (mounted) {
        showAlertDialog(context: context, content: "서명 실패: $_");
      }
    } finally {
      // unbind
      _coconutVault.keyStore.seed = null;
      setState(() {
        _showLoading = false;
      });
    }
  }

  void _updateSignState(int index) {
    setState(() {
      _signersApproved[index] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.lightgrey,
      appBar: CustomAppBar.buildWithNext(
          title: '서명하기',
          context: context,
          onBackPressed: () => Navigator.pop(context),
          onNextPressed: () {
            Navigator.pushNamed(context, '/signed-transaction',
                arguments: {'id': widget.id});
          },
          isActive: _requiredSignatureCount ==
              _signersApproved.where((bool isApproved) => isApproved).length),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // progress
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: _signersApproved.where((item) => item).length /
                        _requiredSignatureCount,
                  ),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    if (value == 1.0) {
                      _isProgressCompleted = true;
                    } else {
                      _isProgressCompleted = false;
                    }
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: MyColors.transparentBlack_06,
                        borderRadius: _isProgressCompleted
                            ? BorderRadius.zero
                            : const BorderRadius.only(
                                topRight: Radius.circular(6),
                                bottomRight: Radius.circular(6)),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(MyColors.black),
                      ),
                    );
                  },
                ),
                // 보낼 수량
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    _requiredSignatureCount <=
                            _signersApproved.where((item) => item).length
                        ? '서명을 완료했습니다'
                        : '${_requiredSignatureCount - _signersApproved.where((item) => item).length}개의 서명이 필요합니다',
                    style: Styles.body2Bold,
                  ),
                ),
                // 보낼 주소
                Padding(
                  padding: const EdgeInsets.only(top: 32, left: 25, right: 25),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '보낼 주소',
                            style:
                                Styles.body2.copyWith(color: MyColors.grey57),
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
                            style:
                                Styles.body2.copyWith(color: MyColors.grey57),
                          ),
                          Text(
                            '${widget.bitcoinString} BTC',
                            style: Styles.balance2.copyWith(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Signer List
                Container(
                  margin: const EdgeInsets.only(top: 32, left: 20, right: 20),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      const length = 1;
                      const isVaultKey = true;
                      final name = _wallet.name;
                      const memo = '';
                      final iconIndex = _wallet.iconIndex;
                      final colorIndex = _wallet.colorIndex;

                      return Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: MyBorder.defaultRadius,
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
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(
                                            isVaultKey ? 10 : 12),
                                        decoration: BoxDecoration(
                                          color: isVaultKey
                                              ? BackgroundColorPalette[
                                                  colorIndex]
                                              : MyColors.grey236,
                                          borderRadius:
                                              BorderRadius.circular(16.0),
                                        ),
                                        child: SvgPicture.asset(
                                          isVaultKey
                                              ? CustomIcons.getPathByIndex(
                                                  iconIndex)
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
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: Styles.body2),
                                          if (memo.isNotEmpty) ...{
                                            Text(
                                              memo,
                                              style: Styles.caption2.copyWith(
                                                fontSize: 11,
                                              ),
                                            ),
                                          }
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  if (_signersApproved[index]) ...{
                                    Row(
                                      children: [
                                        Text(
                                          '서명완료',
                                          style: Styles.body1Bold.copyWith(
                                              fontSize: 12,
                                              color: Colors.black),
                                        ),
                                        const SizedBox(width: 4),
                                        SvgPicture.asset(
                                          'assets/svg/circle-check.svg',
                                          width: 12,
                                        ),
                                      ],
                                    ),
                                  } else if (_requiredSignatureCount >
                                      _signersApproved
                                          .where((item) => item)
                                          .length) ...{
                                    GestureDetector(
                                      onTap: () {
                                        _signStep1(isVaultKey, index);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: MyColors.white,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          border: Border.all(
                                              color: MyColors.black19,
                                              width: 1),
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
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Visibility(
              visible: _showLoading,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration:
                    const BoxDecoration(color: MyColors.transparentBlack_30),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: MyColors.darkgrey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
