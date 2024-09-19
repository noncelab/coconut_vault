import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/icon/svg_icon.dart';
import 'package:coconut_vault/widgets/textfield/custom_textfield.dart';

class VaultNameIconEditPalette extends StatefulWidget {
  final String name;
  final int iconIndex;
  final int colorIndex;
  final Function(String) onNameChanged;
  final Function(int) onIconSelected;
  final Function(int) onColorSelected;

  const VaultNameIconEditPalette({
    super.key,
    required this.onNameChanged,
    required this.onIconSelected,
    required this.onColorSelected,
    this.name = '',
    this.iconIndex = 0,
    this.colorIndex = 0,
  });

  @override
  State<VaultNameIconEditPalette> createState() =>
      _VaultNameIconEditPaletteState();
}

class _VaultNameIconEditPaletteState extends State<VaultNameIconEditPalette> {
  late String _name;
  late int _selectedIconIndex;
  late int _selectedColorIndex;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _selectedIconIndex = widget.iconIndex;
    _selectedColorIndex = widget.colorIndex;
    _controller.text = _name;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      decoration: const BoxDecoration(color: Colors.white),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSelectedIconWithName(),
                  ]),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 4.0,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _updateSelected(index);
                            });
                          },
                          child: index < 10
                              ? Stack(children: [
                                  Container(
                                    margin: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(40.0),
                                      color: _getColorByIndex(index),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Container(
                                      margin: const EdgeInsets.all(11.5),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(40.0),
                                        border: Border.all(
                                          color: index == _selectedColorIndex
                                              ? MyColors.darkgrey
                                              : Colors.white,
                                          width: 1.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ])
                              : Stack(children: [
                                  SvgIcon(index: index - 10),
                                  Positioned.fill(
                                    child: Container(
                                      margin: const EdgeInsets.all(11.5),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(40.0),
                                        border: Border.all(
                                          color:
                                              index == _selectedIconIndex + 10
                                                  ? MyColors.darkgrey
                                                  : Colors.white,
                                          width: 1.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]),
                        );
                      },
                      childCount: ColorPalette.length + CustomIcons.totalCount,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedIconWithName() {
    return Container(
      padding: const EdgeInsets.only(right: 8.0, bottom: 20.0),
      child: Row(
        children: [
          _selectedIconIndex >= 0
              ? SvgIcon(
                  index: _selectedIconIndex,
                  colorIndex: _selectedColorIndex,
                  enableBorder: false,
                )
              : const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                CustomTextField(
                  placeholder: '이름',
                  maxLength: 20,
                  controller: _controller,
                  clearButtonMode: OverlayVisibilityMode.always,
                  onChanged: (text) {
                    setState(() {
                      _name = text;
                      widget.onNameChanged(text);
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      '(${_controller.text.length} / 20)',
                      style: TextStyle(
                          color: _controller.text.length == 20
                              ? MyColors.transparentBlack
                              : MyColors.transparentBlack_50,
                          fontSize: 12,
                          fontFamily: CustomFonts.text.getFontFamily),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateSelected(int index) {
    if (index < 10) {
      setState(() {
        _selectedColorIndex = index;
        widget.onColorSelected(index);
      });
    } else {
      setState(() {
        _selectedIconIndex = index - 10;
        widget.onIconSelected(_selectedIconIndex);
      });
    }
  }

  Color _getColorByIndex(int index) {
    return ColorPalette[index % ColorPalette.length];
  }
}
