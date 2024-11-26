import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:provider/provider.dart';

class SelectVaultTypeScreen extends StatefulWidget {
  const SelectVaultTypeScreen({super.key});

  @override
  State<SelectVaultTypeScreen> createState() => _SelectVaultTypeScreenState();
}

class _SelectVaultTypeScreenState extends State<SelectVaultTypeScreen> {
  String? nextPath;
  bool _processingNextPage = false;
  bool _nextButtonEnabled = true;
  late String guideText;
  List<String> options = ['/vault-creation-options', '/select-multisig-quoram'];
  late final model;

  @override
  void initState() {
    super.initState();
    model = Provider.of<VaultModel>(context, listen: false);
    guideText = '';
    model.addListener(onVaultListLoadingChanged);
  }

  @override
  void dispose() {
    model.removeListener(onVaultListLoadingChanged);
    super.dispose();
  }

  void onNextPressed() async {
    if (nextPath == options[0]) {
      // '일반 지갑' 선택 시
      setState(() {
        _processingNextPage = false;
      });
      Navigator.pushNamed(context, nextPath!);
    } else if (nextPath == options[1]) {
      // '다중 서명 지갑' 선택 시
      if (model.isVaultListLoading) {
        setState(() {
          _nextButtonEnabled = false;
          _processingNextPage = true;
        });
      } else if (!model.isVaultListLoading && model.vaultList.isNotEmpty) {
        setState(() {
          _processingNextPage = false;
        });
        Navigator.pushNamed(context, nextPath!);
      }
    }
  }

  void onVaultListLoadingChanged() {
    setState(() {
      if (!model.isVaultListLoading) {
        if (model.vaultList.isNotEmpty && _processingNextPage) {
          _processingNextPage = false;
          Navigator.pushNamed(context, nextPath!);
        } else {
          _processingNextPage = false;
        }
      } else {
        _processingNextPage = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VaultModel>(
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: MyColors.white,
          appBar: CustomAppBar.buildWithNext(
            title: '지갑 만들기',
            context: context,
            onNextPressed: () => onNextPressed(),
            isActive: _nextButtonEnabled,
          ),
          body: Stack(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
                child: Column(
                  children: [
                    Text(guideText),
                    const SizedBox(height: 10),
                    Text(
                      (nextPath == options[1] &&
                              !model.isVaultListLoading &&
                              model.vaultList.isEmpty)
                          ? '현재 볼트에 사용할 수 있는 키가 없어요'
                          : '',
                      style: Styles.caption.merge(
                        const TextStyle(
                          color: MyColors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableButton(
                            text: '일반 지갑',
                            onTap: () {
                              setState(() {
                                nextPath = options[0];
                                guideText = '하나의 니모닉 문구를 보관하는 단일 서명 지갑이에요';
                                _nextButtonEnabled = true;
                              });
                            },
                            isPressed: nextPath == options[0],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableButton(
                            text: '다중 서명 지갑',
                            onTap: () {
                              setState(() {
                                nextPath = options[1];
                                guideText = '지정한 수의 서명이 필요한 지갑이에요';
                                if (_processingNextPage ||
                                    (!model.isVaultListLoading &&
                                        model.vaultList.isEmpty)) {
                                  _nextButtonEnabled = false;
                                }
                              });
                            },
                            isPressed: nextPath == options[1],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: _processingNextPage,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: MyColors.transparentBlack_30,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: MyColors.darkgrey,
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        Text(
                          '가지고 있는 볼트를 불러오는 중이에요',
                          style: Styles.body2
                              .merge(const TextStyle(color: MyColors.darkgrey)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
