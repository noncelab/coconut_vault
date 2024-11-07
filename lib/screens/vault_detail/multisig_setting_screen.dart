import 'dart:async';

import 'package:coconut_vault/screens/vault_detail/vault_edit_bottom_sheet_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/colors_util.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/bubble_clipper.dart';
import 'package:coconut_vault/widgets/button/tooltip_button.dart';
import 'package:coconut_vault/widgets/information_item_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// TODO: VaultSettings 에 병합 할 것인지 따로 관리할 것인지 협의 필요
class MultisigSettingScreen extends StatefulWidget {
  final String id;
  const MultisigSettingScreen({super.key, required this.id});

  @override
  State<MultisigSettingScreen> createState() => _MultisigSettingScreenState();
}

class _MultisigSettingScreenState extends State<MultisigSettingScreen> {
  final GlobalKey _tooltipIconKey = GlobalKey();

  Timer? _tooltipTimer;
  int _tooltipRemainingTime = 0;

  // TODO: TEST용
  String _titleName = '';
  String _address = '';
  int _colorIndex = 0;
  int _iconIndex = 0;
  int _requiredSignatureCount = 0;
  int _vaultCount = 0;
  final testMultiSigList = [
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
  /// 다중서명 지갑의 그라디언트 색상을 반환합니다.
  /// 지갑이 1개일 경우 [color1, borderLightgrey, color1] 형태로 반환
  /// 지갑이 2개일 경우 [color1, borderLightgrey, color2] 형태로 반환
  /// 지갑이 3개 이상일 경우 [color1, color2, color3] 형태로 반환
  /// 각 지갑의 vaultJsonString이 null인 경우(외부지갑) borderLightgrey 색상 사용
  /// @param multiSigList 다중서명 지갑 목록
  /// @return 그라디언트 색상 목록
  List<Color> getGradientColors(List<TestMultiSig> multiSigList) {
    // 빈 리스트 처리
    if (multiSigList.isEmpty) {
      return [MyColors.borderLightgrey];
    }

    // 색상 가져오는 헬퍼 함수
    Color getColor(TestMultiSig item) {
      return item.vaultJsonString != null
          ? CustomColorHelper.getColorByIndex(item.colorIndex)
          : MyColors.borderLightgrey;
    }

    // 1개인 경우
    if (multiSigList.length == 1) {
      final color = getColor(multiSigList[0]);
      return [color, MyColors.borderLightgrey, color];
    }

    // 2개인 경우
    if (multiSigList.length == 2) {
      return [
        getColor(multiSigList[0]),
        MyColors.borderLightgrey,
        getColor(multiSigList[1]),
      ];
    }

    // 3개 이상인 경우
    return [
      getColor(multiSigList[0]),
      getColor(multiSigList[1]),
      getColor(multiSigList[2]),
    ];
  }

  void _showTooltip(BuildContext context) {
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

  void _removeTooltip() {
    setState(() {
      _tooltipRemainingTime = 0;
    });
    _tooltipTimer?.cancel();
  }

  void _showModalBottomSheetForEditingNameAndIcon(
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

  @override
  void initState() {
    // TODO: 다중지갑 정보 가져오기
    _titleName = '다중지갑';
    _address = '다중 서명 주소';
    _colorIndex = 4;
    _iconIndex = 4;
    _requiredSignatureCount = 2;
    _vaultCount =
        testMultiSigList.where((item) => item.vaultJsonString != null).length;

    super.initState();
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tooltipTop = MediaQuery.of(context).padding.top + 24;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        _tooltipTimer?.cancel();
      },
      child: Scaffold(
        backgroundColor: MyColors.white,
        appBar: CustomAppBar.build(
          title: '$_titleName 정보',
          context: context,
          hasRightIcon: false,
          isBottom: false,
          onBackPressed: () {
            Navigator.pop(context);
          },
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // 다중 서명 지갑
                  Container(
                    margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
                    decoration: BoxDecoration(
                      color: MyColors.white,
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        colors: getGradientColors(testMultiSigList),
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
                              color: BackgroundColorPalette[_colorIndex],
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                            child: SvgPicture.asset(
                              CustomIcons.getPathByIndex(_iconIndex),
                              colorFilter: ColorFilter.mode(
                                  ColorPalette[_colorIndex], BlendMode.srcIn),
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
                                    _titleName,
                                    style: Styles.h3,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )),
                                  const SizedBox(width: 7),
                                  GestureDetector(
                                      onTap: () {
                                        _removeTooltip();
                                        _showModalBottomSheetForEditingNameAndIcon(
                                          _titleName,
                                          _colorIndex,
                                          _iconIndex,
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
                                  style: Styles.body2Bold.merge(const TextStyle(
                                      color: MyColors.transparentBlack_30)),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(
                            flex: 1,
                          ),

                          // M/N, 볼트로 N개 서명 가능
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TooltipButton(
                                isSelected: false,
                                text:
                                    '$_requiredSignatureCount/${testMultiSigList.length}',
                                isLeft: true,
                                iconkey: _tooltipIconKey,
                                containerMargin: EdgeInsets.zero,
                                onTap: () {},
                                onTapDown: (details) {
                                  _showTooltip(context);
                                },
                              ),
                              Text(
                                '볼트로 $_vaultCount개 서명 가능',
                                style: Styles.body2Bold.merge(TextStyle(
                                    fontSize: 12,
                                    fontFamily:
                                        CustomFonts.number.getFontFamily)),
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
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    itemCount: testMultiSigList.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = testMultiSigList[index];

                      return Row(
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
                                border: Border.all(color: MyColors.greyE9),
                              ),
                              child: Row(
                                children: [
                                  // 아이콘
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: item.vaultJsonString != null
                                          ? BackgroundColorPalette[
                                              item.colorIndex]
                                          : MyColors.greyEC,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: item.vaultJsonString != null
                                        ? SvgPicture.asset(
                                            CustomIcons.getPathByIndex(
                                                item.iconIndex),
                                            colorFilter: ColorFilter.mode(
                                                ColorPalette[item.colorIndex],
                                                BlendMode.srcIn),
                                            width: 20,
                                          )
                                        : const Icon(Icons.download,
                                            size: 20,
                                            color: MyColors.body2Grey), //TODO:
                                  ),

                                  const SizedBox(width: 12),

                                  // 이름
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: Styles.body2Bold,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // MFP 텍스트
                                  Text(
                                    'MFP${index + 1}',
                                    style: Styles.body2Bold
                                        .copyWith(color: MyColors.darkgrey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                            InformationRowItem(
                              label: '지갑 설정 정보 보기',
                              showIcon: true,
                              onPressed: () {
                                // TODO: 니모닉 문구 보기 연동
                                _removeTooltip();
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
                                child: SvgPicture.asset('assets/svg/trash.svg',
                                    width: 16,
                                    colorFilter: const ColorFilter.mode(
                                        MyColors.warningText,
                                        BlendMode.srcIn))),
                            onPressed: () {
                              // TODO: 삭제하기 연동
                              _removeTooltip();
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
                                '${testMultiSigList.length}개의 키 중 $_requiredSignatureCount개로 서명해야 하는\n다중 서명 지갑이예요.',
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
                    )),
              )
            ],
          ),
        ),
      ),
    );
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
