import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
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
  final Function? onChangeEntryFlow;
  final Function? onTeeUnaccessible;
  const VaultHomeScreen({super.key, this.onChangeEntryFlow, this.onTeeUnaccessible});

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
      await _viewModel.loadVaults();

      // loadVaults() 완료 후 vaultList가 null이 아닐 때 실행
      if (Platform.isAndroid) {
        final walletProvider = context.read<WalletProvider>();
        if (walletProvider.isVaultsLoaded && walletProvider.vaultList.isNotEmpty) {
          _isTeeAccessible().then((isTeeAccessible) {
            debugPrint('isTeeAccessible: $isTeeAccessible');
            if (!isTeeAccessible) {
              widget.onTeeUnaccessible?.call();
            }
          });
        }
      }
    });
  }

  Future<bool> _isTeeAccessible() async {
    final firstSingleSignatureWalletId =
        context
            .read<WalletProvider>()
            .vaultList
            .firstWhere((vault) => vault.vaultType == WalletType.singleSignature)
            .id;
    try {
      await context.read<WalletProvider>().getSecret(firstSingleSignatureWalletId);
      return true;
    } catch (e) {
      return false;
    }
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
                      _buildAppBar(context, viewModel, wallets, viewModel.isSigningOnlyMode),
                      _buildWalletActionItems(context),
                      SliverToBoxAdapter(child: Container(color: CoconutColors.gray200, height: 12)),
                      if (wallets.isNotEmpty) ...[_buildViewAll(wallets.length)],
                      _buildWalletList(context),
                      // TODO: const SliverToBoxAdapter(child: TeeSmokeTest()),
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

  SliverAppBar _buildAppBar(
    BuildContext context,
    VaultHomeViewModel viewModel,
    List<VaultListItemBase> wallets,
    bool isSigningOnlyMode,
  ) {
    return CoconutAppBar.buildHomeAppbar(
      context: context,
      leadingSvgAsset: Row(
        children: [
          SvgPicture.asset(
            isSigningOnlyMode ? 'assets/svg/signing-mode.svg' : 'assets/svg/storage-mode.svg',
            height: 20,
          ),
          CoconutLayout.spacing_150w,
          MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: Text(
              isSigningOnlyMode
                  ? t.vault_mode_selection_screen.signing_only_mode
                  : t.vault_mode_selection_screen.secure_storage_mode,
              style: CoconutTypography.heading4_18_Bold.setColor(CoconutColors.gray800),
            ),
          ),
        ],
      ),
      appTitle: '',
      actionButtonList: [
        Opacity(
          opacity: viewModel.isVaultsLoaded ? 1.0 : 0.2,
          child: _buildAppBarIconButton(
            key: GlobalKey(),
            icon: SvgPicture.asset(
              'assets/svg/wallet-plus.svg',
              colorFilter: const ColorFilter.mode(CoconutColors.gray800, BlendMode.srcIn),
            ),
            onPressed: () {
              if (!viewModel.isVaultsLoaded) {
                return;
              }

              _onPressedWalletAddButton(viewModel);
            },
          ),
        ),
        _buildAppBarIconButton(
          icon: SvgPicture.asset(
            'assets/svg/gear.svg',
            colorFilter: const ColorFilter.mode(CoconutColors.gray800, BlendMode.srcIn),
          ),
          onPressed: () {
            MyBottomSheet.showDraggableBottomSheet(
              initialChildSize: 0.9,
              context: context,
              showDragHandle: true,
              childBuilder: (scrollController) => SettingsScreen(scrollController: scrollController),
            );
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
          child: VaultAdditionGuideCard(onPressed: () => _onPressedWalletAddButton(viewModel)),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        children: [CoconutLayout.spacing_300h, _buildFavoriteWalletList(viewModel.vaults, viewModel.favoriteVaultIds)],
      ),
    );
  }

  void _onPressedWalletAddButton(VaultHomeViewModel viewModel) {
    if (!viewModel.isSigningOnlyMode && !viewModel.isPinSet) {
      MyBottomSheet.showBottomSheet_90(context: context, child: const PinSettingScreen(greetingVisible: true));
    } else {
      Navigator.pushNamed(context, AppRoutes.vaultTypeSelection);
    }
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

                bool shouldShowPassphraseVerifyMenu =
                    _viewModel.isSigningOnlyMode ? false : await _viewModel.hasPassphrase(vault.id);
                if (mounted) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.singleSigSetupInfo,
                    arguments: {'id': vault.id, 'shouldShowPassphraseVerifyMenu': shouldShowPassphraseVerifyMenu},
                  );
                }
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
                    onPressed: () async {
                      final walletProvider = context.read<WalletProvider>();
                      final viewModel = context.read<VaultHomeViewModel>();
                      final walletList = walletProvider.vaultList;

                      // 지갑이 1개만 있는 경우, 지갑 선택을 거치지 않고 보기 전용 앱 선택 화면으로 이동
                      if (walletList.length == 1) {
                        final walletId = walletList.first.id;
                        await _handleWalletSelection(context, walletId, viewModel);
                        return;
                      }

                      // 지갑이 여러개인 경우, 지갑 선택 화면으로 이동
                      MyBottomSheet.showDraggableBottomSheet(
                        context: context,
                        minChildSize: 0.5,
                        title: t.select_vault_bottom_sheet.select_wallet,
                        subLabel: t.vault_menu_screen.description.export_xpub,
                        childBuilder:
                            (scrollController) => SelectVaultBottomSheet(
                              vaultList: context.read<WalletProvider>().vaultList,
                              onVaultSelected: (id) async {
                                await _handleWalletSelection(context, id, viewModel);
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
                Expanded(
                  child: Selector<PreferenceProvider, bool>(
                    selector: (_, provider) => provider.isSigningOnlyMode,
                    builder: (context, isSigningOnlyMode, child) {
                      if (!isSigningOnlyMode) {
                        return const SizedBox.shrink();
                      }

                      return _buildActionItemButton(
                        isActive: true,
                        textColor: CoconutColors.white,
                        iconColor: CoconutColors.white,
                        backgroundColor: CoconutColors.gray800,
                        pressedColor: CoconutColors.gray700,
                        text: t.delete_vault,
                        iconAssetPath: 'assets/svg/eraser.svg',
                        iconPadding: const EdgeInsets.only(right: 18, bottom: 16),
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return CoconutPopup(
                                insetPadding: EdgeInsets.symmetric(
                                  horizontal: MediaQuery.of(context).size.width * 0.15,
                                ),
                                title: t.delete_vault,
                                description: t.delete_vault_description,
                                backgroundColor: CoconutColors.white,
                                leftButtonText: t.cancel,
                                rightButtonText: t.confirm,
                                rightButtonColor: CoconutColors.black,
                                onTapLeft: () {
                                  Navigator.pop(dialogContext);
                                },
                                onTapRight: () async {
                                  await context.read<WalletProvider>().deleteAllWallets();
                                  if (!context.mounted) return;
                                  await context.read<PreferenceProvider>().resetVaultOrderAndFavorites();

                                  widget.onChangeEntryFlow?.call();
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleWalletSelection(BuildContext context, int walletId, VaultHomeViewModel viewModel) async {
    final hasPassphrase = viewModel.isSigningOnlyMode ? false : await viewModel.hasPassphrase(walletId);
    if (!context.mounted) return;

    if (hasPassphrase) {
      final passphraseInput = await MyBottomSheet.showBottomSheet_ratio<String?>(
        ratio: 0.5,
        context: context,
        child: PassphraseCheckScreen(id: walletId),
      );

      if (passphraseInput != null && context.mounted) {
        _showSyncOptionBottomSheet(walletId, context);
      }
    } else {
      _showSyncOptionBottomSheet(walletId, context);
    }
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
    Color pressedColor = CoconutColors.gray100,
    Color backgroundColor = CoconutColors.white,
    Color textColor = CoconutColors.gray700,
    Color iconColor = CoconutColors.gray800,
  }) {
    return ShrinkAnimationButton(
      isActive: isActive,
      onPressed: onPressed ?? () {},
      defaultColor: backgroundColor,
      pressedColor: pressedColor,
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
                    colorFilter: ColorFilter.mode(isActive ? iconColor : CoconutColors.gray400, BlendMode.srcIn),
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
                  style: CoconutTypography.body2_14_Bold.setColor(isActive ? textColor : CoconutColors.gray400),
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
