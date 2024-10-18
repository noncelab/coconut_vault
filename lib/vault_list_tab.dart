import 'dart:io';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/app.dart';
import 'package:coconut_vault/screens/pin_check_screen.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/message_screen_for_web.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/model/app_model.dart';
import 'package:coconut_vault/screens/setting/settings_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/frosted_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/custom_tooltip.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'model/vault_model.dart';
import 'widgets/vault_row_item.dart';

class VaultListTab extends StatefulWidget {
  final bool? reload;
  const VaultListTab({
    super.key,
    this.reload = true,
  });

  @override
  State<VaultListTab> createState() => _VaultListTabState();
}

class _VaultListTabState extends State<VaultListTab>
    with WidgetsBindingObserver {
  late AppModel _appModel;
  late VaultModel _vaultModel;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _appModel = Provider.of<AppModel>(context, listen: false);
    _vaultModel = Provider.of<VaultModel>(context, listen: false);
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_vaultModel.vaultInitialized) {
        return;
      }

      if (widget.reload == null || widget.reload == true) {
        _vaultModel.loadVaultList();
      }

      // 초기화 이후 홈화면 진입시 설정창 노출
      if (_appModel.isResetVault) {
        MyBottomSheet.showBottomSheet_90(
            context: context, child: const SettingsScreen());
        _appModel.offResetVault();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VaultModel>(
      builder: (context, model, child) {
        final vaults = model.getVaults();
        final vaultListLoading = model.isVaultListLoading;

        return Center(
          child: Container(
            width: 480,
            color: MyColors.lightgrey,
            child: Stack(
              children: [
                CustomScrollView(
                  semanticChildCount:
                      model.isVaultListLoading ? 1 : vaults.length,
                  slivers: <Widget>[
                    const FrostedAppBar(),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      sliver: SliverList.builder(
                        itemCount: vaults.length + (vaults.isEmpty ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          if (index < vaults.length) {
                            return VaultRowItem(vault: vaults[index]);
                          }

                          if (index == vaults.length && vaults.isEmpty) {
                            if (!vaultListLoading) {
                              return CustomTooltip(
                                  richText: RichText(
                                      text: TextSpan(
                                          text:
                                              '안녕하세요. 코코넛 볼트예요!\n\n오른쪽 위 + 버튼을 눌러 니모닉 문구를 추가해 주세요.',
                                          style: Styles.subLabel.merge(
                                              const TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  color: MyColors.darkgrey)))),
                                  showIcon: true,
                                  type: TooltipType.normal);
                            }
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                Visibility(
                    visible: vaultListLoading,
                    child: const MessageScreenForWeb(
                        message:
                            "지갑 불러오는 중...\n웹 브라우저에서 1분 이상 걸릴 수 있으니 기다려 주세요.")),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
