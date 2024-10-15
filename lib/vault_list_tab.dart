import 'dart:io';

import 'package:coconut_vault/app.dart';
import 'package:coconut_vault/screens/pin_check_screen.dart';
import 'package:coconut_vault/widgets/coconut_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/model/app_model.dart';
import 'package:coconut_vault/screens/setting/settings_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/frosted_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'model/vault_model.dart';
import 'widgets/vault_row_item.dart';

class VaultListTab extends StatefulWidget {
  final bool? reload;
  const VaultListTab({
    super.key,
    this.reload = true,
  });

  @override
  State<VaultListTab> createState() => _VaultListTabState();
}

class _VaultListTabState extends State<VaultListTab>
    with WidgetsBindingObserver {
  late AppModel _appModel;
  late VaultModel _vaultModel;
  bool _isSeeMoreDropdown = false;

  DateTime? _lastPressedAt;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _appModel = Provider.of<AppModel>(context, listen: false);
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.reload == null || widget.reload == true) {
        _vaultModel.loadVaultList();
      }

      // 초기화 이후 홈화면 진입시 설정창 노출
      if (_appModel.isResetVault) {
        MyBottomSheet.showBottomSheet_90(
            context: context, child: const SettingsScreen());
        _appModel.offResetVault();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /// 앱이 pause 되면 pin or bio 확인창 이동
    if (AppLifecycleState.paused == state && _appModel.isNotEmptyVaultList) {
      _vaultModel.lockClear();
      Navigator.pushNamedAndRemoveUntil(
          context, '/vault-lock', (Route<dynamic> route) => false,
          arguments: {
            'screenStatus': PinCheckScreenStatus.lock,
            'onReset': () {
              HomeScreenStatus().updateScreenStatus(HomeScreen.vaultlist);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (Route<dynamic> route) => false,
              );
            },
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VaultModel>(
      builder: (context, model, child) {
        final vaults = model.getVaults();
        final vaultListLoading = model.isVaultListLoading;

        return PopScope(
            canPop: false,
            onPopInvoked: (didPop) async {
              if (Platform.isAndroid) {
                final now = DateTime.now();
                if (_lastPressedAt == null ||
                    now.difference(_lastPressedAt!) >
                        const Duration(seconds: 3)) {
                  _lastPressedAt = now;
                  Fluttertoast.showToast(
                    backgroundColor: MyColors.grey,
                    msg: "뒤로 가기 버튼을 한 번 더 누르면 종료됩니다.",
                    toastLength: Toast.LENGTH_SHORT,
                  );
                } else {
                  SystemNavigator.pop();
                }
              }
            },
            child: Scaffold(
              backgroundColor: MyColors.lightgrey,
              body: Stack(
                children: [
                  CustomScrollView(
                    semanticChildCount:
                        model.isVaultListLoading ? 1 : vaults.length,
                    slivers: <Widget>[
                      FrostedAppBar(
                        onTapSeeMore: () {
                          setState(() {
                            _isSeeMoreDropdown = true;
                          });
                        },
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        sliver: SliverList.builder(
                          itemCount: vaults.length + (vaults.isEmpty ? 1 : 0),
                          itemBuilder: (ctx, index) {
                            if (index < vaults.length) {
                              return VaultRowItem(vault: vaults[index]);
                            }

                            if (index == vaults.length && vaults.isEmpty) {
                              if (!vaultListLoading) {
                                return CustomTooltip(
                                    richText: RichText(
                                        text: TextSpan(
                                            text:
                                                '안녕하세요. 코코넛 볼트예요!\n\n오른쪽 위 + 버튼을 눌러 니모닉 문구를 추가해 주세요.',
                                            style: Styles.subLabel.merge(
                                                const TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    color:
                                                        MyColors.darkgrey)))),
                                    showIcon: true,
                                    type: TooltipType.normal);
                              }
                            }

                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  Visibility(
                    visible: _isSeeMoreDropdown,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTapDown: (details) {
                            setState(() {
                              _isSeeMoreDropdown = false;
                            });
                          },
                          child: Container(
                            width: double.maxFinite,
                            height: double.maxFinite,
                            color: Colors.transparent,
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: CoconutDropdown(
                            buttons: const ['니모닉 문구 단어집', '설정', '앱 정보 보기'],
                            onTapButton: (index) {
                              setState(() {
                                _isSeeMoreDropdown = false;
                              });
                              switch (index) {
                                case 0: // 니모닉 문구 단어집
                                  Navigator.pushNamed(
                                      context, '/mnemonic-word-list');
                                  break;
                                case 1: // 설정
                                  MyBottomSheet.showBottomSheet_90(
                                      context: context,
                                      child: const SettingsScreen());
                                  break;
                                case 2: // 앱 정보 보기
                                  Navigator.pushNamed(context, '/app-info');
                                  break;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                      visible: vaultListLoading,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: MyColors.darkgrey,
                          ),
                        ),
                      )),
                ],
              ),
            ));
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
