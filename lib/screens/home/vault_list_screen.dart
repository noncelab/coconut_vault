import 'dart:io';

import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/view_model/home/vault_list_view_model.dart';
import 'package:coconut_vault/screens/settings/pin_setting_screen.dart';
import 'package:coconut_vault/widgets/coconut_dropdown.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/screens/settings/settings_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/frosted_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/wallet_provider.dart';
import '../../widgets/vault_row_item.dart';

class VaultListScreen extends StatefulWidget {
  const VaultListScreen({
    super.key,
  });

  @override
  State<VaultListScreen> createState() => _VaultListScreenState();
}

class _VaultListScreenState extends State<VaultListScreen>
    with TickerProviderStateMixin {
  late VaultListViewModel _viewModel;

  late WalletProvider _vaultModel;
  bool _isSeeMoreDropdown = false;

  DateTime? _lastPressedAt;

  late final AnimationController _newVaultAddAnimController;
  late final Animation<Offset> _newVaultAddAnimation;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _viewModel =
        VaultListViewModel(Provider.of<AuthProvider>(context, listen: false));

    _vaultModel = Provider.of<WalletProvider>(context, listen: false);
    // final connectivityProvider =
    //     Provider.of<ConnectivityProvider>(context, listen: false);

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
      if (_vaultModel.animatedVaultFlags.isNotEmpty &&
          _vaultModel.animatedVaultFlags.last) {
        /// 리스트에 추가되는 애니메이션 보여줍니다.
        /// animatedVaultFlags last가 가장 최근에 추가된 항목이며, 이는 VaultModel의 addVault, addMultisigVaultAsync, importMultisigVaultAsync에서 적용됩니다.
        /// 애니메이션을 보여준 뒤에는 setAnimatedVaultFlags()를 실행해서 animatedVaultFlags를 모두 false로 설정해야 합니다.
        await Future.delayed(const Duration(milliseconds: 500));
        _scrollToBottom();
        await Future.delayed(const Duration(milliseconds: 500));
        _newVaultAddAnimController.forward();
        _vaultModel.setAnimatedVaultFlags();
      }

      if (_vaultModel.vaultInitialized) {
        return;
      }
      _vaultModel.loadVaultList();
    });
  }

  Widget _vaultSkeletonItem() => Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              constraints: const BoxConstraints(minHeight: 100),
              decoration: BoxDecoration(
                color: Colors.white, // 배경색 유지
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: MyColors.transparentBlack_15,
                    offset: Offset(0, 0),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
              child: Row(
                children: [
                  // 1) 아이콘 스켈레톤
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
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
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 14.0,
                            width: 100.0,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        // 두 번째 텍스트
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 14.0,
                            width: 150.0,
                            color: Colors.grey[300],
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

  void _scrollToBottom() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, model, child) {
        final vaults = model
            .getVaults(); // 여기서 _animatedVaultFlags = List.filled(_vaultList.length, false);
        return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) async {
              if (Platform.isAndroid) {
                final now = DateTime.now();
                if (_lastPressedAt == null ||
                    now.difference(_lastPressedAt!) >
                        const Duration(seconds: 3)) {
                  _lastPressedAt = now;
                  Fluttertoast.showToast(
                    backgroundColor: MyColors.grey,
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
                ChangeNotifierProxyProvider2<AuthProvider, ConnectivityProvider,
                    VaultListViewModel>(
              create: (_) => _viewModel,
              update: (_, authProvider, connectivityProvider, viewModel) {
                return viewModel!;
              },
              child: Consumer<VaultListViewModel>(
                builder: (context, viewModel, child) {
                  return Scaffold(
                    backgroundColor: MyColors.lightgrey,
                    body: Stack(
                      children: [
                        CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          // semanticChildCount:
                          //     model.isVaultListLoading ? 1 : vaults.length,
                          slivers: <Widget>[
                            FrostedAppBar(
                              onTapSeeMore: () {
                                setState(() {
                                  _isSeeMoreDropdown = true;
                                });
                              },
                            ),
                            // 바로 추가하기
                            SliverToBoxAdapter(
                              child: Visibility(
                                visible: viewModel.isLoadWalletsDone &&
                                    viewModel.walletCount == 0,
                                child: Container(
                                  width: double.maxFinite,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: MyColors.white),
                                  padding: const EdgeInsets.only(
                                      top: 26, bottom: 24, left: 26, right: 26),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.vault_list_tab.add_wallet,
                                        style: Styles.title5,
                                      ),
                                      Text(
                                        t.vault_list_tab.top_right_icon,
                                        style: Styles.label,
                                      ),
                                      const SizedBox(height: 16),
                                      CupertinoButton(
                                        onPressed: () {
                                          if (!viewModel.isPinSet) {
                                            MyBottomSheet.showBottomSheet_90(
                                                context: context,
                                                child: const PinSettingScreen(
                                                    greetingVisible: true));
                                          } else {
                                            Navigator.pushNamed(context,
                                                AppRoutes.vaultTypeSelection);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        padding: EdgeInsets.zero,
                                        color: MyColors.primary,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 28,
                                            vertical: 12,
                                          ),
                                          child: Text(
                                            t.vault_list_tab.btn_add,
                                            style: Styles.label.merge(
                                              const TextStyle(
                                                color: MyColors.black,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // 지갑 목록
                            SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              sliver: SliverList.builder(
                                itemCount:
                                    vaults.length + (vaults.isEmpty ? 1 : 0),
                                itemBuilder: (ctx, index) =>
                                    index < vaults.length
                                        ? model.animatedVaultFlags[index]
                                            ? SlideTransition(
                                                position: _newVaultAddAnimation,
                                                child: VaultRowItem(
                                                    vault: vaults[index]),
                                              )
                                            : VaultRowItem(vault: vaults[index])
                                        : Container(),
                              ),
                            ),
                            // Skeleton 목록
                            SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              sliver: SliverList.builder(
                                itemBuilder: (ctx, index) =>
                                    _vaultSkeletonItem(),
                                itemCount: _vaultModel.vaultSkeletonLength,
                              ),
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
                              Align(
                                alignment: Alignment.topRight,
                                child: CoconutDropdown(
                                  buttons: [
                                    t.mnemonic_wordlist,
                                    t.settings,
                                    t.view_app_info
                                  ],
                                  onTapButton: (index) {
                                    setState(() {
                                      _isSeeMoreDropdown = false;
                                    });
                                    switch (index) {
                                      case 0: // 니모닉 문구 단어집
                                        Navigator.pushNamed(context,
                                            AppRoutes.mnemonicWordList);
                                        break;
                                      case 1: // 설정
                                        MyBottomSheet.showBottomSheet_90(
                                            context: context,
                                            child: const SettingsScreen());
                                        break;
                                      case 2: // 앱 정보 보기
                                        Navigator.pushNamed(
                                            context, AppRoutes.appInfo);
                                        break;
                                    }
                                  },
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
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _newVaultAddAnimController.dispose();
    super.dispose();
  }
}
