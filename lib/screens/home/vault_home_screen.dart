import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/app_routes_params.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/view_model/home/vault_home_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/home/tutorial_screen.dart';
import 'package:coconut_vault/screens/settings/pin_setting_screen.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/card/vault_addition_guide_card.dart';
import 'package:coconut_vault/widgets/vault_row_item.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/screens/settings/settings_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class VaultHomeScreen extends StatefulWidget {
  const VaultHomeScreen({
    super.key,
  });

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> with TickerProviderStateMixin {
  late VaultHomeViewModel _viewModel;

  DateTime? _lastPressedAt;

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _viewModel = VaultHomeViewModel(
        Provider.of<AuthProvider>(context, listen: false),
        Provider.of<WalletProvider>(context, listen: false),
        Provider.of<VisibilityProvider>(context, listen: false).walletCount);

    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 지갑 추가, 지갑 삭제, 서명완료 후 불필요하게 loadVaultList() 호출되는 것을 막음
      if (_viewModel.isWalletsLoaded) {
        return;
      }
      _viewModel.loadWallets();
    });
  }

  bool isEnablePlusButton(bool isWalletsLoaded, bool isWalletEmpty) {
    return NetworkType.currentNetworkType.isTestnet || (isWalletsLoaded && isWalletEmpty);
  }

  @override
  Widget build(BuildContext context) {
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
          ChangeNotifierProxyProvider3<AuthProvider, ConnectivityProvider, VisibilityProvider,
              VaultHomeViewModel>(
        create: (_) => _viewModel,
        update: (_, authProvider, connectivityProvider, visibilityProvider, viewModel) {
          return viewModel!;
        },
        child: Consumer2<VaultHomeViewModel, VisibilityProvider>(
          builder: (context, viewModel, visibilityProvider, child) {
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
                      _buildAppBar(context, viewModel, wallets),
                      _buildWalletList(context),
                      SliverToBoxAdapter(
                        child: Container(
                          color: CoconutColors.gray100,
                          height: 12,
                        ),
                      ),
                      _buildWalletActionItems(context),

                      // 지갑 목록
                      // SliverPadding(
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: CoconutLayout.defaultPadding,
                      //   ),
                      //   sliver: SliverList.builder(
                      //     itemCount: wallets.isEmpty ? 1 : wallets.length,
                      //     itemBuilder: (ctx, index) => index < wallets.length
                      //         ? _shouldAnimateAddition && index == 0
                      //             ? SlideTransition(
                      //                 position: _newVaultAddAnimation,
                      //                 child: VaultRowItem(vault: wallets[index]),
                      //               )
                      //             : VaultRowItem(vault: wallets[index])
                      //         : Container(),
                      //   ),
                      // ),
                      // // Skeleton 목록
                      // if (!viewModel.isWalletsLoaded)
                      //   SliverPadding(
                      //     padding: const EdgeInsets.symmetric(
                      //       horizontal: CoconutLayout.defaultPadding,
                      //     ),
                      //     sliver: SliverList.builder(
                      //       itemBuilder: (ctx, index) => _vaultSkeletonItem(),
                      //       itemCount: _initialWalletCount - wallets.length,
                      //     ),
                      //   ),
                      // const SliverToBoxAdapter(
                      //   child: SizedBox(height: 30),
                      // ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
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

  SliverAppBar _buildAppBar(
      BuildContext context, VaultHomeViewModel viewModel, List<VaultListItemBase> wallets) {
    return CoconutAppBar.buildHomeAppbar(
      context: context,
      leadingSvgAsset: const SizedBox.shrink(key: ValueKey('empty')),
      appTitle: '',
      actionButtonList: [
        Opacity(
          opacity: isEnablePlusButton(viewModel.isWalletsLoaded, wallets.isEmpty) ? 1.0 : 0.2,
          child: _buildAppBarIconButton(
            key: GlobalKey(),
            icon: SvgPicture.asset(
              'assets/svg/wallet-plus.svg',
              colorFilter: const ColorFilter.mode(
                CoconutColors.gray800,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () {
              if (!isEnablePlusButton(viewModel.isWalletsLoaded, wallets.isEmpty)) {
                return;
              }

              if (viewModel.walletCount == 0 && !viewModel.isPinSet) {
                MyBottomSheet.showBottomSheet_90(
                    context: context, child: const PinSettingScreen(greetingVisible: true));
              } else {
                Navigator.pushNamed(context, AppRoutes.vaultTypeSelection);
              }
            },
          ),
        ),
        _buildAppBarIconButton(
          icon: SvgPicture.asset(
            'assets/svg/gear.svg',
            colorFilter: const ColorFilter.mode(CoconutColors.gray800, BlendMode.srcIn),
          ),
          onPressed: () {
            MyBottomSheet.showBottomSheet_90(context: context, child: const SettingsScreen());
          },
        ),
      ],
    );
  }

  Widget _buildWalletList(BuildContext context) {
    final viewModel = context.read<VaultHomeViewModel>();

    if (viewModel.isWalletsLoaded && viewModel.walletCount == 0) {
      // '지갑을 추가해 보세요!' 위젯
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          child: VaultAdditionGuideCard(
            onPressed: () {
              if (!viewModel.isPinSet) {
                MyBottomSheet.showBottomSheet_90(
                    context: context, child: const PinSettingScreen(greetingVisible: true));
              } else {
                Navigator.pushNamed(context, AppRoutes.vaultTypeSelection);
              }
            },
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        children: [
          // 전체보기 위젯
          _buildViewAll(viewModel.walletCount),

          // if (favoriteWallets.isNotEmpty)
          //   // 즐겨찾기된 지갑 목록
          _buildFavoriteWalletList(
            viewModel.wallets,
            viewModel.wallets,
          ),
        ],
      ),
    );
  }

  Widget _buildViewAll(int walletCount) {
    return Column(
      children: [
        CoconutLayout.spacing_300h,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ShrinkAnimationButton(
            defaultColor: CoconutColors.white,
            pressedColor: CoconutColors.gray100,
            onPressed: () {
              Navigator.pushNamed(context, '/vault-list');
            },
            borderRadius: CoconutStyles.radius_200,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t.vault_home_screen.view_all_my_wallets,
                    style: CoconutTypography.body2_14,
                  ),
                  Row(
                    children: [
                      Text(
                        t.vault_home_screen.wallet_count(count: walletCount),
                        style: CoconutTypography.body3_12,
                      ),
                      CoconutLayout.spacing_200w,
                      SvgPicture.asset(
                        'assets/svg/chevron-right.svg',
                        width: 6,
                        height: 10,
                        colorFilter: const ColorFilter.mode(
                          CoconutColors.gray700,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
        CoconutLayout.spacing_500h,
      ],
    );
  }

  Widget _buildFavoriteWalletList(
    List<VaultListItemBase> walletList,
    List<VaultListItemBase> favoriteWalletList,
  ) {
    debugPrint('favoriteWalletList: $favoriteWalletList');
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: CoconutColors.white,
      ),
      child: Column(
        children: List.generate(favoriteWalletList.length, (index) {
          final wallet = walletList[index];
          final isFavorite = favoriteWalletList.any((w) => w.id == wallet.id);

          if (isFavorite) {
            return VaultRowItem(vault: wallet, isSelectable: false);
          } else {
            return Container();
          }
        }),
      ),
    );
  }

  Widget _buildWalletActionItems(BuildContext context) {
    final walletCount = context.watch<VaultHomeViewModel>().walletCount;
    return SliverToBoxAdapter(
        child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionItemButton(
                  isActive: walletCount > 0,
                  text: t.vault_home_screen.action_items.sign,
                  iconAssetPath: 'assets/svg/signature.svg',
                  iconPadding: const EdgeInsets.only(
                    right: 14,
                    bottom: 17,
                  ),
                ),
              ),
              CoconutLayout.spacing_200w,
              Expanded(
                child: _buildActionItemButton(
                  isActive: walletCount > 0,
                  text: t.vault_home_screen.action_items.view_address,
                  iconAssetPath: 'assets/svg/bc1.svg',
                  iconPadding: const EdgeInsets.only(
                    right: 15,
                    bottom: 17,
                  ),
                ),
              ),
            ],
          ),
          CoconutLayout.spacing_200h,
          Row(
            children: [
              Expanded(
                child: _buildActionItemButton(
                  isActive: walletCount > 0,
                  text: t.vault_home_screen.action_items.export_wallet,
                  iconAssetPath: 'assets/svg/wallet-eyes.svg',
                  iconPadding: const EdgeInsets.only(
                    right: 14,
                    bottom: 16,
                  ),
                ),
              ),
              CoconutLayout.spacing_200w,
              Expanded(
                child: _buildActionItemButton(
                  isActive: walletCount > 0,
                  text: t.vault_home_screen.action_items.import_multisig_wallet,
                  iconAssetPath: 'assets/svg/two-keys.svg',
                  iconPadding: const EdgeInsets.only(
                    right: 15,
                    bottom: 9,
                  ),
                ),
              ),
            ],
          ),
          CoconutLayout.spacing_200h,
          Row(
            children: [
              Expanded(
                child: _buildActionItemButton(
                  isActive: true,
                  text: t.vault_home_screen.action_items.mnemonic_wordlist,
                  iconAssetPath: 'assets/svg/font-book.svg',
                  iconPadding: const EdgeInsets.only(
                    right: 18,
                    bottom: 16,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.mnemonicWordList);
                  },
                ),
              ),
              CoconutLayout.spacing_200w,
              Expanded(
                child: _buildActionItemButton(
                  isActive: walletCount > 0,
                  text: t.vault_home_screen.action_items.import_multisig_wallet,
                  iconAssetPath: 'assets/svg/align-center.svg',
                  iconPadding: const EdgeInsets.only(
                    right: 18,
                    bottom: 19,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildActionItemButton({
    required String text,
    required String iconAssetPath,
    EdgeInsets? iconPadding,
    bool isActive = false,
    VoidCallback? onPressed,
  }) {
    return ShrinkAnimationButton(
      isActive: isActive,
      onPressed: onPressed ?? () {},
      pressedColor: CoconutColors.gray100,
      borderRadius: 12,
      child: SizedBox(
        height: 90,
        child: Stack(
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              child: Center(
                child: Padding(
                  padding: iconPadding ?? EdgeInsets.zero,
                  child: SvgPicture.asset(
                    iconAssetPath,
                    colorFilter: ColorFilter.mode(
                      isActive ? CoconutColors.gray800 : CoconutColors.gray400,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 13,
              child: Text(
                text,
                style: CoconutTypography.body2_14_Bold.setColor(
                  isActive ? CoconutColors.gray700 : CoconutColors.gray400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarIconButton({required Widget icon, required VoidCallback onPressed, Key? key}) {
    return SizedBox(
      key: key,
      height: 40,
      width: 40,
      child: IconButton(
        icon: icon,
        highlightColor: CoconutColors.gray200,
        onPressed: onPressed,
        color: CoconutColors.white,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
