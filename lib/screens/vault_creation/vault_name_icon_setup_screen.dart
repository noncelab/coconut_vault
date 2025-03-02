import 'package:coconut_vault/app.dart';
import 'package:coconut_vault/model/manager/singlesig_wallet.dart';
import 'package:coconut_vault/model/state/multisig_creation_model.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/custom_dialog.dart';
import 'package:coconut_vault/widgets/indicator/message_activity_indicator.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/custom_toast.dart';
import 'package:coconut_vault/widgets/vault_name_icon_edit_palette.dart';
import 'package:provider/provider.dart';

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
  late VaultModel _vaultModel;
  late MultisigCreationModel _multisigCreationState;
  String inputText = '';
  late int selectedIconIndex;
  late int selectedColorIndex;
  final TextEditingController _controller = TextEditingController();
  bool _showLoading = false;

  @override
  void initState() {
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    _vaultModel.isVaultListLoadingNotifier.addListener(_onVaultListLoading);
    _multisigCreationState =
        Provider.of<MultisigCreationModel>(context, listen: false);
    super.initState();
    inputText = widget.name;
    selectedIconIndex = widget.iconIndex;
    selectedColorIndex = widget.colorIndex;
    _controller.text = inputText;
  }

  @override
  void dispose() {
    _vaultModel.isVaultListLoadingNotifier.removeListener(_onVaultListLoading);
    super.dispose();
  }

  void _onVaultListLoading() {
    if (!mounted) return;

    if (!_vaultModel.isVaultListLoadingNotifier.value) {
      if (_showLoading) {
        saveNewVaultName(context);
      }
    }
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> saveNewVaultName(BuildContext context) async {
    try {
      setState(() {
        _showLoading = true;
      });

      if (_vaultModel.isNameDuplicated(inputText)) {
        CustomToast.showToast(text: "이미 사용 중인 이름은 설정할 수 없어요", context: context);
        setState(() {
          _showLoading = false;
        });
        return;
      }

      if (_vaultModel.importingSecret != null) {
        await _vaultModel.addVault(SinglesigWallet(
            null,
            inputText,
            selectedIconIndex,
            selectedColorIndex,
            _vaultModel.importingSecret!,
            _vaultModel.importingPassphrase));

        if (_vaultModel.isAddVaultCompleted) {
          Logger.log('finish creating vault. return to home.');
          Logger.log('Homeroute = ${HomeScreenStatus().screenStatus}');
        }
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
      Logger.log("$e");
      CustomDialogs.showCustomAlertDialog(context,
          title: '생성 실패',
          onConfirm: () => Navigator.of(context).pop(),
          message: e.toString(),
          isSingleButton: true,
          confirmButtonColor: MyColors.black);
    } finally {
      setState(() {
        _showLoading = false;
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
              _closeKeyboard();
              if (_vaultModel.isVaultListLoading) {
                setState(() {
                  _showLoading = true;
                });
              } else {
                saveNewVaultName(context);
              }
            },
            isActive: inputText.trim().isNotEmpty && !_showLoading,
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
          visible: _showLoading,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration:
                const BoxDecoration(color: MyColors.transparentBlack_30),
            child: Center(
              child: _vaultModel.isVaultListLoading
                  ? const MessageActivityIndicator(
                      message: '저장 중이에요.') // 기존 볼트들 불러오는 중
                  : const CircularProgressIndicator(color: MyColors.darkgrey),
            ),
          ),
        ),
      ],
    );
  }
}
