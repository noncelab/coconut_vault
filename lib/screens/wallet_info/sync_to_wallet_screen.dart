import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/wallet_info/sync_to_wallet_view_model.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/home/select_sync_option_bottom_sheet.dart';
import 'package:coconut_vault/screens/wallet_info/account_number_settings_bottom_sheet.dart';
import 'package:coconut_vault/screens/wallet_info/passphrase_check_bottom_sheet.dart';
import 'package:coconut_vault/widgets/adaptive_qr_image.dart';
import 'package:coconut_vault/widgets/animated_qr/view_data_handler/bc_ur_qr_view_handler.dart';
import 'package:coconut_vault/widgets/button/copy_text_container.dart';
import 'package:coconut_vault/widgets/tooltip/custom_tooltip.dart';
import 'package:coconut_vault/widgets/tooltip_description.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class SyncToWalletScreen extends StatefulWidget {
  final int id;
  final SyncOption syncOption;

  const SyncToWalletScreen({super.key, required this.id, required this.syncOption});

  @override
  State<SyncToWalletScreen> createState() => _SyncToWalletScreenState();
}

class _SyncToWalletScreenState extends State<SyncToWalletScreen> {
  late String _name;
  late bool _isMultisig;
  bool _isDerivationPathTapped = false;

  @override
  void initState() {
    super.initState();
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final vaultListItem = walletProvider.getVaultById(widget.id);
    _isMultisig = vaultListItem.vaultType == WalletType.multiSignature;
    _name = vaultListItem.name;
  }

