import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/app_routes_params.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/view_model/home/vault_home_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/multisig_bsms_scanner_screen.dart';
import 'package:coconut_vault/screens/home/select_sync_option_bottom_sheet.dart';
import 'package:coconut_vault/screens/home/select_vault_bottom_sheet.dart';
import 'package:coconut_vault/screens/settings/pin_setting_screen.dart';
import 'package:coconut_vault/screens/vault_menu/info/passphrase_check_screen.dart';
import 'package:coconut_vault/utils/logger.dart';
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
import 'package:collection/collection.dart';

class VaultHomeScreen extends StatefulWidget {
  const VaultHomeScreen({super.key});

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> with TickerProviderStateMixin {
  late VaultHomeViewModel _viewModel;

  DateTime? _lastPressedAt;
  bool _handledDidChangeDependencies = false;

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _viewModel = VaultHomeViewModel(
      Provider.of<AuthProvider>(context, listen: false),
      Provider.of<WalletProvider>(context, listen: false),
      Provider.of<PreferenceProvider>(context, listen: false),
      Provider.of<VisibilityProvider>(context, listen: false).walletCount,
    );

    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 지갑 추가, 지갑 삭제, 서명완료 후 불필요하게 loadVaultList() 호출되는 것을 막음
      if (_viewModel.isVaultsLoaded) {
        return;
      }
      _viewModel.loadVaults();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledDidChangeDependencies) return;
    _handledDidChangeDependencies = true;

