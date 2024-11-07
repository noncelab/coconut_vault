import 'package:coconut_vault/model/vault_model.dart';
import 'package:coconut_vault/screens/pin_check_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class MultiSignatureScreen extends StatefulWidget {
  final String sendAddress;
  final String bitcoinString;
  const MultiSignatureScreen({
    super.key,
    required this.sendAddress,
    required this.bitcoinString,
  });

  @override
  State<MultiSignatureScreen> createState() => _MultiSignatureScreenState();
}

class _MultiSignatureScreenState extends State<MultiSignatureScreen> {
  // late AppModel _appModel;
  // late VaultModel _vaultModel;
  final _signedSignatureList = [false, false, false];
  int _requiredSignatureCount = 0;
  String _sendAddress = '';

  final testSignatureList = [
    TestMultiSignature(
        id: 1,
        name: 'qwer',
        colorIndex: 0,
        iconIndex: 0,
        secret:
            'control wonder horse expect notable proud eternal mountain swim path toe warm',
        passphrase: '',
        vaultJsonString:
            '''{"keyStore":"{"fingerprint":"ED8D1A16","hdWallet":"{\\"privateKey\\":\\"c800e15734782112ce1c39b95dfaae6f00a3cd4adc32701909e1c32c1bcf7c9f\\",\\"publicKey\\":\\"034f9728039cd80c090c36a506cd8b2b501eea20cac00e9cba944b9bd05e2b9bcf\\",\\"chainCode\\":\\"2af691cac33131f23da7df840bc6bdf863b7710a8fb95262b7e5f2e4a2fb6c5a\\"}","extendedPublicKey":"vpub5YGaouVZqpfDLquULQ6yeSAkKiq8NWepeiP8YJyJeFyCMvH4mwiRBw1NzN6cg8S4mKxNMxyN1Sdfckn7h91FwPEEJVfVVQDWoATyABdPbmX","seed":"{\\"entropy\\":\\"\\",\\"mnemonic\\":[\\"control\\",\\"wonder\\",\\"horse\\",\\"expect\\",\\"notable\\",\\"proud\\",\\"eternal\\",\\"mountain\\",\\"swim\\",\\"path\\",\\"toe\\",\\"warm\\"],\\"passphrase\\":\\"\\"}"}","addressType":"P2WPKH","derivationPath":"m/84'/1'/0'"}'''),
    TestMultiSignature(
        id: 2,
        name: '외부지갑',
        colorIndex: 0,
        iconIndex: 0,
        secret:
            'gravity ranch badge scorpion remind involve able mimic warrior buffalo outdoor air',
        passphrase: '',
        vaultJsonString: null),
    TestMultiSignature(
        id: 3,
        name: 'go',
        colorIndex: 4,
        iconIndex: 4,
        secret:
            'garlic concert text street avoid flavor rare mechanic hand hurry smile market',
        passphrase: '',
        vaultJsonString:
            '''{"keyStore":"{"fingerprint":"4638011E","hdWallet":"{\\"privateKey\\":\\"e8d63f05b7cfd54a7376576fad92dd6539e273867b0c7ee5cd9abaf962367f0f\\",\\"publicKey\\":\\"0357585c4682c23956be78e5ff867f2d3a1c57fa1c403a3b71a006e09cab438b54\\",\\"chainCode\\":\\"40bc2e20c426afe351fe035f2ea41646fce0f23de68ab3e9175462690981eb16\\"}","extendedPublicKey":"vpub5Y8gaU6obBfenCiBB4GoneXQqV2EXvZWpToCPi8j24XtuLFYvMiYPu53RRNkgyPdpBRwVFCLFVDqBEAkjUi4ySqFnYosnFJyuxmW9vsar7d","seed":"{\\"entropy\\":\\"\\",\\"mnemonic\\":[\\"garlic\\",\\"concert\\",\\"text\\",\\"street\\",\\"avoid\\",\\"flavor\\",\\"rare\\",\\"mechanic\\",\\"hand\\",\\"hurry\\",\\"smile\\",\\"market\\"],\\"passphrase\\":\\"\\"}"}","addressType":"P2WPKH","derivationPath":"m/84'/1'/0'"}'''),
  ];

  @override
  void initState() {
    // _appModel = Provider.of<AppModel>(context, listen: false);
    // _vaultModel = Provider.of<VaultModel>(context, listen: false);

    // TODO: 지정된 서명 숫자 가져오기
    _requiredSignatureCount = 2;

    _sendAddress =
        '${widget.sendAddress.substring(0, 15)}...${widget.sendAddress.substring(widget.sendAddress.length - 10, widget.sendAddress.length)}';

    super.initState();
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
                // TODO: 서명하기 다음 절차 구현
                Navigator.pushNamed(context, '/signed-transaction',
                    arguments: {'id': 1});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: _signedSignatureList.where((item) => item).length >=
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
              value: _signedSignatureList.where((item) => item).length /
                  _requiredSignatureCount,
              minHeight: 6,
              backgroundColor: MyColors.transparentBlack_06,
              borderRadius: _signedSignatureList.where((item) => item).length >=
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
              _requiredSignatureCount <=
                      _signedSignatureList.where((item) => item).length
                  ? '서명을 완료했습니다'
                  : '${_requiredSignatureCount - _signedSignatureList.where((item) => item).length}개의 서명이 필요합니다',
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
                      _sendAddress,
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
              itemCount: testSignatureList.length,
              itemBuilder: (context, index) {
                final length = testSignatureList.length - 1;
                final name = testSignatureList[index].name;
                final iconIndex = testSignatureList[index].iconIndex;
                final colorIndex = testSignatureList[index].colorIndex;
                final isVaultWallet =
                    testSignatureList[index].vaultJsonString != null;

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
                                  padding:
                                      EdgeInsets.all(isVaultWallet ? 10 : 12),
                                  decoration: BoxDecoration(
                                    color: isVaultWallet
                                        ? BackgroundColorPalette[colorIndex]
                                        : MyColors.grey236,
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: SvgPicture.asset(
                                    isVaultWallet
                                        ? CustomIcons.getPathByIndex(iconIndex)
                                        : 'assets/svg/download.svg',
                                    colorFilter: ColorFilter.mode(
                                      isVaultWallet
                                          ? ColorPalette[colorIndex]
                                          : MyColors.black,
                                      BlendMode.srcIn,
                                    ),
                                    width: isVaultWallet ? 20 : 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(name, style: Styles.body2),
                              ],
                            ),
                            const Spacer(),
                            if (_signedSignatureList[index]) ...{
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
                                _signedSignatureList
                                    .where((item) => item)
                                    .length) ...{
                              GestureDetector(
                                onTap: () {
                                  if (isVaultWallet) {
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
                                              _signedSignatureList[index] =
                                                  true;
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

class TestMultiSignature {
  final int id;
  final String name;
  final int colorIndex;
  final int iconIndex;
  final String secret;
  final String passphrase;
  String? vaultJsonString;

  TestMultiSignature({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.iconIndex,
    required this.secret,
    required this.passphrase,
    this.vaultJsonString,
  });
}
