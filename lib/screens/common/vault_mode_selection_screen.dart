import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/connectivity_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';

class VaultModeSelectionScreen extends StatefulWidget {
  final Function()? onComplete; // onComplete이 null일 경우 [설정 - 모드 변경]으로 진입
  const VaultModeSelectionScreen({
    super.key,
    this.onComplete,
  });

  @override
  State<VaultModeSelectionScreen> createState() => _VaultModeSelectionScreenState();
}

class _VaultModeSelectionScreenState extends State<VaultModeSelectionScreen> {
  VaultMode? selectedVaultMode;

  @override
  void initState() {
    super.initState();
    selectedVaultMode = context.read<PreferenceProvider>().getVaultMode();
  }

  bool _getActiveState(VaultMode vaultMode) {
    if (widget.onComplete != null) {
      return true;
    }
    return context.read<PreferenceProvider>().getVaultMode() != vaultMode;
  }

  Color _borderColor(VaultMode mode) {
    final bool inactive = widget.onComplete == null && !_getActiveState(mode);
    if (inactive) return CoconutColors.gray300;
    return selectedVaultMode == mode ? CoconutColors.black : CoconutColors.gray400;
  }

  Widget _buildModeCard({
    required VaultMode mode,
    required String title,
    required String description,
  }) {
    return ShrinkAnimationButton(
      isActive: _getActiveState(mode),
      disabledColor: CoconutColors.gray200,
      border: Border.all(
        color: _borderColor(mode),
        width: 1.5,
      ),
      borderRadius: 12,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: CoconutTypography.heading4_18_Bold),
                if (widget.onComplete == null &&
                    mode == context.read<PreferenceProvider>().getVaultMode())
                  Text(t.vault_mode_selection_screen.current_using,
                      style: CoconutTypography.body3_12_Bold.setColor(CoconutColors.gray400)),
              ],
            ),
            CoconutLayout.spacing_200h,
            Text(description, style: CoconutTypography.body2_14),
          ],
        ),
      ),
      onPressed: () {
        setState(() {
          selectedVaultMode = mode;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        context: context,
        title: t.vault_mode_selection_screen.select_mode,
        onBackPressed: () {
          Navigator.pop(context);
        },
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  _buildModeCard(
                    mode: VaultMode.secureStorage,
                    title: t.vault_mode_selection_screen.secure_storage_mode,
                    description: t.vault_mode_selection_screen.secure_storage_mode_description,
                  ),
                  CoconutLayout.spacing_300h,
                  _buildModeCard(
                    mode: VaultMode.signingOnly,
                    title: t.vault_mode_selection_screen.signing_only_mode,
                    description: t.vault_mode_selection_screen.signing_only_mode_description,
                  ),
                ],
              ),
            ),
            FixedBottomButton(
              isActive: widget.onComplete != null
                  ? selectedVaultMode != null
                  : selectedVaultMode != context.read<PreferenceProvider>().getVaultMode(),
              onButtonClicked: () async {
                if (widget.onComplete != null) {
                  // 앱 최초 실행 시 widget.onComplete != null
                  context.read<ConnectivityProvider>().setHasSeenGuideTrue();
                  context.read<VisibilityProvider>().setHasSeenGuide().then((_) {
                    if (context.mounted) {
                      context.read<PreferenceProvider>().setVaultMode(selectedVaultMode!);
                      widget.onComplete!();
                    }
                  });
                }

                // 설정 - 모드 변경으로 진입(widget.onComplete가 null일 경우)
                // 앱 비밀번호 확인 먼저 수행
                await _authenticateWithBiometricOrPin(context, PinCheckContextEnum.sensitiveAction,
                    () {
                  // 비밀번호 일치 시 모드 변경 로직 수행
                  _changeVaultMode();
                });
              },
              text: widget.onComplete != null
                  ? t.vault_mode_selection_screen.start
                  : t.vault_mode_selection_screen.change,
            ),
          ],
        ),
      ),
    );
  }

  void _changeVaultMode() async {
    setState(() {
      context.read<PreferenceProvider>().setVaultMode(selectedVaultMode!);
    });

    if (context.read<PreferenceProvider>().getVaultMode() == VaultMode.signingOnly) {
      // 안전 저장 모드에서 서명 전용 모드로 바뀐 경우
      // SecureStorage에서 시드 관련 데이터 모두 삭제
      // WalletProvider에 시드 관련 데이터는 남겨둠

      final secureStorageRepository = SecureStorageRepository();
      final sharedPrefsRepository = SharedPrefsRepository();
      await secureStorageRepository.deleteAll();
      await sharedPrefsRepository.deleteSharedPrefsWithKey(SharedPrefsKeys.kVaultListField);
      await sharedPrefsRepository.deleteSharedPrefsWithKey(SharedPrefsKeys.vaultListLength);
    }

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return CoconutPopup(
            insetPadding:
                EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
            title: t.vault_mode_selection_screen.mode_change_complete,
            description: context.read<PreferenceProvider>().isSigningOnlyMode
                ? t.vault_mode_selection_screen.mode_changed_description_signing_only
                : t.vault_mode_selection_screen.mode_changed_description_secrue_storage,
            backgroundColor: CoconutColors.white,
            rightButtonText: t.confirm,
            rightButtonColor: CoconutColors.black,
            onTapRight: () {
              Navigator.pop(context);
            },
          );
        });
  }

  Future<void> _authenticateWithBiometricOrPin(
      BuildContext context, PinCheckContextEnum pinCheckContext, VoidCallback onSuccess) async {
    final authProvider = context.read<AuthProvider>();

    if (await authProvider.isBiometricsAuthValid() && context.mounted) {
      onSuccess();
      return;
    }

    await MyBottomSheet.showBottomSheet_90(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: pinCheckContext,
          onSuccess: () async {
            Navigator.pop(context);
            onSuccess();
          },
        ),
      ),
    );
  }
}
