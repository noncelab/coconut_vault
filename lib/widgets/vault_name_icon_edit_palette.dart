import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/icon/vault_icon.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/icon/svg_icon.dart';
import 'package:flutter_svg/svg.dart';

class VaultNameIconEditPalette extends StatefulWidget {
  final String name;
  final int iconIndex;
  final int colorIndex;
  final Function(String) onNameChanged;
  final Function(int) onIconSelected;
  final Function(int) onColorSelected;
  final Function(bool)? onFocusChanged;

  const VaultNameIconEditPalette({
    super.key,
    required this.onNameChanged,
    required this.onIconSelected,
    required this.onColorSelected,
    this.onFocusChanged,
    this.name = '',
    this.iconIndex = 0,
    this.colorIndex = 0,
  });

  @override
  State<VaultNameIconEditPalette> createState() => _VaultNameIconEditPaletteState();
}

class _VaultNameIconEditPaletteState extends State<VaultNameIconEditPalette> {
  late String _name;
  late int _selectedIconIndex;
  late int _selectedColorIndex;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _selectedIconIndex = widget.iconIndex;
    _selectedColorIndex = widget.colorIndex;
    _controller.text = _name;

    _focusNode.addListener(() {
      if (widget.onFocusChanged != null) {
        widget.onFocusChanged!(_focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(child: Container(height: 10)),
                SliverList(delegate: SliverChildListDelegate([_buildSelectedIconWithName()])),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 4.0,
                    ),
                    delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _updateSelected(index);
                          });
                        },
                        child: index < 10
                            ? Stack(
                                children: [
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
                                        borderRadius: BorderRadius.circular(40.0),
                                        border: Border.all(
                                          color: index == _selectedColorIndex
                                              ? CoconutColors.gray800
                                              : CoconutColors.white,
                                          width: 1.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Stack(
                                children: [
                                  Positioned.fill(child: SvgIcon(index: index - 10)),
                                  Positioned.fill(
                                    child: Container(
                                      margin: const EdgeInsets.all(11.5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(40.0),
                                        border: Border.all(
                                          color: index == _selectedIconIndex + 10
                                              ? CoconutColors.gray800
                                              : CoconutColors.white,
                                          width: 1.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      );
                    }, childCount: CoconutColors.colorPalette.length + CustomIcons.totalCount),
                  ),
                ),
                SliverToBoxAdapter(child: Container(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedIconWithName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CoconutLayout.spacing_400w,
            _selectedIconIndex >= 0
                ? Center(child: VaultIcon(iconIndex: _selectedIconIndex, colorIndex: _selectedColorIndex))
                : const SizedBox(width: 16),
            CoconutLayout.spacing_200w,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CoconutTextField(
                    isLengthVisible: false,
                    placeholderColor: CoconutColors.gray400,
                    placeholderText: t.name,
                    maxLength: 20,
                    maxLines: 1,
                    controller: _controller,
                    focusNode: _focusNode,
                    suffix: IconButton(
                      highlightColor: CoconutColors.gray200,
                      iconSize: 14,
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _controller.text = '';
                        });
                      },
                      icon: _controller.text.isNotEmpty
                          ? SvgPicture.asset(
                              'assets/svg/text-field-clear.svg',
                              colorFilter: const ColorFilter.mode(CoconutColors.gray400, BlendMode.srcIn),
                            )
                          : Container(),
                    ),
                    onChanged: (text) {
                      setState(() {
                        _name = text;
                        widget.onNameChanged(text);
                      });
                    },
                  ),
                ],
              ),
            ),
            CoconutLayout.spacing_400w,
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Text('${_name.length} / 20', style: CoconutTypography.body3_12_Number.setColor(CoconutColors.gray500)),
        ),
      ],
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
    return CoconutColors.colorPalette[index % CoconutColors.colorPalette.length];
  }
}
