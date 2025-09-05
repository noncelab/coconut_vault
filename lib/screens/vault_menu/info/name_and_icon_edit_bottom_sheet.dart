import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/widgets/vault_name_icon_edit_palette.dart';
import 'package:loader_overlay/loader_overlay.dart';

class NameAndIconEditBottomSheet extends StatefulWidget {
  final String name;
  final int colorIndex;
  final int iconIndex;
  final Function(String, int, int) onUpdate;

  const NameAndIconEditBottomSheet({
    super.key,
    required this.onUpdate,
    required this.name,
    required this.colorIndex,
    required this.iconIndex,
  });

  @override
  State<NameAndIconEditBottomSheet> createState() => _NameAndIconEditBottomSheetState();
}

class _NameAndIconEditBottomSheetState extends State<NameAndIconEditBottomSheet> {
  late String _name;
  late int _iconIndex;
  late int _colorIndex;
  bool hasChanged = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _iconIndex = widget.iconIndex;
    _colorIndex = widget.colorIndex;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: CoconutBorder.defaultRadius,
      child: CustomLoadingOverlay(
        child: Scaffold(
          backgroundColor: CoconutColors.white,
          appBar: CoconutAppBar.build(
            context: context,
            title: _name,
            isBottom: true,
          ),
          body: SafeArea(
            child: Stack(
              children: [
                NestedScrollView(
                  headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                    return [];
                  },
                  body: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: CoconutColors.white,
                    child: VaultNameIconEditPalette(
                      name: _name, // 초기 값 설정
                      iconIndex: _iconIndex,
                      colorIndex: _colorIndex,
                      onNameChanged: (String newName) {
                        setState(() {
                          _name = newName;
                          hasChanged = true;
                        });
                      },
                      onIconSelected: (int newIconIndex) {
                        setState(() {
                          _iconIndex = newIconIndex;
                          hasChanged = true;
                        });
                      },
                      onColorSelected: (int newColorIndex) {
                        setState(() {
                          _colorIndex = newColorIndex;
                          hasChanged = true;
                        });
                      },
                    ),
                  ),
                ),
                FixedBottomButton(
                  text: t.complete,
                  onButtonClicked: _onNextPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onNextPressed() async {
    if (_name.trim().isEmpty) return;
    _closeKeyboard();
    setState(() {
      isSaving = hasChanged;
    });

    if (hasChanged) {
      context.loaderOverlay.show();
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        context.loaderOverlay.hide();
      }
    }

    widget.onUpdate(_name.isEmpty ? widget.name : _name, _iconIndex, _colorIndex);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }
}
