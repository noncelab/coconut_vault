import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/multisig_signer.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/screens/airgap/psbt_confirmation_screen.dart';
import 'package:coconut_vault/screens/pin_check_screen.dart';
import 'package:coconut_vault/screens/vault_creation/multi_sig/signer_qr_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_creation/multi_sig/signer_scanner_bottom_sheet.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class MultiSignatureScreen extends StatefulWidget {
  final String id;
  final String psbtBase64;
  final String sendAddress;
  final String bitcoinString;
  const MultiSignatureScreen({
    super.key,
    required this.id,
    required this.psbtBase64,
    required this.sendAddress,
    required this.bitcoinString,
  });

  @override
  State<MultiSignatureScreen> createState() => _MultiSignatureScreenState();
}

class _MultiSignatureScreenState extends State<MultiSignatureScreen> {
  late VaultModel _vaultModel;
  late MultisigVaultListItem _multisigVaultItem;
  late MultisignatureVault _multisigVault;
  late List<bool> _signers;
  int _requiredSignatureCount = 0;
  bool _showLoading = false;
  bool _isProgressCompleted = false;

  @override
  void initState() {
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    super.initState();
    _multisigVaultItem =
        _vaultModel.getVaultById(int.parse(widget.id)) as MultisigVaultListItem;
    _multisigVault = _multisigVaultItem.coconutVault as MultisignatureVault;
    _signers = List<bool>.filled(_multisigVaultItem.signers.length, false);
    _requiredSignatureCount = _multisigVaultItem.requiredSignatureCount;
    _vaultModel.signedRawTx = null;
    _bindSeedToKeyStore();
    _checkSignedPsbt(widget.psbtBase64);
  }

  _bindSeedToKeyStore() {
    for (MultisigSigner signer in _multisigVaultItem.signers) {
      if (signer.innerVaultId != null) {
        final singleVaultItem = _vaultModel.getVaultById(signer.innerVaultId!)
            as SinglesigVaultListItem;
        final keyStore =
            (singleVaultItem.coconutVault as SingleSignatureVault).keyStore;
        final seed = keyStore.seed;
        _multisigVault.bindSeedToKeyStore(seed);
      }
    }
  }

  _checkSignedPsbt(String psbtBase64) {
    PSBT psbt = PSBT.parse(psbtBase64);

    for (KeyStore keyStore in _multisigVault.keyStoreList) {
      if (psbt.isSigned(keyStore)) {
        final index = _multisigVault.keyStoreList.indexOf(keyStore);
        _delayedUpdateSigner(index);
      }
    }
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
      _showQrBottomSheet(index);
    }
  }

  _signStep2(int index) async {
    try {
      setState(() {
        _showLoading = true;
      });

      final psbt = _vaultModel.signedRawTx == null
          ? widget.psbtBase64
          : _vaultModel.signedRawTx!;

      bool canSignResult =
          await canSignToPsbt(_multisigVaultItem.coconutVault, psbt);

      if (!canSignResult) {
        if (mounted) {
          showAlertDialog(context: context, content: "서명할 수 없는 트랜잭션입니다.");
        }
        return;
      }

      final signedTx =
          _multisigVault.keyStoreList[index].addSignatureToPsbt(psbt);

      _vaultModel.signedRawTx = signedTx;
      if (_vaultModel.signedRawTx == null) {
        if (mounted) {
          throw 'signedRawTx is null.';
        }
      }

      _delayedUpdateSigner(index);
    } catch (_) {
      if (mounted) {
        showAlertDialog(context: context, content: "서명 실패: $_");
      }
    } finally {
      setState(() {
        _showLoading = false;
      });
    }
  }

  void _delayedUpdateSigner(int index) {
    setState(() {
      _signers[index] = true;
    });
  }

  void _showQrBottomSheet(int index) {
    final signedRawTx = _vaultModel.signedRawTx == null
        ? widget.psbtBase64
        : _vaultModel.signedRawTx!;
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: SignerQrBottomSheet(
        multisigName: _multisigVaultItem.name,
        keyIndex: '${index + 1}',
        signedRawTx: signedRawTx,
      ),
    );
  }

  void _showScannerBottomSheet() {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: SignerScannerBottomSheet(
        onScanComplete: (signedRawTx) {
          _vaultModel.signedRawTx = signedRawTx;
          _checkSignedPsbt(signedRawTx);
          setState(() {});
        },
      ),
    );
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
              onTap: _requiredSignatureCount >
                      _signers.where((item) => item).length
                  ? null
                  : () {
                      if (mounted) {
                        Navigator.pushNamed(context, '/signed-transaction',
                            arguments: {'id': int.parse(widget.id)});
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: _signers.where((item) => item).length >=
                          _requiredSignatureCount
                      ? MyColors.black
                      : MyColors.transparentBlack_30,
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
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // progress
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: _signers.where((item) => item).length /
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
                            _signers.where((item) => item).length
                        ? '서명을 완료했습니다'
                        : '${_requiredSignatureCount - _signers.where((item) => item).length}개의 서명이 필요합니다',
                    style: Styles.body2Bold,
                  ),
                ),
                // 보낼 주소
                Padding(
                  padding: const EdgeInsets.only(top: 32, left: 20, right: 20),
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
                    itemCount: _multisigVaultItem.signers.length,
                    itemBuilder: (context, index) {
                      final signer = _multisigVaultItem.signers[index];
                      final length = _multisigVaultItem.signers.length - 1;
                      final isVaultKey = signer.innerVaultId != null;
                      final name = isVaultKey ? signer.name ?? '' : '외부지갑';
                      final memo = signer.memo ?? '';
                      final iconIndex = signer.iconIndex ?? 0;
                      final colorIndex =
                          _multisigVaultItem.signers[index].colorIndex ?? 0;

                      return Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(index == 0 ? 19 : 0),
                            topRight: Radius.circular(index == 0 ? 19 : 0),
                            bottomLeft:
                                Radius.circular(index == length ? 19 : 0),
                            bottomRight:
                                Radius.circular(index == length ? 19 : 0),
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
                                  SizedBox(
                                    width: 60,
                                    child: Text('${index + 1}번 키 -',
                                        style: Styles.body1),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
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
                                  if (_signers[index]) ...{
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
                                      _signers
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
                            if (index < length) ...{
                              const Divider(color: MyColors.divider, height: 1),
                            }
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(),
                // 종료, 서명 업데이트 버튼
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.popUntil(
                                context, (route) => route.isFirst);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: MyColors.white,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Center(
                              child: Text(
                                '종료',
                                style: TextStyle(
                                  color: MyColors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: _signers.where((item) => item).length >=
                                      _requiredSignatureCount ||
                                  _signers.where((item) => item).isEmpty
                              ? null
                              : _showScannerBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _signers.where((item) => item).length >=
                                          _requiredSignatureCount ||
                                      _signers.where((item) => item).isEmpty
                                  ? MyColors.transparentBlack_30
                                  : MyColors.black,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Center(
                              child: Text(
                                '서명 업데이트',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
}
