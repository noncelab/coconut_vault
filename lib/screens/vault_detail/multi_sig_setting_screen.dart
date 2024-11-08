import 'dart:async';

import 'package:coconut_vault/model/app_model.dart';
import 'package:coconut_vault/screens/pin_check_screen.dart';
import 'package:coconut_vault/screens/vault_detail/mnemonic_view_screen.dart';
import 'package:coconut_vault/screens/vault_detail/multi_sig_memo_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_detail/vault_edit_bottom_sheet_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/alert_util.dart';
import 'package:coconut_vault/utils/colors_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/bubble_clipper.dart';
import 'package:coconut_vault/widgets/button/tooltip_button.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/information_item_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

// TODO: VaultSettings 에 병합 할 것인지 따로 관리할 것인지 협의 필요
class MultiSigSettingScreen extends StatefulWidget {
  final String id;
  const MultiSigSettingScreen({super.key, required this.id});

  @override
  State<MultiSigSettingScreen> createState() => _MultiSigSettingScreenState();
}

class _MultiSigSettingScreenState extends State<MultiSigSettingScreen> {
  late AppModel _appModel;
  final GlobalKey _tooltipIconKey = GlobalKey();

  Timer? _tooltipTimer;
  int _tooltipRemainingTime = 0;

  // TODO: TEST용
  late TestMultiSig testVault;
  String _address = '';
  String _masterFingerPrint = '';
  int _requiredSignatureCount = 0;
  final testVaultList = [
    TestMultiSig(
        id: 1,
        name: 'qwer',
        colorIndex: 0,
        iconIndex: 0,
        secret:
            'control wonder horse expect notable proud eternal mountain swim path toe warm',
        passphrase: '',
        vaultJsonString:
            '''{"keyStore":"{"fingerprint":"ED8D1A16","hdWallet":"{\\"privateKey\\":\\"c800e15734782112ce1c39b95dfaae6f00a3cd4adc32701909e1c32c1bcf7c9f\\",\\"publicKey\\":\\"034f9728039cd80c090c36a506cd8b2b501eea20cac00e9cba944b9bd05e2b9bcf\\",\\"chainCode\\":\\"2af691cac33131f23da7df840bc6bdf863b7710a8fb95262b7e5f2e4a2fb6c5a\\"}","extendedPublicKey":"vpub5YGaouVZqpfDLquULQ6yeSAkKiq8NWepeiP8YJyJeFyCMvH4mwiRBw1NzN6cg8S4mKxNMxyN1Sdfckn7h91FwPEEJVfVVQDWoATyABdPbmX","seed":"{\\"entropy\\":\\"\\",\\"mnemonic\\":[\\"control\\",\\"wonder\\",\\"horse\\",\\"expect\\",\\"notable\\",\\"proud\\",\\"eternal\\",\\"mountain\\",\\"swim\\",\\"path\\",\\"toe\\",\\"warm\\"],\\"passphrase\\":\\"\\"}"}","addressType":"P2WPKH","derivationPath":"m/84'/1'/0'"}'''),
    TestMultiSig(
        id: 2,
        name: '외부지갑',
        colorIndex: 0,
        iconIndex: 0,
        secret:
            'gravity ranch badge scorpion remind involve able mimic warrior buffalo outdoor air',
        passphrase: '',
        vaultJsonString: null),
    TestMultiSig(
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

  // TODO: 외부 지갑 구분에 따른 로직 수정 필요함
  List<Color> getGradientColors(List<TestMultiSig> list) {
    // 빈 리스트 처리
    if (list.isEmpty) {
      return [MyColors.borderLightgrey];
    }

    // 색상 가져오는 헬퍼 함수
    Color getColor(TestMultiSig item) {
      return item.name != '외부지갑'
          ? CustomColorHelper.getColorByIndex(item.colorIndex)
          : MyColors.borderLightgrey;
    }

    // 1개인 경우
    if (list.length == 1) {
      final color = getColor(testVaultList[0]);
      return [color, MyColors.borderLightgrey, color];
    }

    // 2개인 경우
    if (testVaultList.length == 2) {
      return [
        getColor(testVaultList[0]),
        MyColors.borderLightgrey,
        getColor(testVaultList[1]),
      ];
    }

    // 3개 이상인 경우
    return [
      getColor(testVaultList[0]),
      getColor(testVaultList[1]),
      getColor(testVaultList[2]),
    ];
  }

  @override
  void initState() {
    _appModel = Provider.of<AppModel>(context, listen: false);
    super.initState();

    // TODO: 다중지갑 정보 가져오기
    testVault = TestMultiSig(
      id: 5,
      name: '다중지갑',
      colorIndex: 7,
      iconIndex: 7,
      secret:
          'gravity ranch badge scorpion remind involve able mimic warrior buffalo outdoor air',
      passphrase: '',
    );
    _address = '다중 서명 주소';
    _masterFingerPrint = 'MFP000';
    _requiredSignatureCount = 2;
  }

  _showTooltip(BuildContext context) {
    _removeTooltip();

    setState(() {
      _tooltipRemainingTime = 5;
    });

    _tooltipTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_tooltipRemainingTime > 0) {
          _tooltipRemainingTime--;
        } else {
          _removeTooltip();
          timer.cancel();
        }
      });
    });
  }

  _removeTooltip() {
    setState(() {
      _tooltipRemainingTime = 0;
    });
    _tooltipTimer?.cancel();
  }

  _showModalBottomSheetForEditingNameAndIcon(
      String name, int colorIndex, int iconIndex) {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: VaultInfoEditBottomSheet(
        name: name,
        iconIndex: iconIndex,
        colorIndex: colorIndex,
        onUpdate: (String newName, int newIconIndex, int newColorIndex) {
          // TODO: icon update
        },
      ),
    );
  }

  _showEditMemoBottomSheet(TestMultiSig selectedVault) {
    // TODO: 기존 메모 전송, 임시로 name 전송
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MultiSigMemoBottomSheet(
        memo: '',
        onUpdate: (memo) {
          // TODO: 메모 업데이트 처리
          Navigator.pop(context);
        },
      ),
    );
  }

  /*void _showModalBottomSheetWithQrImage(String appBarTitle, String data, Widget? qrcodeTopWidget) {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: QrcodeBottomSheetScreen(
        qrData: data,
        title: appBarTitle,
        qrcodeTopWidget: qrcodeTopWidget,
      ),
    );
  }*/

  Future _verifyBiometric(int status, {TestMultiSig? selectedVault}) async {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          screenStatus: PinCheckScreenStatus.info,
          isDeleteScreen: true,
          onComplete: () async {
            Navigator.pop(context);
            // TODO: 0 -> 확장 공개키, 1 -> 니모닉, 2 -> 삭제
            switch (status) {
              case 0:
                if (selectedVault != null) {
                  // SingleSignatureVault vault = selectedVault.coconutVault;
                  // _showModalBottomSheetWithQrImage(
                  //   '확장 공개키',
                  //   vault.keyStore.extendedPublicKey.serialize(),
                  //   null,
                  // );
                }
                break;
              case 1:
                if (selectedVault != null) {
                  MyBottomSheet.showBottomSheet_90(
                    context: context,
                    child: MnemonicViewScreen(
                      mnemonic: selectedVault.secret,
                      passphrase: selectedVault.passphrase,
                      title: '니모닉 문구 보기',
                      subtitle: '패스프레이즈 보기',
                    ),
                  );
                }
                break;
              default:
              // _vaultModel.deleteVault(int.parse(widget.id));
              // vibrateLight();
              // Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
        ),
      ),
    );
  }

  Future _selectedKeyBottomSheet(TestMultiSig vault) async {
    // TODO: 로직 수정 필요함
    final isCoconutVault = vault.name != '외부지갑';
    // bool isCreatedMemo = false;
    MyBottomSheet.showBottomSheet(
      context: context,
      title: vault.name.length > 20
          ? '${vault.name.substring(0, 17)}...'
          : vault.name,
      titleTextStyle: Styles.body1.copyWith(
        fontSize: 18,
      ),
      isCloseButton: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.only(bottom: 84),
        child: Column(
          children: [
            _bottomSheetButton(
              '다중 서명용 확장 공개키 보기',
              onPressed: () {
                // TODO: 확장 공개키
                _verifyBiometric(0, selectedVault: vault);
              },
            ),
            const Divider(),
            _bottomSheetButton(
              isCoconutVault
                  ? '니모닉 문구 보기'
                  : /*isCreatedMemo ? '메모 수정' :*/ '메모 추가',
              onPressed: () {
                if (isCoconutVault) {
                  // TODO: 니모닉 문구 보기
                  _verifyBiometric(1, selectedVault: vault);
                } else {
                  // TODO: 메모하기
                  _showEditMemoBottomSheet(vault);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomSheetButton(String title, {required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: () {
        onPressed.call();
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.only(
          top: 30,
          bottom: 30,
          left: 8,
        ),
        width: double.infinity,
        child: Text(
          title,
          style: Styles.body1Bold,
          textAlign: TextAlign.left, // 텍스트 왼쪽 정렬
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tooltipTop = MediaQuery.of(context).padding.top + 46;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        _tooltipTimer?.cancel();
      },
      child: Scaffold(
        backgroundColor: MyColors.white,
        appBar: CustomAppBar.build(
          title: '${testVault.name} 정보',
          context: context,
          hasRightIcon: false,
          isBottom: false,
          onBackPressed: () {
            Navigator.pop(context);
          },
        ),
        body: SingleChildScrollView(
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // 다중 서명 지갑
                    Container(
                      margin:
                          const EdgeInsets.only(top: 20, left: 16, right: 16),
                      decoration: BoxDecoration(
                        color: MyColors.white,
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          colors: getGradientColors(testVaultList),
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        padding: const EdgeInsets.only(
                            left: 24, right: 24, top: 30, bottom: 24),
                        decoration: BoxDecoration(
                          color: MyColors.white,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 아이콘
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: BackgroundColorPalette[
                                    testVault.colorIndex],
                                borderRadius: BorderRadius.circular(18.0),
                              ),
                              child: SvgPicture.asset(
                                CustomIcons.getPathByIndex(testVault.iconIndex),
                                colorFilter: ColorFilter.mode(
                                    ColorPalette[testVault.iconIndex],
                                    BlendMode.srcIn),
                                width: 28.0,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            // 이름, 편집버튼, 주소
                            Flexible(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Flexible(
                                        child: Text(
                                      testVault.name,
                                      style: Styles.h3,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                    const SizedBox(width: 7),
                                    GestureDetector(
                                        onTap: () {
                                          _removeTooltip();
                                          _showModalBottomSheetForEditingNameAndIcon(
                                            testVault.name,
                                            testVault.iconIndex,
                                            testVault.colorIndex,
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              color: MyColors.lightgrey),
                                          child: const Padding(
                                            padding: EdgeInsets.all(5.0),
                                            child: Icon(
                                              Icons.edit,
                                              color: MyColors.darkgrey,
                                              size: 14,
                                            ),
                                          ),
                                        ))
                                  ]),
                                  Text(
                                    _address,
                                    style: Styles.body2Bold.merge(
                                        const TextStyle(
                                            color:
                                                MyColors.transparentBlack_30)),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(
                              flex: 1,
                            ),

                            // MFP, M/N, 볼트로 N개 서명 가능
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _masterFingerPrint,
                                  style: Styles.body1Bold,
                                ),
                                TooltipButton(
                                  isSelected: false,
                                  text:
                                      '$_requiredSignatureCount/${testVaultList.length}',
                                  isLeft: true,
                                  iconkey: _tooltipIconKey,
                                  containerMargin: EdgeInsets.zero,
                                  onTap: () {},
                                  onTapDown: (details) {
                                    _showTooltip(context);
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    // 상세 지갑 리스트
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      itemCount: testVaultList.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = testVaultList[index];

                        return GestureDetector(
                          onTap: () {
                            _selectedKeyBottomSheet(item);
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                // 왼쪽 인덱스 번호
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '${index + 1}',
                                    textAlign: TextAlign.center,
                                    style: Styles.body2.merge(
                                      TextStyle(
                                          fontSize: 16,
                                          fontFamily:
                                              CustomFonts.number.getFontFamily),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12), // 간격

                                // 카드 영역
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: MyColors.white,
                                      borderRadius: BorderRadius.circular(17),
                                      border:
                                          Border.all(color: MyColors.greyE9),
                                    ),
                                    child: Row(
                                      children: [
                                        // 아이콘
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: item.name != '외부지갑'
                                                ? BackgroundColorPalette[
                                                    item.colorIndex]
                                                : MyColors.greyEC,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: item.name != '외부지갑'
                                              ? SvgPicture.asset(
                                                  CustomIcons.getPathByIndex(
                                                      item.iconIndex),
                                                  colorFilter: ColorFilter.mode(
                                                      ColorPalette[
                                                          item.colorIndex],
                                                      BlendMode.srcIn),
                                                  width: 20,
                                                )
                                              : const Icon(Icons.download,
                                                  size: 20,
                                                  color: MyColors
                                                      .body2Grey), //TODO:
                                        ),

                                        const SizedBox(width: 12),

                                        // 이름
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: Styles.body2,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        // MFP 텍스트
                                        // TODO: MFP 가져오기 변경
                                        Text(
                                          'MFP${index + 1}',
                                          style: Styles.body1.copyWith(
                                              color: MyColors.darkgrey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // 지갑설정 정보보기, 삭제하기
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28.0),
                          color: MyColors.transparentBlack_03,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              // TODO: exportDetail
                              InformationRowItem(
                                label: '지갑 설정 정보 보기',
                                showIcon: true,
                                onPressed: () {
                                  _removeTooltip();
                                  Navigator.pushNamed(context, '/multisig-bsms',
                                      arguments: {
                                        'exportDetail':
                                            '''{"name":"qo","colorIndex":4,"iconIndex":4,"descriptor":"wpkh([4638011E/84'/1'/0']vpub5Y8gaU6obBfenCiBB4GoneXQqV2EXvZWpToCPi8j24XtuLFYvMiYPu53RRNkgyPdpBRwVFCLFVDqBEAkjUi4ySqFnYosnFJyuxmW9vsar7d/<0;1>/*)#a35u9ufu"}'''
                                      });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28.0),
                          color: MyColors.transparentBlack_03,
                        ),
                        child: Column(
                          children: [
                            InformationRowItem(
                              label: '삭제하기',
                              showIcon: true,
                              rightIcon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: MyColors.transparentWhite_70,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: SvgPicture.asset(
                                      'assets/svg/trash.svg',
                                      width: 16,
                                      colorFilter: const ColorFilter.mode(
                                          MyColors.warningText,
                                          BlendMode.srcIn))),
                              onPressed: () {
                                _removeTooltip();
                                showConfirmDialog(
                                  context: context,
                                  title: '확인',
                                  content:
                                      '정말로 볼트에서 ${testVault.name} 정보를 삭제하시겠어요?',
                                  onConfirmPressed: () async {
                                    _appModel.showIndicator();
                                    await Future.delayed(
                                        const Duration(seconds: 1));
                                    _verifyBiometric(2);
                                    _appModel.hideIndicator();
                                    //context.go('/');
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // ToolTip
                Visibility(
                  visible: _tooltipRemainingTime > 0,
                  child: Positioned(
                    top: tooltipTop,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => _removeTooltip(),
                      child: ClipPath(
                        clipper: RightTriangleBubbleClipper(),
                        child: Container(
                          padding: const EdgeInsets.only(
                            top: 25,
                            left: 10,
                            right: 10,
                            bottom: 10,
                          ),
                          color: MyColors.darkgrey,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${testVaultList.length}개의 키 중 $_requiredSignatureCount개로 서명해야 하는\n다중 서명 지갑이예요.',
                                style: Styles.caption.merge(TextStyle(
                                  height: 1.3,
                                  fontFamily: CustomFonts.text.getFontFamily,
                                  color: MyColors.white,
                                )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    super.dispose();
  }
}

class TestMultiSig {
  final int id;
  final String name;
  final int colorIndex;
  final int iconIndex;
  final String secret;
  final String passphrase;
  String? vaultJsonString;

  TestMultiSig({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.iconIndex,
    required this.secret,
    required this.passphrase,
    this.vaultJsonString,
  });
}
