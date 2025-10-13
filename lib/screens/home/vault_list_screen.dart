import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/view_model/home/vault_list_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/screens/home/vault_item_setting_bottom_sheet.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/coconut_loading_overlay.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:coconut_vault/widgets/vault_row_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

class VaultListScreen extends StatefulWidget {
  const VaultListScreen({super.key});

  @override
  State<VaultListScreen> createState() => _VaultListScreenState();
}

class _VaultListScreenState extends State<VaultListScreen> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late VaultListViewModel _viewModel;
  late VisibilityProvider _visibilityProvider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProxyProvider3<WalletProvider, ConnectivityProvider, PreferenceProvider, VaultListViewModel>(
      create: (_) => _createViewModel(),
      update: (
        BuildContext context,
        WalletProvider walletProvider,
        ConnectivityProvider connectivityProvider,
        PreferenceProvider preferenceProvider,
        VaultListViewModel? previous,
      ) {
        previous ??= _createViewModel();
        previous.onPreferenceProviderUpdated();
        return previous;
      },
      child: Selector<VaultListViewModel, Tuple5<List<VaultListItemBase>, List<int>, List<int>, bool, List<int>>>(
        selector:
            (_, vm) => Tuple5(vm.vaults, vm.tempFavoriteVaultIds, vm.tempVaultOrder, vm.isEditMode, vm.vaultOrder),
        builder: (context, data, child) {
          final viewModel = Provider.of<VaultListViewModel>(context, listen: false);

          final vaultListItem = data.item1;
          final isEditMode = data.item4;
          final vaultOrder = data.item5;
          // Pin check 로직(편집모드에서 삭제 후 완료 버튼 클릭시 동작)
          if (viewModel.pinCheckNotifier.value == true) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              viewModel.pinCheckNotifier.value = false;
              await MyBottomSheet.showBottomSheet_90(
                context: context,
                child: CustomLoadingOverlay(
                  child: PinCheckScreen(
                    pinCheckContext: PinCheckContextEnum.sensitiveAction,
                    onSuccess: () async {
                      viewModel.handleAuthCompletion();
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            });
          }

          // 편집모드에서 모든 볼트를 다 삭제했을 때 홈화면으로 자동 전환
          if (vaultListItem.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.popUntil(context, (route) {
                return route.settings.name == '/';
              });
            });
          }

          return Stack(
            children: [
              PopScope(
                canPop: !isEditMode,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) {
                    Navigator.pop(context);
                  }
                },
                child: Scaffold(
                  backgroundColor: CoconutColors.white,
                  extendBodyBehindAppBar: true,
                  appBar: _buildAppBar(context),
                  body: SafeArea(
                    top: true,
                    child:
                        isEditMode
                            // 편집 모드
                            ? Stack(
                              children: [
                                _buildEditableVaultList(),
                                FixedBottomButton(
                                  onButtonClicked: () async {
                                    await viewModel.applyTempDatasToVaults();
                                  },
                                  isActive: viewModel.hasFavoriteChanged || viewModel.hasVaultOrderChanged,
                                  backgroundColor: CoconutColors.black,
                                  text: t.complete,
                                ),
                              ],
                            )
                            // 일반 모드
                            : Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: CustomScrollView(
                                    controller: _scrollController,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    semanticChildCount: vaultListItem.length,
                                    slivers: <Widget>[
                                      // 볼트 목록
                                      _buildVaultList(vaultListItem, vaultOrder),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: viewModel.loadingNotifier,
                builder: (context, isLoading, _) {
                  return isLoading ? const CoconutLoadingOverlay() : Container();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _visibilityProvider = Provider.of<VisibilityProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  VaultListViewModel _createViewModel() {
    _viewModel = VaultListViewModel(
      Provider.of<AuthProvider>(context, listen: false),
      Provider.of<WalletProvider>(context, listen: false),
      Provider.of<PreferenceProvider>(context, listen: false),
      Provider.of<WalletProvider>(context, listen: false).vaultList.length,
    );
    return _viewModel;
  }

  Widget _buildEditModeHeader() {
    SvgPicture starIcon = SvgPicture.asset(
      'assets/svg/star-small.svg',
      width: 16,
      height: 16,
      colorFilter: const ColorFilter.mode(CoconutColors.gray800, BlendMode.srcIn),
    );
    SvgPicture hamburgerIcon = SvgPicture.asset(
      'assets/svg/hamburger.svg',
      width: 16,
      height: 16,
      colorFilter: const ColorFilter.mode(CoconutColors.gray800, BlendMode.srcIn),
    );
    debugPrint('_visibilityProvider.isEnglish: ${_visibilityProvider.isEnglish}');
    return Container(
      width: MediaQuery.sizeOf(context).width,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: CoconutColors.gray150,
        borderRadius: BorderRadius.circular(CoconutStyles.radius_200),
      ),
      child: Column(
        children: [
          _buildEditModeHeaderLine([
            if (_visibilityProvider.isEnglish) ...[
              TextSpan(text: '${t.select} '),
              WidgetSpan(alignment: PlaceholderAlignment.top, child: starIcon),
              const TextSpan(text: ' '),
            ],
            if (_visibilityProvider.isKorean) WidgetSpan(alignment: PlaceholderAlignment.top, child: starIcon),
            TextSpan(text: t.vault_list_screen.edit.star_description),
          ]),
          CoconutLayout.spacing_100h,
          _buildEditModeHeaderLine([
            if (_visibilityProvider.isEnglish) ...[
              TextSpan(text: '${t.tap} '),
              WidgetSpan(alignment: PlaceholderAlignment.top, child: hamburgerIcon),
              const TextSpan(text: ' '),
            ],
            if (_visibilityProvider.isKorean) WidgetSpan(alignment: PlaceholderAlignment.top, child: hamburgerIcon),
            TextSpan(text: t.vault_list_screen.edit.order_description),
          ]),
          CoconutLayout.spacing_100h,
          _buildEditModeHeaderLine([TextSpan(text: t.vault_list_screen.edit.delete_description)]),
        ],
      ),
    );
  }

  Widget _buildEditModeHeaderLine(List<InlineSpan> inlineSpan) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.5, horizontal: 6),
          height: 3,
          width: 3,
          decoration: const BoxDecoration(color: CoconutColors.gray800, shape: BoxShape.circle),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(style: CoconutTypography.body2_14.setColor(CoconutColors.gray800), children: inlineSpan),
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
        ),
      ],
    );
  }

  Widget _buildVaultList(List<VaultListItemBase> vaultList, List<int> vaultOrder) {
    vaultList.sort((a, b) => vaultOrder.indexOf(a.id).compareTo(vaultOrder.indexOf(b.id)));
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index < vaultList.length) {
          return _buildVaultItem(vaultList[index], index == vaultOrder.length - 1, index == 0);
        } else if (index < vaultOrder.length) {
          // vaultOrder에 있지만 vaultList에 없는 경우 skeleton UI 표시
          return VaultRowItem.buildSkeleton();
        }
        return null;
      }, childCount: vaultOrder.length),
    );
  }

  Widget _buildEditableVaultList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      primary: false,
      physics: const AlwaysScrollableScrollPhysics(),
      header: _buildEditModeHeader(),
      footer: const Padding(padding: EdgeInsets.all(60.0)),
      proxyDecorator: (child, index, animation) {
        // 드래그 중인 항목의 외관 변경
        return Container(
          decoration: BoxDecoration(
            color: CoconutColors.white,
            borderRadius: BorderRadius.circular(CoconutStyles.radius_200),
            boxShadow: const [BoxShadow(color: CoconutColors.gray300, blurRadius: 8, spreadRadius: 0.5)],
          ),
          child: child,
        );
      },
      itemCount: _viewModel.tempVaultOrder.length,
      onReorder: (oldIndex, newIndex) {
        _viewModel.reorderTempVaultOrder(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        VaultListItemBase vault = _viewModel.vaults.firstWhere((w) => w.id == _viewModel.tempVaultOrder[index]);
        // 삭제 가능한 조건
        // MultisigVaultListItem 인 경우 삭제 가능
        // SingleSigVaultListItem 인 경우 연결된 MultisigVaultListItem 이 없는 경우 삭제 가능
        // 연결된 MultisigVaultListItem 이 있는 경우 연결된 MultisigVaultListItem 이 먼저 Dismiss된 경우 삭제 가능
        var canDismiss = false;
        if (vault is MultisigVaultListItem) {
          canDismiss = true;
        } else {
          if ((vault as SingleSigVaultListItem).linkedMultisigInfo?.entries.isEmpty == true ||
              vault.linkedMultisigInfo?.entries == null ||
              (vault.linkedMultisigInfo?.entries.isNotEmpty == true &&
                  vault.linkedMultisigInfo!.entries.every((entry) => !_viewModel.tempVaultOrder.contains(entry.key)))) {
            canDismiss = true;
          }
        }
        return Dismissible(
          key: ValueKey(vault.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: CoconutColors.hotPink,
            child: SvgPicture.asset(
              'assets/svg/trash.svg',
              width: 16,
              colorFilter: const ColorFilter.mode(CoconutColors.white, BlendMode.srcIn),
            ),
          ),
          confirmDismiss: (direction) async {
            if (!canDismiss) {
              CoconutToast.showToast(context: context, text: t.toast.name_multisig_in_use, isVisibleIcon: true);
              return false; // 되돌리기
            }
            return true;
          },
          onDismissed: (direction) {
            if (!canDismiss) {
              return;
            }
            _viewModel.removeTempWalletOrderByWalletId(vault.id);
          },
          child: KeyedSubtree(
            key: ValueKey(_viewModel.tempVaultOrder[index]),
            child: _buildVaultItem(
              vault,
              false,
              index == 0,
              isEditMode: true,
              isFavorite: _viewModel.tempFavoriteVaultIds.contains(vault.id),
              index: index,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVaultItem(
    VaultListItemBase vault,
    bool isLastItem,
    bool isFirstItem, {
    bool isEditMode = false,
    bool isFavorite = false,
    int? index,
  }) {
    return Column(
      children: [
        if (isEditMode) CoconutLayout.spacing_100h,
        _getVaultRowItem(
          Key(vault.id.toString()),
          vault,
          isLastItem,
          isFirstItem,
          isEditMode,
          isFavorite,
          index: index,
        ),
        isEditMode
            ? CoconutLayout.spacing_100h
            : isLastItem
            ? CoconutLayout.spacing_1000h
            : CoconutLayout.spacing_200h,
      ],
    );
  }

  Widget _getVaultRowItem(
    Key key,
    VaultListItemBase vault,
    bool isLastItem,
    bool isFirstItem,
    bool isEditMode,
    bool isFavorite, {
    int? index,
  }) {
    final VaultListItemBase(id: id, name: name, iconIndex: iconIndex, colorIndex: colorIndex) = vault;

    return VaultRowItem(
      key: key,
      vault: vault,
      isLastItem: isLastItem,
      isPrimaryWallet: isFirstItem,
      isEditMode: isEditMode,
      isFavorite: isFavorite,
      isStarVisible: isFavorite || _viewModel.tempFavoriteVaultIds.length < kMaxStarLength, // 즐겨찾기 제한 만큼 설정
      onTapStar: (pair) {
        // pair: (bool isFavorite, int walletId)

        // 즐겨찾기 된 지갑이 1개인 경우 즐겨찾기 해제 불가
        if (isFavorite && _viewModel.tempFavoriteVaultIds.length == 1) {
          vibrateExtraLightDouble();
          CoconutToast.showToast(context: context, text: t.toast.home_vault_min_one, isVisibleIcon: true);
          return;
        }
        vibrateExtraLight();
        _viewModel.toggleTempFavorite(pair.$2);
      },
      index: index,
      onLongPressed: () {
        vibrateExtraLight();
        MyBottomSheet.showBottomSheet_ratio(ratio: 0.3, context: context, child: VaultItemSettingBottomSheet(id: id));
      },
      entryPoint: AppRoutes.vaultList,
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    bool isEditMode = _viewModel.isEditMode;
    bool hasFavoriteChanged = _viewModel.hasFavoriteChanged;
    bool hasWalletOrderChanged = _viewModel.hasVaultOrderChanged;
    return CoconutAppBar.build(
      title: isEditMode ? t.vault_list_screen.edit.wallet_list : '',
      context: context,
      onBackPressed: () {
        if (isEditMode) {
          if (hasFavoriteChanged || hasWalletOrderChanged) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return CoconutPopup(
                  title: t.vault_list_screen.edit.finish,
                  description: t.vault_list_screen.edit.unsaved_changes_confirm_exit,
                  leftButtonText: t.no,
                  rightButtonText: t.yes,
                  onTapRight: () {
                    _viewModel.setEditMode(false);
                    Navigator.pop(context);
                  },
                  onTapLeft: () {
                    Navigator.pop(context);
                  },
                );
              },
            );
          } else {
            _viewModel.setEditMode(false);
          }
        } else {
          Navigator.pop(context);
        }
      },
      actionButtonList: [
        if (!isEditMode) ...[
          CoconutUnderlinedButton(
            isActive: _viewModel.isVaultsLoaded,
            text: t.edit,
            textStyle: CoconutTypography.body2_14,
            onTap: () {
              _viewModel.setEditMode(true);
            },
          ),
          CoconutLayout.spacing_200w,
        ],
      ],
    );
  }
}