  @override
  Widget build(BuildContext context) {
    final qrSize = MediaQuery.of(context).size.width * 0.8;

    return ChangeNotifierProvider<WalletToSyncViewModel>(
      create: (context) {
        final viewModel = WalletToSyncViewModel(widget.id, context.read<WalletProvider>());
        viewModel.setFormatOption(widget.syncOption);
        return viewModel;
      },
      child: Builder(
        builder: (providerContext) {
          final qrDataString = providerContext.watch<WalletToSyncViewModel>().qrDataString;
          return Scaffold(
            backgroundColor: CoconutColors.white,
            appBar: CoconutAppBar.build(
              title: t.sync_to_wallet_screen.title(name: _name),
              onBackPressed: () => Navigator.pop(context),
              context: context,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  color: CoconutColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildGuideTooltip(),
                      const SizedBox(height: 20),
                      _buildDerivationPathSection(providerContext),
                      const SizedBox(height: 20),
                      _buildQrSection(),
                      const SizedBox(height: 32),
                      _buildCopyTextSection(qrDataString, qrSize),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // MARK: - UI Sections

  Widget _buildGuideTooltip() {
    return CustomTooltip.buildInfoTooltip(
      context,
      richText: RichText(
        text: TextSpan(
          style: CoconutTypography.body2_14.copyWith(height: 1.3, color: CoconutColors.black),
          children: _getGuideTextSpan(),
        ),
      ),
    );
  }

  Widget _buildDerivationPathSection(BuildContext providerContext) {
    final isAccountEditEnabled = providerContext.watch<VisibilityProvider>().isAccountEditEnabled;

    return Selector<WalletProvider, ({String derivationPath, int currentAccount})>(
      selector: (context, provider) {
        final vault = provider.getVaultById(widget.id);
        if (vault is! SingleSigVaultListItem) {
          return (derivationPath: '', currentAccount: 0);
        }
        return (derivationPath: vault.derivationPath, currentAccount: vault.currentAccountIndex);
      },
      builder: (context, data, child) {
        if (data.derivationPath.isEmpty) return const SizedBox.shrink();

        final textColor =
            _isDerivationPathTapped
                ? CoconutColors.gray500
                : (isAccountEditEnabled ? CoconutColors.gray900 : CoconutColors.gray700);
        final iconColor = _isDerivationPathTapped ? CoconutColors.gray500 : CoconutColors.gray700;

        return GestureDetector(
          onTapDown: isAccountEditEnabled ? (_) => setState(() => _isDerivationPathTapped = true) : null,
          onTapCancel: isAccountEditEnabled ? () => setState(() => _isDerivationPathTapped = false) : null,
          onTapUp: isAccountEditEnabled ? (_) => setState(() => _isDerivationPathTapped = false) : null,
          onTap: isAccountEditEnabled ? () => _handleAccountEditTap(providerContext, data.currentAccount) : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(data.derivationPath, style: CoconutTypography.body2_14_Bold.copyWith(color: textColor)),
                if (isAccountEditEnabled) ...[
                  const SizedBox(width: 4),
                  SvgPicture.asset(
                    'assets/svg/edit-outlined.svg',
                    width: 14,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQrSection() {
    return Consumer<WalletToSyncViewModel>(
      builder: (context, vm, child) {
        return AdaptiveQrImage(
          key: ValueKey(vm.qrData.data),
          qrData: vm.qrData.type == QrType.single ? vm.qrData.data : null,
          qrViewDataHandler: vm.qrData.type != QrType.single ? BcUrQrViewHandler(vm.qrData.data, vm.urType) : null,
        );
      },
    );
  }

  Widget _buildCopyTextSection(String qrData, double qrWidth) {
    return SizedBox(
      width: qrWidth,
      child: CopyTextContainer(
        text: qrData,
        textStyle: CoconutTypography.body2_14_Number,
        toastMsg: t.toast.clipboard_copied,
      ),
    );
  }

  // MARK: - Handlers

  Future<void> _handleAccountEditTap(BuildContext providerContext, int currentAccount) async {
    final walletProvider = providerContext.read<WalletProvider>();
    bool hasPassphrase = false;

    if (!walletProvider.isSigningOnlyMode) {
      hasPassphrase = await walletProvider.hasPassphrase(widget.id);
    }

    if (!providerContext.mounted) return;

    if (hasPassphrase) {
      showModalBottomSheet(
        context: providerContext,
        isScrollControlled: true,
        builder:
            (context) => PassphraseVerificationBottomSheet(
              vaultId: widget.id,
              onVerificationSuccess: (passphrase) {
                Navigator.pop(providerContext);
                _showAccountEditSheet(providerContext, currentAccount, passphrase: passphrase);
              },
            ),
      );
    } else {
      _showAccountEditSheet(providerContext, currentAccount);
    }
  }

  void _showAccountEditSheet(BuildContext providerContext, int currentAccount, {Uint8List? passphrase}) {
    showModalBottomSheet(
      context: providerContext,
      isScrollControlled: true,
      builder:
          (context) => AccountEditBottomSheet(
            account: currentAccount,
            onUpdate: (account) async {
              await providerContext.read<WalletToSyncViewModel>().updateAccount(account, passphrase: passphrase);
            },
          ),
    );
  }

  // MARK: - Guide Text Builders

  List<TextSpan> _getGuideTextSpan() {
    final language = Provider.of<VisibilityProvider>(context, listen: false).language;
    final title = widget.syncOption.title;

    if (title == t.watch_only_options.coconut_wallet) {
      return _getCoconutGuide(language);
    } else if (title == t.watch_only_options.sparrow) {
      return _getSparrowGuide(language);
    } else if (title == t.watch_only_options.nunchuk) {
      return _getNunchukGuide(language);
    } else if (title == t.watch_only_options.bluewallet) {
      return _getBlueWalletGuide(language);
    }
    return [];
  }

  List<TextSpan> _getCoconutGuide(String language) {
    if (language == 'en') {
      return [
        em(t.watch_only_options.coconut_wallet),
        const TextSpan(text: '\n1. '),
        TextSpan(text: t.select),
        em(t.sync_to_wallet_screen.guide.coconut),
        const TextSpan(text: '\n'),
        TextSpan(text: t.sync_to_wallet_screen.guide.common),
      ];
    }
    return [
      em(t.watch_only_options.coconut_wallet),
      const TextSpan(text: '\n1. '),
      em(t.sync_to_wallet_screen.guide.coconut),
      TextSpan(text: t.select),
      const TextSpan(text: '\n'),
      TextSpan(text: t.sync_to_wallet_screen.guide.common),
    ];
  }

  List<TextSpan> _getSparrowGuide(String language) {
    if (language == 'en') {
      return [
        em(t.watch_only_options.sparrow),
        const TextSpan(text: '\n'),
        TextSpan(text: t.sync_to_wallet_screen.guide.sparrow_singlesig.guide0_1),
        const TextSpan(text: '\n1. '),
        TextSpan(text: t.select),
        em(" ${t.sync_to_wallet_screen.guide.sparrow_singlesig.guide1_1}"),
        const TextSpan(text: '\n2. '),
        TextSpan(text: t.select),
        em(" ${t.sync_to_wallet_screen.guide.sparrow_singlesig.guide2_1}"),
        if (_isMultisig) em(' ${t.sync_to_wallet_screen.guide.multisig}'),
        const TextSpan(text: '\n'),
        TextSpan(text: t.sync_to_wallet_screen.guide.sparrow_singlesig.guide3_1),
        TextSpan(text: t.sync_to_wallet_screen.guide.common),
      ];
    }
    return [
      em(t.watch_only_options.sparrow),
      const TextSpan(text: '\n'),
      TextSpan(text: t.sync_to_wallet_screen.guide.sparrow_singlesig.guide0_1),
      const TextSpan(text: '\n1. '),
      em(t.sync_to_wallet_screen.guide.sparrow_singlesig.guide1_1),
      TextSpan(text: ' ${t.select}\n2. '),
      em(t.sync_to_wallet_screen.guide.sparrow_singlesig.guide2_1),
      if (_isMultisig) em(' ${t.sync_to_wallet_screen.guide.multisig}'),
      TextSpan(text: ' ${t.select}\n'),
      TextSpan(text: t.sync_to_wallet_screen.guide.sparrow_singlesig.guide3_1),
      TextSpan(text: t.sync_to_wallet_screen.guide.common),
    ];
  }

  List<TextSpan> _getNunchukGuide(String language) {
    final guide = t.sync_to_wallet_screen.guide.nunchuk;

    if (language == 'en') {
      return [
        em(t.watch_only_options.nunchuk),
        const TextSpan(text: '\n1. '),
        TextSpan(text: '${guide.guide1_1} - '),
        em(!_isMultisig ? guide.guide1_2_singlesig : guide.guide1_2_multisig),
        const TextSpan(text: '\n2. '),
        TextSpan(text: !_isMultisig ? guide.guide2_1_siglesig : guide.guide2_1_multisig),
        const TextSpan(text: '\n3. '),
        TextSpan(text: '${t.select} '),
        em(!_isMultisig ? guide.guide3_1_singlesig : guide.guide3_1_multisig),
        const TextSpan(text: '\n4. '),
        if (!_isMultisig) TextSpan(text: guide.guide4_1_singlesig),
        if (_isMultisig) ...[TextSpan(text: '${t.select} '), em(guide.guide4_1_multisig)],
        const TextSpan(text: '\n'),
        TextSpan(text: t.sync_to_wallet_screen.guide.common),
      ];
    }
    return [
      em(t.watch_only_options.nunchuk),
      const TextSpan(text: '\n1. '),
      TextSpan(text: '${guide.guide1_1} - '),
      em(!_isMultisig ? guide.guide1_2_singlesig : guide.guide1_2_multisig),
      const TextSpan(text: '\n2. '),
      TextSpan(text: !_isMultisig ? guide.guide2_1_siglesig : guide.guide2_1_multisig),
      const TextSpan(text: '\n3. '),
      em(!_isMultisig ? guide.guide3_1_singlesig : guide.guide3_1_multisig),
      TextSpan(text: ' ${t.select}\n4. '),
      if (!_isMultisig) TextSpan(text: guide.guide4_1_singlesig),
      if (_isMultisig) ...[em(guide.guide4_1_multisig), TextSpan(text: ' ${t.select}')],
      const TextSpan(text: '\n'),
      TextSpan(text: t.sync_to_wallet_screen.guide.common),
    ];
  }

  List<TextSpan> _getBlueWalletGuide(String language) {
    final guide = t.sync_to_wallet_screen.guide.bluewallet;

    if (language == 'en') {
      return [
        em(t.watch_only_options.bluewallet),
        const TextSpan(text: '\n1. '),
        TextSpan(text: guide.guide1_1),
        const TextSpan(text: '\n2. '),
        TextSpan(text: t.select),
        em(" ${guide.guide2_1}"),
        const TextSpan(text: '\n3. '),
        TextSpan(text: t.select),
        em(" ${guide.guide3_1}"),
        const TextSpan(text: '\n'),
        TextSpan(text: t.sync_to_wallet_screen.guide.common),
      ];
    }
    return [
      em(t.watch_only_options.bluewallet),
      const TextSpan(text: '\n1. '),
      TextSpan(text: guide.guide1_1),
      const TextSpan(text: '\n2. '),
      em(guide.guide2_1),
      TextSpan(text: ' ${t.select}\n3. '),
      em(guide.guide3_1),
      TextSpan(text: ' ${t.select}\n'),
      TextSpan(text: t.sync_to_wallet_screen.guide.common),
    ];
  }
}
