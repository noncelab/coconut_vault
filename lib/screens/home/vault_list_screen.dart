import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/app_routes_params.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/view_model/home/vault_list_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/home/tutorial_screen.dart';
import 'package:coconut_vault/screens/settings/pin_setting_screen.dart';
import 'package:coconut_vault/widgets/card/vault_addition_guide_card.dart';
import 'package:coconut_vault/widgets/vault_row_item.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/screens/settings/settings_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/frosted_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class VaultListScreen extends StatefulWidget {
  const VaultListScreen({
    super.key,
  });

  @override
  State<VaultListScreen> createState() => _VaultListScreenState();
}

class _VaultListScreenState extends State<VaultListScreen> with TickerProviderStateMixin {
  late VaultListViewModel _viewModel;

  late int _initialWalletCount;
  bool _isSeeMoreDropdown = false;

  DateTime? _lastPressedAt;

  late final AnimationController _newVaultAddAnimController;
  late final Animation<Offset> _newVaultAddAnimation;
  late ScrollController _scrollController;
  bool _shouldAnimateAddition = false;

  final GlobalKey _dropdownButtonKey = GlobalKey();
  Size _dropdownButtonSize = const Size(0, 0);
  Offset _dropdownButtonPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _viewModel = VaultListViewModel(
        Provider.of<AuthProvider>(context, listen: false),
        Provider.of<WalletProvider>(context, listen: false),
        Provider.of<VisibilityProvider>(context, listen: false).walletCount);
    _initialWalletCount = _viewModel.initialWalletCount;

