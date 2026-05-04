import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/indicator/message_activity_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class VaultTypeSelectionScreen extends StatefulWidget {
  const VaultTypeSelectionScreen({super.key});

  @override
  State<VaultTypeSelectionScreen> createState() => _VaultTypeSelectionScreenState();
}

class _VaultTypeSelectionScreenState extends State<VaultTypeSelectionScreen> {
  String? nextPath;
  bool _showLoading = false;
  List<String> routesOptions = [
    AppRoutes.vaultCreationOptions,
    AppRoutes.multisigCreationOptions,
    AppRoutes.taprootCreationOptions,
  ];
  late final WalletProvider _walletProvider;

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _walletProvider.isVaultListLoadingNotifier.addListener(_loadingListener);
  }

  @override
  void dispose() {
    _walletProvider.isVaultListLoadingNotifier.removeListener(_loadingListener);
    super.dispose();
  }

  void _loadingListener() {
    if (!mounted) return;

    if (!_walletProvider.isVaultListLoadingNotifier.value) {
      if (_showLoading && nextPath != null) {
        setState(() {
          _showLoading = false;
        });

        Navigator.pushNamed(context, nextPath!);
      }
    }
  }

  void onTapSinglesigWallet() {
    Navigator.pushNamed(context, routesOptions[0]);
  }

  void onTapMultisigWallet() {
    Navigator.pushNamed(context, routesOptions[1]);
  }

  void onTapTaprootWallet() {
    Navigator.pushNamed(context, routesOptions[2]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: CoconutColors.white,
          appBar: CoconutAppBar.build(title: t.select_vault_type_screen.title, context: context),
          body: SafeArea(
            minimum: const EdgeInsets.only(top: 10, right: 16, left: 16),
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildOption(
                      t.single_sig_wallet,
                      t.select_vault_type_screen.single_sig,
                      onTapSinglesigWallet,
                      true,
                    ),
                    CoconutLayout.spacing_300h,
                    _buildOption(t.multisig_wallet, t.select_vault_type_screen.multisig, onTapMultisigWallet, true),
                    CoconutLayout.spacing_300h,
                    _buildOption(
                      t.taproot.parent_creation_screen.taproot_inheritance_wallet,
                      t.select_vault_type_screen.taproot,
                      onTapTaprootWallet,
                      true,
                    ),
                    CoconutLayout.spacing_300h,
                    _buildOption('Date Picker', '바텀시트로 DatePicker를 띄웁니다. (테스트용)', () {
                      DateTime? selectedDate;
                      var selectedTime = TimeOfDay.now();
                      MyBottomSheet.showBottomSheet(
                        title: '날짜 선택',
                        context: context,
                        isCloseButton: true,
                        child: StatefulBuilder(
                          builder: (context, setBottomSheetState) {
                            const bottomButtonAreaHeight =
                                FixedBottomButton.fixedBottomButtonDefaultHeight +
                                FixedBottomButton.fixedBottomButtonDefaultBottomPadding +
                                40;
                            final bottomSheetBodyHeight = (MediaQuery.sizeOf(context).height -
                                    MediaQuery.viewInsetsOf(context).bottom -
                                    300)
                                .clamp(360.0, 600.0);
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                              child: SafeArea(
                                child: SizedBox(
                                  height: bottomSheetBodyHeight,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(horizontal: 28),
                                                child: CoconutDatePicker(
                                                  onDateChanged: (d) {
                                                    Logger.log(d.toIso8601String());
                                                    selectedDate = d;
                                                  },
                                                  firstDate: DateTime(2009, 01, 03),
                                                  lastDate: DateTime(2100, 12, 31),
                                                  showTimeSelector: true,
                                                  selectedTime: selectedTime,
                                                  onTimeChanged: (time) {
                                                    setBottomSheetState(() {
                                                      selectedTime = time;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: bottomButtonAreaHeight,
                                        child: FixedBottomButton(
                                          isVisibleAboveKeyboard: false,
                                          bottomPadding: 0,
                                          onButtonClicked: () {
                                            Logger.log(
                                              'Selected date: ${selectedDate?.toIso8601String() ?? 'None'}, time: ${selectedTime.format(context)}',
                                            );
                                          },
                                          text: '다음',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }, true),
                  ],
                ),
                Visibility(
                  visible: _showLoading,
                  child: Container(
                    decoration: BoxDecoration(color: CoconutColors.black.withValues(alpha: 0.3)),
                    child: Center(child: MessageActivityIndicator(message: t.select_vault_type_screen.loading_keys)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOption(String title, String description, VoidCallback onPressed, bool isSelectable) {
    print('isSelectable: $isSelectable');
    return ShrinkAnimationButton(
      defaultColor: CoconutColors.gray150,
      pressedColor: CoconutColors.gray500.withValues(alpha: 0.1),
      onPressed: isSelectable ? onPressed : () {},
      isActive: isSelectable,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: CoconutTypography.body1_16_Bold.copyWith(
                        color: isSelectable ? CoconutColors.black : CoconutColors.gray400,
                        letterSpacing: 0.2,
                      ),
                    ),
                    CoconutLayout.spacing_100h,
                    Flexible(
                      child: Text(
                        overflow: TextOverflow.visible,
                        maxLines: 2,
                        description,
                        style: CoconutTypography.body2_14.copyWith(
                          color: isSelectable ? CoconutColors.gray700 : CoconutColors.gray400,
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(width: 10),
            SvgPicture.asset(
              'assets/svg/chevron-right.svg',
              colorFilter: ColorFilter.mode(
                isSelectable ? CoconutColors.black : CoconutColors.gray400,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
