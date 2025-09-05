import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/vault_menu/sync_to_wallet_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/services/blockchain_commons/ur_type.dart';
import 'package:coconut_vault/widgets/animated_qr/animated_qr_view.dart';
import 'package:coconut_vault/widgets/animated_qr/view_data_handler/bc_ur_qr_view_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SyncToWalletScreen extends StatefulWidget {
  final int id;

  const SyncToWalletScreen({super.key, required this.id});

  @override
  State<SyncToWalletScreen> createState() => _SyncToWalletScreenState();
}

class _SyncToWalletScreenState extends State<SyncToWalletScreen> {
  late String _name;
  List<bool> _isSelected = [true, false, false];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WalletToSyncViewModel>(
      create: (context) => WalletToSyncViewModel(widget.id, context.read<WalletProvider>()),
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(
          title: t.sync_to_wallet_screen.title(name: _name),
          context: context,
        ),
        body: SafeArea(
          minimum: CoconutPadding.container,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Selector<WalletToSyncViewModel, List<String>>(
                  selector: (context, vm) => vm.options,
                  builder: (context, options, child) => CoconutSegmentedControl(
                    labels: options,
                    isSelected: _isSelected,
                    onPressed: (index) {
                      setState(() {
                        _isSelected = List.generate(options.length, (index) => false);
                        _isSelected[index] = true;
                      });
                      context.read<WalletToSyncViewModel>().setSelectedOption(index);
                    },
                  ),
                ),
                const SizedBox(height: 32),
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
                                qrViewDataHandler: BcUrQrViewHandler(
                                    selectedValue.qrData.data, selectedValue.urType),
                                qrSize: qrSize,
                              );
                            }))),
                const SizedBox(height: 32),
              ],
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
    _name = vaultListItem.name;
  }
}
