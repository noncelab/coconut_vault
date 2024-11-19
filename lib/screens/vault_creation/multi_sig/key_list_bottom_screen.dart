import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/screens/vault_creation/multi_sig/assign_signers_screen.dart';
import 'package:coconut_vault/widgets/vault_row_item.dart';
import 'package:flutter/material.dart';

class KeyListBottomScreen extends StatefulWidget {
  final List<SinglesigVaultListItem> vaultList;
  final List<AssignedVaultListItem> assignedList;
  final void Function(SinglesigVaultListItem) onPressed;

  const KeyListBottomScreen({
    super.key,
    required this.onPressed,
    required this.vaultList,
    required this.assignedList,
  });

  @override
  _KeyListBottomScreenState createState() => _KeyListBottomScreenState();
}

class _KeyListBottomScreenState extends State<KeyListBottomScreen> {
  // 상태를 관리하는 리스트
  late List<bool> isPressedList;

  @override
  void initState() {
    super.initState();
    isPressedList = List<bool>.filled(widget.vaultList.length, false);
  }

  void _handleSelection(int index) {
    setState(() {
      for (int i = 0; i < widget.vaultList.length; i++) {
        isPressedList[i] = false;
      }
      isPressedList[index] = true;
    });
    widget.onPressed(widget.vaultList[index]);
  }

  bool _checkAssignedItem(SinglesigVaultListItem item) {
    for (var assignedItem in widget.assignedList) {
      if (item == assignedItem.item) {
        return true;
      }
    }
    return false;
  }

  bool _isAlreadyImportedInternalItem(String data) {
    for (int i = 0; i < widget.assignedList.length; i++) {
      String bsmsString = '';
      if (widget.assignedList[i].importKeyType == ImportKeyType.internal) {
        bsmsString = _extractOnlyPubString(
            (widget.assignedList[i].item!.coconutVault as SingleSignatureVault)
                .getSignerBsms(
                    AddressType.p2wsh, widget.assignedList[i].item!.name));
      } else if (widget.assignedList[i].importKeyType ==
          ImportKeyType.external) {
        bsmsString = _extractOnlyPubString(widget.assignedList[i].bsms ?? '');
      }

      if (bsmsString == _extractOnlyPubString(data)) {
        return true;
      }
    }
    return false;
  }

  String _extractOnlyPubString(String bsms) {
    String pubString = '';
    if (bsms.isNotEmpty) {
      if (bsms.contains('Vpub')) {
        pubString = bsms.substring(bsms.indexOf('Vpub'));
      }
      if (bsms.contains('Xpub')) {
        pubString = bsms.substring(bsms.indexOf('Xpub'));
      }
      if (bsms.contains('Zpub')) {
        pubString = bsms.substring(bsms.indexOf('Zpub'));
      }
      return pubString.substring(0, pubString.indexOf('\n'));
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Column(children: [
        const SizedBox(
          height: 20,
        ),
        ...List.generate(widget.vaultList.length, (index) {
          bool isAlreadyImported = _isAlreadyImportedInternalItem((widget
                  .vaultList[index].coconutVault as SingleSignatureVault)
              .getSignerBsms(AddressType.p2wsh, widget.vaultList[index].name));

          if (_checkAssignedItem(widget.vaultList[index]) ||
              isAlreadyImported) {
            return Container();
          }
          return VaultRowItem(
            vault: widget.vaultList[index],
            isSelectable: true,
            isPressed: isPressedList[index],
            onSelected: () => _handleSelection(index),
            resetSelected: () {},
          );
        }),
        const SizedBox(
          height: 50,
        ),
      ]),
    );
  }
}
