import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/vault_menu/sync_to_wallet_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/home/select_sync_option_bottom_sheet.dart';
import 'package:coconut_vault/services/blockchain_commons/ur_type.dart';
import 'package:coconut_vault/widgets/animated_qr/animated_qr_view.dart';
import 'package:coconut_vault/widgets/animated_qr/view_data_handler/bc_ur_qr_view_handler.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WalletToSyncViewModel>(
      create: (context) {
        final viewModel = WalletToSyncViewModel(widget.id, context.read<WalletProvider>());
        viewModel.setFormatOption(widget.syncOption);
        return viewModel;
      },
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(title: t.sync_to_wallet_screen.title(name: _name), context: context),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              color: CoconutColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomTooltip.buildInfoTooltip(
                    context,
                    richText: RichText(
                      text: TextSpan(
                        style: CoconutTypography.body3_12.copyWith(color: CoconutColors.black),
                        children: _getGuideTextSpan(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: CoconutBoxDecoration.shadowBoxDecoration,
                      child: Selector<WalletToSyncViewModel, ({QrData qrData, UrType urType})>(
                        selector: (context, vm) => (qrData: vm.qrData, urType: vm.urType),
                        builder: (context, selectedValue, child) {
                          final qrSize = MediaQuery.of(context).size.width * 0.8;
                          if (selectedValue.qrData.type == QrType.single) {
                            return QrImageView(data: selectedValue.qrData.data, size: qrSize);
                          }
                          return AnimatedQrView(
                            qrViewDataHandler: BcUrQrViewHandler(selectedValue.qrData.data, selectedValue.urType),
                            qrSize: qrSize,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final vaultListItem = walletProvider.getVaultById(widget.id);
    _isMultisig = vaultListItem.vaultType == WalletType.multiSignature;
    _name = vaultListItem.name;
  }

  List<TextSpan> _getGuideTextSpan() {
    final language = Provider.of<VisibilityProvider>(context, listen: false).language;

    if (widget.syncOption.title == t.coconut) {
      return [
        _em(t.watch_only_options.coconut_wallet),
        const TextSpan(text: '\n'),
        _em(t.sync_to_wallet_screen.guide.coconut),
        const TextSpan(text: '\n'),
        TextSpan(text: t.sync_to_wallet_screen.guide.common),
      ];
    } else if (widget.syncOption.title == t.watch_only_options.sparrow) {
      switch (language) {
        case 'en':
          return [
            _em(t.watch_only_options.sparrow),
            const TextSpan(text: '\n'),
            TextSpan(text: t.sync_to_wallet_screen.guide.sparrow_singlesig.guide0_1),
            const TextSpan(text: '\n'),
            const TextSpan(text: '1. '),
            TextSpan(text: t.select),
            _em(" ${t.sync_to_wallet_screen.guide.sparrow_singlesig.guide1_1}"),
            const TextSpan(text: '\n'),
            const TextSpan(text: '2. '),
            TextSpan(text: t.select),
            _em(" ${t.sync_to_wallet_screen.guide.sparrow_singlesig.guide2_1}"),
            if (_isMultisig) _em(' ${t.sync_to_wallet_screen.guide.multisig}'),
            const TextSpan(text: '\n'),
            TextSpan(text: t.sync_to_wallet_screen.guide.sparrow_singlesig.guide3_1),
            TextSpan(text: t.sync_to_wallet_screen.guide.common),
          ];
        case 'kr':
        default:
          return [
            _em(t.watch_only_options.sparrow),
            const TextSpan(text: '\n'),
            TextSpan(text: t.sync_to_wallet_screen.guide.sparrow_singlesig.guide0_1),
            const TextSpan(text: '\n'),
            const TextSpan(text: '1. '),
            _em(t.sync_to_wallet_screen.guide.sparrow_singlesig.guide1_1),
            TextSpan(text: ' ${t.select}'),
            const TextSpan(text: '\n'),
            const TextSpan(text: '2. '),
            _em(t.sync_to_wallet_screen.guide.sparrow_singlesig.guide2_1),
            if (_isMultisig) _em(' ${t.sync_to_wallet_screen.guide.multisig}'),
            TextSpan(text: ' ${t.select}'),
            const TextSpan(text: '\n'),
            TextSpan(text: t.sync_to_wallet_screen.guide.sparrow_singlesig.guide3_1),
            TextSpan(text: t.sync_to_wallet_screen.guide.common),
          ];
      }
    } else if (widget.syncOption.title == t.watch_only_options.nunchuk) {
      switch (language) {
        case 'en':
          return [
            _em(t.watch_only_options.nunchuk),
            const TextSpan(text: '\n'),
            const TextSpan(text: '1. '),
            TextSpan(text: '${t.sync_to_wallet_screen.guide.nunchuk.guide1_1} - '),
            _em(
              !_isMultisig
                  ? t.sync_to_wallet_screen.guide.nunchuk.guide1_2_singlesig
                  : t.sync_to_wallet_screen.guide.nunchuk.guide1_2_multisig,
            ),
            const TextSpan(text: '\n'),
            TextSpan(
              text:
                  '2. ${!_isMultisig ? t.sync_to_wallet_screen.guide.nunchuk.guide2_1_siglesig : t.sync_to_wallet_screen.guide.nunchuk.guide2_1_multisig}',
            ),
            const TextSpan(text: '\n'),
            const TextSpan(text: '3. '),
            TextSpan(text: '${t.select} '),
            _em(
              !_isMultisig
                  ? t.sync_to_wallet_screen.guide.nunchuk.guide3_1_singlesig
                  : t.sync_to_wallet_screen.guide.nunchuk.guide3_1_multisig,
            ),
            const TextSpan(text: '\n'),
            const TextSpan(text: '4. '),
            if (!_isMultisig) TextSpan(text: t.sync_to_wallet_screen.guide.nunchuk.guide4_1_singlesig),
            if (_isMultisig) ...[
              TextSpan(text: '${t.select} '),
              _em(t.sync_to_wallet_screen.guide.nunchuk.guide4_1_multisig),
            ],
            const TextSpan(text: '\n'),
            TextSpan(text: t.sync_to_wallet_screen.guide.common),
          ];
        case 'kr':
        default:
          return [
            _em(t.watch_only_options.nunchuk),
            const TextSpan(text: '\n'),
            const TextSpan(text: '1. '),
            TextSpan(text: '${t.sync_to_wallet_screen.guide.nunchuk.guide1_1} - '),
            _em(
              !_isMultisig
                  ? t.sync_to_wallet_screen.guide.nunchuk.guide1_2_singlesig
                  : t.sync_to_wallet_screen.guide.nunchuk.guide1_2_multisig,
            ),
            const TextSpan(text: '\n'),
            TextSpan(
              text:
                  '2. ${!_isMultisig ? t.sync_to_wallet_screen.guide.nunchuk.guide2_1_siglesig : t.sync_to_wallet_screen.guide.nunchuk.guide2_1_multisig}',
            ),
            const TextSpan(text: '\n'),
            const TextSpan(text: '3. '),
            _em(
              !_isMultisig
                  ? t.sync_to_wallet_screen.guide.nunchuk.guide3_1_singlesig
                  : t.sync_to_wallet_screen.guide.nunchuk.guide3_1_multisig,
            ),
            TextSpan(text: ' ${t.select}'),
            const TextSpan(text: '\n'),
            const TextSpan(text: '4. '),
            if (!_isMultisig) TextSpan(text: t.sync_to_wallet_screen.guide.nunchuk.guide4_1_singlesig),
            if (_isMultisig) ...[
              _em(t.sync_to_wallet_screen.guide.nunchuk.guide4_1_multisig),
              TextSpan(text: ' ${t.select}'),
            ],
            const TextSpan(text: '\n'),
            TextSpan(text: t.sync_to_wallet_screen.guide.common),
          ];
      }
    } else if (widget.syncOption.title == t.watch_only_options.bluewallet) {
      switch (language) {
        case 'en':
          return [
            _em(t.watch_only_options.bluewallet),
            const TextSpan(text: '\n'),
            const TextSpan(text: '1. '),
            TextSpan(text: t.sync_to_wallet_screen.guide.bluewallet.guide1_1),
            const TextSpan(text: '\n'),
            const TextSpan(text: '2. '),
            TextSpan(text: t.select),
            _em(" ${t.sync_to_wallet_screen.guide.bluewallet.guide2_1}"),
            const TextSpan(text: '\n'),
            const TextSpan(text: '3. '),
            TextSpan(text: t.select),
            _em(" ${t.sync_to_wallet_screen.guide.bluewallet.guide3_1}"),
            const TextSpan(text: '\n'),
            TextSpan(text: t.sync_to_wallet_screen.guide.common),
          ];
        case 'kr':
        default:
          return [
            _em(t.watch_only_options.bluewallet),
            const TextSpan(text: '\n'),
            const TextSpan(text: '1. '),
            TextSpan(text: t.sync_to_wallet_screen.guide.bluewallet.guide1_1),
            const TextSpan(text: '\n'),
            const TextSpan(text: '2. '),
            _em(t.sync_to_wallet_screen.guide.bluewallet.guide2_1),
            TextSpan(text: ' ${t.select}'),
            const TextSpan(text: '\n'),
            const TextSpan(text: '3. '),
            _em(t.sync_to_wallet_screen.guide.bluewallet.guide3_1),
            TextSpan(text: ' ${t.select}'),
            const TextSpan(text: '\n'),
            TextSpan(text: t.sync_to_wallet_screen.guide.common),
          ];
      }
    }
    return [];
  }

  TextSpan _em(String text) => TextSpan(text: text, style: CoconutTypography.body3_12_Bold);
}