    final args = ModalRoute.of(context)?.settings.arguments as VaultHomeNavArgs?;
    if (args?.addedWalletId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bool isAddedWalletInFavorite =
            _viewModel.favoriteVaultIds.firstWhereOrNull((id) => id == args!.addedWalletId) != null;
        if (isAddedWalletInFavorite) return;

        CoconutToast.showToast(
          isVisibleIcon: true,
          context: context,
          text: t.vault_home_screen.toast.wallet_added_but_not_favorite,
        );
      });
    }
  }

  bool isEnablePlusButton(bool isWalletsLoaded) {
    return NetworkType.currentNetworkType.isTestnet || (isWalletsLoaded);
  }

  VaultHomeViewModel _createViewModel() {
    _viewModel = VaultHomeViewModel(
      Provider.of<AuthProvider>(context, listen: false),
      Provider.of<WalletProvider>(context, listen: false),
      Provider.of<PreferenceProvider>(context, listen: false),
      Provider.of<VisibilityProvider>(context, listen: false).walletCount,
    );
    return _viewModel;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (Platform.isAndroid) {
          final now = DateTime.now();
          if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 3)) {
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
      ChangeNotifierProxyProvider4<
        AuthProvider,
        ConnectivityProvider,
        VisibilityProvider,
        PreferenceProvider,
        VaultHomeViewModel
      >(
        create: (_) => _viewModel,
        update: (_, authProvider, connectivityProvider, visibilityProvider, preferenceProvider, viewModel) {
          viewModel ??= _createViewModel();
          return viewModel;
        },
        child: Consumer2<VaultHomeViewModel, VisibilityProvider>(
          builder: (context, viewModel, visibilityProvider, child) {
            final wallets = viewModel.vaults;
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
                      _buildWalletActionItems(context),
                      SliverToBoxAdapter(child: Container(color: CoconutColors.gray200, height: 12)),
                      if (wallets.isNotEmpty) ...[_buildViewAll(wallets.length)],
                      _buildWalletList(context),
                      SliverToBoxAdapter(child: Container(height: 100)),
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

  SliverAppBar _buildAppBar(BuildContext context, VaultHomeViewModel viewModel, List<VaultListItemBase> wallets) {
    return CoconutAppBar.buildHomeAppbar(
      context: context,
      leadingSvgAsset: const SizedBox.shrink(key: ValueKey('empty')),
      appTitle: '',
      actionButtonList: [
        Opacity(
          opacity: isEnablePlusButton(viewModel.isVaultsLoaded) ? 1.0 : 0.2,
          child: _buildAppBarIconButton(
            key: GlobalKey(),
            icon: SvgPicture.asset(
              'assets/svg/wallet-plus.svg',
              colorFilter: const ColorFilter.mode(CoconutColors.gray800, BlendMode.srcIn),
            ),
            onPressed: () {
              if (!isEnablePlusButton(viewModel.isVaultsLoaded)) {
                return;
              }

              if (viewModel.vaultCount == 0 && !viewModel.isPinSet) {
                MyBottomSheet.showBottomSheet_90(
                  context: context,
                  child: const PinSettingScreen(greetingVisible: true),
                );
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

  Widget _buildViewAll(int walletCount) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          CoconutLayout.spacing_500h,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ShrinkAnimationButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.vaultList);
              },
              borderRadius: CoconutStyles.radius_200,
              pressedColor: CoconutColors.gray100,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(t.vault_home_screen.view_all_wallets, style: CoconutTypography.body2_14),
                      ),
                    ),
                    Row(
                      children: [
                        CoconutLayout.spacing_200w,
                        Text(t.vault_home_screen.wallet_count(count: walletCount), style: CoconutTypography.body3_12),
                        CoconutLayout.spacing_200w,
                        SvgPicture.asset('assets/svg/chevron-right.svg', width: 6, height: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletList(BuildContext context) {
    final viewModel = context.read<VaultHomeViewModel>();

    if (viewModel.isVaultsLoaded && viewModel.vaultCount == 0) {
      // '지갑을 추가해 보세요!' 위젯
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          child: VaultAdditionGuideCard(
            onPressed: () {
              if (!viewModel.isPinSet) {
                MyBottomSheet.showBottomSheet_90(
                  context: context,
                  child: const PinSettingScreen(greetingVisible: true),
                );
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
        children: [CoconutLayout.spacing_300h, _buildFavoriteWalletList(viewModel.vaults, viewModel.favoriteVaultIds)],
      ),
    );
  }

  Widget _buildFavoriteWalletList(List<VaultListItemBase> walletList, List<int> favoriteWalletIds) {
    // favoriteWalletIds를 orederList 순서에 맞게 정렬
    final sortedFavoriteWalletIds = List<int>.from(favoriteWalletIds)..sort((a, b) {
      final aIndex = walletList.indexWhere((vault) => vault.id == a);
      final bIndex = walletList.indexWhere((vault) => vault.id == b);
      if (aIndex == -1 && bIndex == -1) return 0;
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: CoconutColors.white),
      child: Column(
        children: List.generate(sortedFavoriteWalletIds.length, (index) {
          final vaultId = sortedFavoriteWalletIds[index];
          final vault = walletList.firstWhereOrNull((w) => w.id == vaultId);
          if (vault != null) {
            return VaultRowItem(
              vault: vault,
              isSelectable: false,
              onSelected: () async {
                if (vault.vaultType == WalletType.multiSignature) {
                  Navigator.pushNamed(context, AppRoutes.multisigSetupInfo, arguments: {'id': vault.id});
                  return;
                }

                bool hasPassphrase = await _viewModel.hasPassphrase(vault.id);
                Navigator.pushNamed(
                  context,
                  AppRoutes.singleSigSetupInfo,
                  arguments: {'id': vault.id, 'hasPassphrase': hasPassphrase},
                );
              },
            );
          } else {
            // vault가 null인 경우(아직 로드안됨) Skeleton UI 표시
            return VaultRowItem.buildSkeleton();
          }
        }),
      ),
    );
  }

  Widget _buildWalletActionItems(BuildContext context) {
    final walletCount = context.watch<VaultHomeViewModel>().vaultCount;
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildActionItemButton(
                    // 서명하기 버튼
                    isActive: walletCount > 0,
                    text: t.vault_home_screen.action_items.sign,
                    iconAssetPath: 'assets/svg/signature.svg',
                    iconPadding: const EdgeInsets.only(right: 14, bottom: 17),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.psbtScanner);
                    },
                  ),
                ),
                CoconutLayout.spacing_200w,
                Expanded(
                  child: _buildActionItemButton(
                    isActive: walletCount > 0,
                    text: t.vault_home_screen.action_items.view_address,
                    iconAssetPath: 'assets/svg/bc1.svg',
                    iconPadding: const EdgeInsets.only(right: 15, bottom: 17),
                    onPressed: () {
                      // 지갑 선택 후 주소 보기 화면으로 이동
                      MyBottomSheet.showDraggableBottomSheet(
                        context: context,
                        minChildSize: 0.5,
                        title: t.select_vault_bottom_sheet.select_wallet,
                        childBuilder:
                            (scrollController) => SelectVaultBottomSheet(
                              vaultList: context.read<WalletProvider>().vaultList,
                              onVaultSelected: (id) async {
                                Navigator.pushNamed(context, AppRoutes.addressList, arguments: {'id': id});
                              },
                              scrollController: scrollController,
                            ),
                      );
                    },
                  ),
                ),
              ],
            ),
            CoconutLayout.spacing_200h,
            Row(
              children: [
                Expanded(
                  child: _buildActionItemButton(
                    // 지갑 내보내기 버튼
                    isActive: walletCount > 0,
                    text: t.vault_home_screen.action_items.export_wallet,
                    iconAssetPath: 'assets/svg/wallet-eyes.svg',
                    iconPadding: const EdgeInsets.only(right: 14, bottom: 16),
                    onPressed: () {
                      MyBottomSheet.showDraggableBottomSheet(
                        context: context,
                        minChildSize: 0.5,
                        title: t.select_vault_bottom_sheet.select_wallet,
                        subLabel: t.vault_menu_screen.description.export_xpub,
                        childBuilder:
                            (scrollController) => SelectVaultBottomSheet(
                              vaultList: context.read<WalletProvider>().vaultList,
                              onVaultSelected: (id) async {
                                bool hasPassphrase = await context.read<VaultHomeViewModel>().hasPassphrase(id);

                                if (!context.mounted) return;

                                if (hasPassphrase) {
                                  final result = await MyBottomSheet.showBottomSheet_ratio<String?>(
                                    ratio: 0.5,
                                    context: context,
                                    child: PassphraseCheckScreen(id: id),
                                  );
                                  if (result != null && context.mounted) {
                                    _showSyncOptionBottomSheet(id, context);
                                  }
                                  return;
                                }

                                _showSyncOptionBottomSheet(id, context);
                              },
                              scrollController: scrollController,
                            ),
                      );
                    },
                  ),
                ),
                CoconutLayout.spacing_200w,
                Expanded(
                  child: _buildActionItemButton(
                    // 다중서명 지갑 가져오기 버튼
                    isActive:
                        walletCount > 0 &&
                        context.watch<WalletProvider>().vaultList.any(
                          (vault) => vault.vaultType == WalletType.singleSignature,
                        ),
                    text: t.vault_home_screen.action_items.import_multisig_wallet,
                    iconAssetPath: 'assets/svg/two-keys.svg',
                    iconPadding: const EdgeInsets.only(right: 15, bottom: 9),
                    onPressed: () {
                      MyBottomSheet.showDraggableBottomSheet(
                        context: context,
                        title: t.select_vault_bottom_sheet.select_wallet,
                        subLabel: t.vault_menu_screen.description.import_bsms,
                        childBuilder:
                            (scrollController) => SelectVaultBottomSheet(
                              vaultList:
                                  context
                                      .read<WalletProvider>()
                                      .vaultList
                                      .where((vault) => vault.vaultType == WalletType.singleSignature)
                                      .toList(),
                              subLabel: t.vault_menu_screen.description.import_bsms,
                              onVaultSelected: (id) async {
                                if (mounted) {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.signerBsmsScanner,
                                    arguments: {'id': id, 'screenType': MultisigBsmsImportType.copy},
                                  );
                                }
                              },
                              scrollController: scrollController,
                            ),
                      );
                    },
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
                    iconPadding: const EdgeInsets.only(right: 18, bottom: 16),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.mnemonicWordList);
                    },
                  ),
                ),
                CoconutLayout.spacing_200w,
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncOptionBottomSheet(int walletId, BuildContext context) {
    MyBottomSheet.showBottomSheet_ratio(
      context: context,
      ratio: 0.5,
      child: SelectSyncOptionBottomSheet(
        onSyncOptionSelected: (format) {
          if (!context.mounted) return;
          Navigator.popUntil(context, (route) => route.isFirst);
          Navigator.pushNamed(context, AppRoutes.syncToWallet, arguments: {'id': walletId, 'syncOption': format});
        },
      ),
    );
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
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: Text(
                  text,
                  style: CoconutTypography.body2_14_Bold.setColor(
                    isActive ? CoconutColors.gray700 : CoconutColors.gray400,
                  ),
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
