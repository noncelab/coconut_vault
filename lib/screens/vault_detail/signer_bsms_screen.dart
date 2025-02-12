import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/managers/isolate_manager.dart';
import 'package:coconut_vault/utils/isolate_handler.dart';
import 'package:coconut_vault/widgets/multisig/card/signer_bsms_info_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SignerBsmsScreen extends StatefulWidget {
  final int id;

  const SignerBsmsScreen({super.key, required this.id});

  @override
  State<SignerBsmsScreen> createState() => _SignerBsmsScreenState();
}

class _SignerBsmsScreenState extends State<SignerBsmsScreen> {
  String qrData = '';
  BSMS? _bsms;
  late String _name;
  bool _isLoading = true;
  late VaultListItemBase _vaultListItem;

  @override
  void initState() {
    super.initState();
    final model = Provider.of<WalletProvider>(context, listen: false);
    _vaultListItem = model.getVaultById(widget.id);
    _name = _vaultListItem.name;
    setSignerBsms();
  }

  Future<void> setSignerBsms() async {
    IsolateHandler<List<VaultListItemBase>, List<String>>
        extractBsmsIsolateHandler = IsolateHandler(extractSignerBsmsIsolate);
    await extractBsmsIsolateHandler.initialize(
        initialType: InitializeType.extractSignerBsms);

    try {
      List<String> bsmses =
          await extractBsmsIsolateHandler.run([_vaultListItem]);

      setState(() {
        qrData = bsmses[0];
        _bsms = BSMS.parseSigner(qrData);
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
                title: Text(t.errors.export_error),
                content: Text(error.toString()),
                actions: <CupertinoDialogAction>[
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(t.confirm),
                  ),
                ]);
          });
    } finally {
      extractBsmsIsolateHandler.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.white,
      appBar: CustomAppBar.build(
        title: _name,
        context: context,
        hasRightIcon: false,
        isBottom: true,
      ),
      body: SafeArea(
        child: Stack(children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20,
                ),
                CustomTooltip(
                    type: TooltipType.info,
                    showIcon: true,
                    richText: RichText(
                      text: TextSpan(
                        text: t.signer_bsms_screen.guide1_1,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.4,
                          letterSpacing: 0.5,
                          color: MyColors.black,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: t.signer_bsms_screen.guide1_2,
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          TextSpan(
                            text: t.signer_bsms_screen.guide1_3,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: t.signer_bsms_screen.guide1_4,
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          TextSpan(
                            text: t.signer_bsms_screen.guide1_5,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: t.signer_bsms_screen.guide1_6,
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 32),
                Center(
                    child: Container(
                        width: MediaQuery.of(context).size.width * 0.76,
                        decoration: BoxDecorations.shadowBoxDecoration,
                        child: QrImageView(
                          data: qrData,
                        ))),
                const SizedBox(height: 32),
                Column(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width - 50,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        t.signer_bsms_screen.export_info,
                        style: Styles.body2Bold,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (_bsms != null) SignerBsmsInfoCard(bsms: _bsms!)
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
          Visibility(
              visible: _isLoading,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: const BoxDecoration(color: MyColors.lightgrey),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: MyColors.darkgrey,
                  ),
                ),
              )),
        ]),
      ),
    );
  }
}
