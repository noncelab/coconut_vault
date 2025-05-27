import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/button/copy_text_container.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class MnemonicViewScreen extends StatefulWidget {
  const MnemonicViewScreen(
      {super.key, required this.walletId, this.title = '', this.subtitle = ''});

  final int walletId;
  final String title;
  final String subtitle;

  @override
  State<MnemonicViewScreen> createState() => _MnemonicViewScreen();
}

class _MnemonicViewScreen extends State<MnemonicViewScreen> {
  bool _isPressed = false;
  bool _isLoading = true;
  List<Widget> _passphraseGridItems = [];
  late WalletProvider _walletProvider;
  String? mnemonic;
  String? passphrase;

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _walletProvider.getSecret(widget.walletId).then((secret) async {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        setState(() {
          mnemonic = secret.mnemonic;
          passphrase = secret.passphrase;
          if (secret.passphrase.isNotEmpty) {
            _passphraseGridItems = _buildPassphraseGridItems();
          }
          _isLoading = false;
        });
      });
    });
  }

  List<Widget> _buildPassphraseGridItems() {
    List<Widget> gridItems = [];
    for (int index = 0; index < passphrase!.length + 20; index++) {
      if (index < passphrase!.length) {
        gridItems.add(
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CoconutColors.white,
              border: Border.all(
                width: 1,
                color: CoconutColors.black,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Visibility(
                  visible: index % 10 == 0,
                  child: Positioned(
                    top: 3,
                    left: 3,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          color: CoconutColors.borderGray,
                          fontWeight: FontWeight.bold,
                          fontSize: 6),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: Text(
                      passphrase![index],
                      style: const TextStyle(
                        color: CoconutColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        gridItems.add(Container());
      }
    }
    return gridItems;
  }

  Widget _buildSkeleton() {
    final double qrSize = MediaQuery.of(context).size.width * 275 / 375;
    const int skeletonTextLines = 4;
    List<Widget> textWidgets = [];
    for (int i = 0; i < skeletonTextLines; i++) {
      textWidgets.add(
        Column(
          children: [
            Container(
              width: qrSize,
              height: 20,
              color: CoconutColors.gray300,
            ),
            i < 4 ? const SizedBox(height: 5) : Container(),
          ],
        ),
      );
    }

    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: CoconutColors.gray300,
          highlightColor: CoconutColors.gray150,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                    width: qrSize,
                    height: qrSize,
                    decoration: CoconutBoxDecoration.shadowBoxDecoration),
                const SizedBox(height: 32),
                for (int line = 0; line < textWidgets.length; line++) textWidgets[line],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return CopyTextContainer(
      text: mnemonic!,
      toastMsg: t.toast.mnemonic_copied,
    );
  }

  Widget _passphraseButton() {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              color: _isPressed ? CoconutColors.borderGray : CoconutColors.gray800,
            ),
            child: Text(
              t.mnemonic_view_screen.view_passphrase,
              style: CoconutTypography.body3_12.setColor(
                CoconutColors.white,
              ),
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            t.mnemonic_view_screen.visible_while_pressing,
            style: CoconutTypography.body3_12.setColor(
              CoconutColors.gray800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassphraseGridViewWidget() {
    //if (passphrase.isEmpty) return Container();
    return GridView.count(
      crossAxisCount: 10,
      crossAxisSpacing: 3.0,
      mainAxisSpacing: 10.0,
      shrinkWrap: true,
      children: _passphraseGridItems, // 미리 생성한 아이템 리스트 사용
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: CoconutBorder.defaultRadius,
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: AppBar(
          title: !_isPressed ? Text(widget.title) : Text(widget.subtitle),
          centerTitle: true,
          backgroundColor: CoconutColors.white,
          titleTextStyle: CoconutTypography.body1_16_Bold,
          toolbarTextStyle: CoconutTypography.body1_16_Bold,
          leading: IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: CoconutColors.gray800,
              size: 22,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: CoconutPadding.container,
              child: Stack(
                children: [
                  Visibility(
                    visible: !_isPressed,
                    child: _isLoading ? _buildSkeleton() : _buildContent(),
                  ),
                  Visibility(
                    visible: _isPressed,
                    child: Column(
                      children: [
                        Visibility(
                          visible: passphrase != null && passphrase!.contains(' '),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: CoconutColors.gray800,
                                size: 14,
                              ),
                              Text(
                                t.mnemonic_view_screen.space_as_blank,
                                style: CoconutTypography.body2_14.setColor(
                                  CoconutColors.gray500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        if (passphrase != null) _buildPassphraseGridViewWidget(),
                      ],
                    ),
                  ),
                  Visibility(
                      visible: passphrase != null && passphrase!.isNotEmpty && !_isLoading,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _passphraseButton(),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
