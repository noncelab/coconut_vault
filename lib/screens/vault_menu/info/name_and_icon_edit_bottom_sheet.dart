import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
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
    return CustomLoadingOverlay(
      child: ClipRRect(
        borderRadius: CoconutBorder.defaultRadius,
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: CoconutColors.white,
              // TODO: custom_appber.buildWithSave로 대체 --> builWithSave를 활용하려면 이 코드도 변경이 필요해 보이기 때문에, 이건 CDS 적용할 때 바꾸는게 좋을 것 같습니다.
              appBar: AppBar(
                backgroundColor: CoconutColors.white,
                title: Text(_name, maxLines: 1),
                centerTitle: true,
                titleTextStyle: Styles.body1Bold,
                leading: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: CoconutColors.gray800,
                    size: 22,
                  ),
                  onPressed: () {
                    if (!isSaving) Navigator.pop(context);
                  },
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16.0),
                    child: GestureDetector(
                      onTap: () async {
                        if (_name.trim().isEmpty) return;
                        _closeKeyboard();
                        setState(() {
                          isSaving = hasChanged;
                        });
                        // CustomDialogs.showLoadingDialog(context);
                        if (hasChanged) {
                          context.loaderOverlay.show();

                          await Future.delayed(const Duration(seconds: 1));

                          context.loaderOverlay.hide();
                        }
                        widget.onUpdate(
                            _name.isEmpty ? widget.name : _name, _iconIndex, _colorIndex);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(
                            color: _name.trim().isNotEmpty
                                ? Colors.transparent
                                : CoconutColors.black.withOpacity(0.06),
                          ),
                          color: _name.trim().isNotEmpty
                              ? CoconutColors.gray800
                              : CoconutColors.gray150,
                        ),
                        child: Center(
                          child: Text(t.complete,
                              style: Styles.subLabel.merge(TextStyle(
                                  color: _name.trim().isNotEmpty
                                      ? CoconutColors.white
                                      : CoconutColors.black.withOpacity(0.3),
                                  fontSize: 11))),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              body: SafeArea(
                child: NestedScrollView(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }
}
