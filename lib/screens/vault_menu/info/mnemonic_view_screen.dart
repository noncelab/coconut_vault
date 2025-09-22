import 'dart:ui';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/list/mnemonic_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class MnemonicViewScreen extends StatefulWidget {
  const MnemonicViewScreen({
    super.key,
    required this.walletId,
  });

  final int walletId;

  @override
  State<MnemonicViewScreen> createState() => _MnemonicViewScreen();
}

class _MnemonicViewScreen extends State<MnemonicViewScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late WalletProvider _walletProvider;
  String? mnemonic;
  bool _isWarningVisible = true;

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _walletProvider.getSecret(widget.walletId).then((mnemonicValue) async {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        setState(() {
          mnemonic = mnemonicValue;
        });
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        context: context,
        title: t.view_mnemonic,
        backgroundColor: CoconutColors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  color: CoconutColors.white,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 48,
                          bottom: 24,
                        ),
                        child: Text(
                          t.mnemonic_view_screen.security_guide,
                          style: CoconutTypography.body1_16_Bold.setColor(
                            CoconutColors.warningText,
                          ),
                        ),
                      ),
                      MnemonicList(mnemonic: mnemonic ?? '', isLoading: mnemonic == null),
                      const SizedBox(height: 40),
                    ],
                  )),
            ),
            Visibility(
              visible: _isWarningVisible,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: CoconutColors.hotPink,
                        ),
                        padding: const EdgeInsets.only(top: 28, left: 20, right: 20, bottom: 20),
                        margin: const EdgeInsets.symmetric(horizontal: 68),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final text = Text(
                              t.mnemonic_view_screen.warning_title,
                              style: CoconutTypography.body1_16_Bold.setColor(CoconutColors.white),
                            );

                            final textPainter = TextPainter(
                              text: TextSpan(
                                  text: t.mnemonic_view_screen.warning_title,
                                  style: CoconutTypography.body1_16_Bold
                                      .setColor(CoconutColors.white)),
                              maxLines: 1,
                              textDirection: TextDirection.ltr,
                            )..layout(maxWidth: constraints.maxWidth);

                            final textWidth = textPainter.size.width;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/svg/triangle-warning.svg',
                                  colorFilter: const ColorFilter.mode(
                                    CoconutColors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                CoconutLayout.spacing_300h,
                                text,
                                CoconutLayout.spacing_400h,
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: textWidth),
                                  child: Text(
                                    t.mnemonic_view_screen.warning_guide,
                                    style: CoconutTypography.body2_14.setColor(CoconutColors.white),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                CoconutLayout.spacing_500h,
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: textWidth),
                                  child: ShrinkAnimationButton(
                                    borderRadius: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      width: double.infinity,
                                      child: Text(
                                        t.mnemonic_view_screen.warning_btn,
                                        style: CoconutTypography.body2_14_Bold
                                            .setColor(CoconutColors.hotPink),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isWarningVisible = false;
                                      });
                                    },
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