    _scrollController = ScrollController();
    _newVaultAddAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _newVaultAddAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _newVaultAddAnimController,
        curve: Curves.easeOut,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_dropdownButtonKey.currentContext != null) {
        final faucetRenderBox = _dropdownButtonKey.currentContext?.findRenderObject() as RenderBox;
        _dropdownButtonPosition = faucetRenderBox.localToGlobal(Offset.zero);
        _dropdownButtonSize = faucetRenderBox.size;
      }

      if (_shouldAnimateAddition) {
        await Future.delayed(const Duration(milliseconds: 500));
        _newVaultAddAnimController.forward();
        _shouldAnimateAddition = false;
      }

      // 지갑 추가, 지갑 삭제, 서명완료 후 불필요하게 loadVaultList() 호출되는 것을 막음
      if (_viewModel.isWalletsLoaded) {
        return;
      }
      _viewModel.loadWallets();
    });
  }

  Widget _vaultSkeletonItem() => Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              constraints: const BoxConstraints(minHeight: 100),
              decoration: BoxDecoration(
                color: CoconutColors.white, // 배경색 유지
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: CoconutColors.black.withOpacity(0.15),
                    offset: const Offset(0, 0),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
              child: Row(
                children: [
                  // 1) 아이콘 스켈레톤
                  Shimmer.fromColors(
                    baseColor: CoconutColors.gray300,
                    highlightColor: CoconutColors.gray150,
                    child: Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: CoconutColors.gray300,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  // 2) 텍스트 영역
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 첫 번째 텍스트
                        Shimmer.fromColors(
                          baseColor: CoconutColors.gray300,
                          highlightColor: CoconutColors.gray150,
                          child: Container(
                            height: 14.0,
                            width: 100.0,
                            color: CoconutColors.gray300,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        // 두 번째 텍스트
                        Shimmer.fromColors(
                          baseColor: CoconutColors.gray300,
                          highlightColor: CoconutColors.gray150,
                          child: Container(
                            height: 14.0,
                            width: 150.0,
                            color: CoconutColors.gray300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as VaultListNavArgs?;
    if (args?.isWalletAdded == true) {
      _shouldAnimateAddition = true;
    }

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (Platform.isAndroid) {
            final now = DateTime.now();
            if (_lastPressedAt == null ||
                now.difference(_lastPressedAt!) > const Duration(seconds: 3)) {
              _lastPressedAt = now;
              Fluttertoast.showToast(
                backgroundColor: CoconutColors.gray500,
                msg: t.toast.back_exit,
                toastLength: Toast.LENGTH_SHORT,
              );
            } else {
              SystemNavigator.pop();
            }
          }
        },
        child:
            // ConnectivityProvider: 실제로 활용되지 않지만 참조해야, 네트워크/블루투스/개발자모드 연결 시 화면 전환이 됩니다.
            ChangeNotifierProxyProvider2<AuthProvider, ConnectivityProvider, VaultListViewModel>(
          create: (_) => _viewModel,
          update: (_, authProvider, connectivityProvider, viewModel) {
            return viewModel!;
          },
          child: Consumer<VaultListViewModel>(
            builder: (context, viewModel, child) {
              final wallets = viewModel.wallets;
              return Scaffold(
                backgroundColor: CoconutColors.gray150,
                body: Stack(
                  children: [
                    CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      // semanticChildCount:
                      //     model.isVaultListLoading ? 1 : vaults.length,
                      slivers: <Widget>[
                        FrostedAppBar(
                          enablePlusButton:
                              NetworkType.currentNetworkType.isTestnet || wallets.isEmpty,
                          onTapPlus: () {
                            if (viewModel.walletCount == 0 && !viewModel.isPinSet) {
                              MyBottomSheet.showBottomSheet_90(
                                  context: context,
                                  child: const PinSettingScreen(greetingVisible: true));
                            } else {
                              Navigator.pushNamed(context, AppRoutes.vaultTypeSelection);
                            }
                          },
                          onTapSeeMore: () {
                            setState(() {
                              _isSeeMoreDropdown = true;
                            });
                          },
                          dropdownKey: _dropdownButtonKey,
                        ),

                        // 바로 추가하기
                        SliverToBoxAdapter(
                          child: Visibility(
                            visible: viewModel.isWalletsLoaded && viewModel.walletCount == 0,
                            child: VaultAdditionGuideCard(
                              onPressed: () {
                                if (!viewModel.isPinSet) {
                                  MyBottomSheet.showBottomSheet_90(
                                      context: context,
                                      child: const PinSettingScreen(greetingVisible: true));
                                } else {
                                  Navigator.pushNamed(context, AppRoutes.vaultTypeSelection);
                                }
                              },
                            ),
                          ),
                        ),
                        // 지갑 목록
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CoconutLayout.defaultPadding,
                          ),
                          sliver: SliverList.builder(
                            itemCount: wallets.isEmpty ? 1 : wallets.length,
                            itemBuilder: (ctx, index) => index < wallets.length
                                ? _shouldAnimateAddition && index == 0
                                    ? SlideTransition(
                                        position: _newVaultAddAnimation,
                                        child: VaultRowItem(vault: wallets[index]),
                                      )
                                    : VaultRowItem(vault: wallets[index])
                                : Container(),
                          ),
                        ),
                        // Skeleton 목록
                        if (!viewModel.isWalletsLoaded)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: CoconutLayout.defaultPadding,
                            ),
                            sliver: SliverList.builder(
                              itemBuilder: (ctx, index) => _vaultSkeletonItem(),
                              itemCount: _initialWalletCount - wallets.length,
                            ),
                          ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 30),
                        ),
                      ],
                    ),

                    // 더보기
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
                          Positioned(
                            top: _dropdownButtonPosition.dy + _dropdownButtonSize.height,
                            right: 20,
                            child: CoconutPulldownMenu(
                              shadowColor: CoconutColors.gray300,
                              dividerColor: CoconutColors.gray200,
                              entries: [
                                CoconutPulldownMenuGroup(
                                  groupTitle: t.tool,
                                  items: [
                                    CoconutPulldownMenuItem(title: t.mnemonic_wordlist),
                                    if (NetworkType.currentNetworkType.isTestnet)
                                      CoconutPulldownMenuItem(title: t.tutorial),
                                  ],
                                ),
                                CoconutPulldownMenuItem(title: t.settings),
                                CoconutPulldownMenuItem(title: t.view_app_info),
                              ],
                              dividerHeight: 1,
                              thickDividerHeight: 3,
                              thickDividerIndexList: [
                                NetworkType.currentNetworkType.isTestnet ? 1 : 0,
                              ],
                              onSelected: ((index, selectedText) {
                                setState(() {
                                  _isSeeMoreDropdown = false;
                                });

                                // 메인넷의 경우 튜토리얼 항목을 넘어간다.
                                if (!NetworkType.currentNetworkType.isTestnet && index >= 1) {
                                  ++index;
                                }
                                switch (index) {
                                  case 0:
                                    // 지갑 복구 단어
                                    Navigator.pushNamed(context, AppRoutes.mnemonicWordList);
                                    break;
                                  case 1:
                                    MyBottomSheet.showBottomSheet_90(
                                      context: context,
                                      child: const TutorialScreen(
                                        screenStatus: TutorialScreenStatus.modal,
                                      ),
                                    );
                                    break;
                                  case 2:
                                    MyBottomSheet.showBottomSheet_90(
                                        context: context, child: const SettingsScreen());
                                    break;
                                  case 3:
                                    Navigator.pushNamed(context, AppRoutes.appInfo);
                                    break;
                                }
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _newVaultAddAnimController.dispose();
    super.dispose();
  }
}
