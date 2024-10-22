import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/calc_textlines.dart';
import 'package:coconut_vault/widgets/qrcode_info.dart';
import 'package:shimmer/shimmer.dart';

class MnemonicViewScreen extends StatefulWidget {
  const MnemonicViewScreen(
      {super.key,
      required this.mnemonic,
      this.passphrase = '',
      this.title = '',
      this.subtitle = ''});

  final String title;
  final String mnemonic;
  final String passphrase;
  final String subtitle;

  @override
  State<MnemonicViewScreen> createState() => _MnemonicViewScreen();
}

class _MnemonicViewScreen extends State<MnemonicViewScreen> {
  bool _isPressed = false;
  bool _isLoading = true;
  late List<Widget> _passphraseGridItems;

  @override
  void initState() {
    super.initState();
    _passphraseGridItems = _buildPassphraseGridItems();
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  List<Widget> _buildPassphraseGridItems() {
    List<Widget> gridItems = [];
    for (int index = 0; index < widget.passphrase.length + 20; index++) {
      if (index < widget.passphrase.length) {
        gridItems.add(
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: MyColors.white,
              border: Border.all(
                width: 1,
                color: MyColors.black,
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
                          color: MyColors.borderGrey,
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
                      widget.passphrase[index],
                      style: const TextStyle(
                        color: MyColors.black,
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
    const double qrSize = 375;
    final int skeletonTextLines = calculateNumberOfLines(
        context, widget.mnemonic, Styles.body2, qrSize, 36);
    List<Widget> textWidgets = [];
    for (int i = 0; i < skeletonTextLines; i++) {
      textWidgets.add(
        Column(
          children: [
            Container(
              width: qrSize,
              height: 20,
              color: MyColors.skeletonBaseColor,
            ),
            i < 4 ? const SizedBox(height: 5) : Container(),
          ],
        ),
      );
    }

    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: MyColors.skeletonBaseColor,
          highlightColor: MyColors.skeletonHighlightColor,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                    width: qrSize,
                    height: qrSize,
                    decoration: BoxDecorations.shadowBoxDecoration),
                const SizedBox(height: 32),
                for (int line = 0; line < textWidgets.length; line++)
                  textWidgets[line],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return QRCodeInfo(
      qrData: widget.mnemonic,
      toastMessage: '니모닉 문구가 복사됐어요.',
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
              color: _isPressed ? MyColors.borderGrey : MyColors.darkgrey,
            ),
            child: Text('패스프레이즈 보기',
                style: Styles.caption
                    .merge(const TextStyle(color: MyColors.white))),
          ),
          const SizedBox(
            height: 7,
          ),
          const Text(
            '누르는 동안 보여요',
            style: Styles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildPassphraseGridViewWidget() {
    if (widget.passphrase.isEmpty) return Container();
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
      borderRadius: MyBorder.defaultRadius,
      child: Scaffold(
        backgroundColor: MyColors.white,
        appBar: AppBar(
          title: !_isPressed ? Text(widget.title) : Text(widget.subtitle),
          centerTitle: true,
          backgroundColor: MyColors.white,
          titleTextStyle: Styles.body1Bold,
          toolbarTextStyle: Styles.body1Bold,
          leading: IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: MyColors.darkgrey,
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
              padding: Paddings.container,
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
                          visible: widget.passphrase.contains(' '),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: MyColors.darkgrey,
                                size: 14,
                              ),
                              Text(
                                ' 공백 문자는 빈칸으로 표시됩니다.',
                                style: TextStyle(
                                    color: MyColors.grey,
                                    fontSize: 14.0,
                                    fontFamily: CustomFonts.text.getFontFamily),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        _buildPassphraseGridViewWidget(),
                      ],
                    ),
                  ),
                  Visibility(
                      visible: widget.passphrase.isNotEmpty && !_isLoading,
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
