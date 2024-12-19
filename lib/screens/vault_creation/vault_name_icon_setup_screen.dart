import 'package:coconut_vault/model/manager/singlesig_wallet.dart';
import 'package:coconut_vault/model/state/app_model.dart';
import 'package:coconut_vault/model/state/multisig_creation_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/message_screen_for_web.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/custom_toast.dart';
import 'package:coconut_vault/widgets/vault_name_icon_edit_palette.dart';
import 'package:provider/provider.dart';

import '../../model/state/vault_model.dart';

class VaultNameIconSetup extends StatefulWidget {
  final String name;
  final int iconIndex;
  final int colorIndex;

  const VaultNameIconSetup({
    super.key,
    this.name = '',
    this.iconIndex = 0,
    this.colorIndex = 0,
  });

  @override
  State<VaultNameIconSetup> createState() => _VaultNameIconSetupState();
}

class _VaultNameIconSetupState extends State<VaultNameIconSetup> {
  late AppModel _appModel;
  late VaultModel _vaultModel;
  late MultisigCreationModel _multisigCreationState;
  String inputText = '';
  late int selectedIconIndex;
  late int selectedColorIndex;
  final TextEditingController _controller = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    _appModel = Provider.of<AppModel>(context, listen: false);
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    _multisigCreationState =
        Provider.of<MultisigCreationModel>(context, listen: false);
    super.initState();
    inputText = widget.name;
    selectedIconIndex = widget.iconIndex;
    selectedColorIndex = widget.colorIndex;
    _controller.text = inputText;
  }

  Future<void> saveNewVaultName(BuildContext context) async {
    try {
      setState(() {
        isSaving = true;
      });

      if (_vaultModel.isNameDuplicated(inputText)) {
        CustomToast.showToast(text: "이미 사용 중인 이름은 설정할 수 없어요", context: context);
        setState(() {
          isSaving = false;
        });
        return;
      }

      // delay for 1 second to show loading indicator
      await Future.delayed(const Duration(seconds: 2));

      if (_vaultModel.importingSecret != null) {
        await _vaultModel.addVault(SinglesigWallet(
            null,
            inputText,
            selectedIconIndex,
            selectedColorIndex,
            _vaultModel.importingSecret!,
            _vaultModel.importingPassphrase));
      } else if (_multisigCreationState.signers != null) {
        // 새로운 멀티시그 지갑 리스트 아이템을 생성.
        await _vaultModel.addMultisigVaultAsync(
            inputText, selectedColorIndex, selectedIconIndex);
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      CustomDialogs.showCustomAlertDialog(context,
          title: '생성 실패',
          onConfirm: () => Navigator.of(context).pop(),
          message: e.toString(),
          isSingleButton: true,
          confirmButtonColor: MyColors.black);

      setState(() {
        isSaving = false;
      });
    }
  }

  void updateName(String name) {
    setState(() {
      inputText = name;
    });
  }

  void updateIcon(int index) {
    setState(() {
      selectedIconIndex = index;
    });
  }

  void updateColor(int index) {
    setState(() {
      selectedColorIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VaultModel>(
      builder: (context, model, child) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: Colors.white,
              appBar: CustomAppBar.buildWithNext(
                title: '이름 설정',
                context: context,
                onBackPressed: () {
                  _vaultModel.completeSinglesigImporting();
                  Navigator.pop(context);
                },
                onNextPressed: () {
                  if (inputText.trim().isEmpty) return;
                  saveNewVaultName(context);
                },
                isActive: inputText.trim().isNotEmpty && !isSaving,
              ),
              body: VaultNameIconEditPalette(
                name: inputText,
                iconIndex: selectedIconIndex,
                colorIndex: selectedColorIndex,
                onNameChanged: updateName,
                onIconSelected: updateIcon,
                onColorSelected: updateColor,
              ),
            ),
            Visibility(
                visible: isSaving,
                child: const MessageScreenForWeb(
                    message: "지갑 추가 중...\n웹 브라우저에서 1분 이상 걸릴 수 있으니 기다려 주세요")),
          ],
        );
      },
    );
  }
}
