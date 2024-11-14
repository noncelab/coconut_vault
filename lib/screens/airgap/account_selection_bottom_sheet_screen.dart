import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:provider/provider.dart';

class AccountSelectionBottomSheetScreen extends StatefulWidget {
  final Function(int) onSelected;

  const AccountSelectionBottomSheetScreen(
      {super.key, required this.onSelected});

  @override
  State<AccountSelectionBottomSheetScreen> createState() =>
      _AccountSelectionBottomSheetScreenState();
}

class _AccountSelectionBottomSheetScreenState
    extends State<AccountSelectionBottomSheetScreen> {
  late List<SinglesigVaultListItem> _vaultList;
  late List<_SelectionItemParams> _selections;

  @override
  void initState() {
    super.initState();
    _vaultList = Provider.of<VaultModel>(context, listen: false).getVaults();
    List<_SelectionItemParams> selections = [];
    for (var vault in _vaultList) {
      selections.add(_SelectionItemParams(
        vaultId: vault.id,
        name: vault.name,
      ));
    }

    _selections = selections;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: MyBorder.defaultRadius,
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: Paddings.container,
                  color: MyColors.white,
                  child: Column(children: [
                    const SizedBox(
                      height: 10,
                    ),
                    const Text("서명할 계정을 선택해주세요."),
                    const SizedBox(
                      height: 10,
                    ),
                    ...List.generate(
                        _selections.length,
                        (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: _SelectionItem(
                                  params: _selections[index],
                                  onPressed: () {
                                    widget.onSelected(
                                      _selections[index].vaultId,
                                    );
                                  }),
                            ))
                  ])),
            ),
          ),
        ));
  }
}

class _SelectionItemParams {
  final int vaultId;
  final String name;

  _SelectionItemParams({required this.vaultId, required this.name});
}

class _SelectionItem extends StatelessWidget {
  final _SelectionItemParams params;
  final VoidCallback onPressed;

  const _SelectionItem({required this.params, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onPressed,
      child: Container(
        alignment: const Alignment(0.0, 0.5),
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: MyBorder.defaultRadius,
        ),
        padding: Paddings.widgetContainer,
        child: Text(
          "${params.name} 지갑",
          style: Styles.h3,
        ),
      ),
    );
  }
}
