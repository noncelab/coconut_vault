import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/icon_path.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MultisigAddIconBottomSheet extends StatefulWidget {
  final String? iconSource;
  const MultisigAddIconBottomSheet({super.key, this.iconSource});

  @override
  State<MultisigAddIconBottomSheet> createState() => _MultisigAddIconBottomSheetState();
}

class _MultisigAddIconBottomSheetState extends State<MultisigAddIconBottomSheet> {
  String? selectedIconSource;

  @override
  void initState() {
    super.initState();
    selectedIconSource = widget.iconSource;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        customTitle: Text(t.multi_sig_setting_screen.add_icon.title, style: CoconutTypography.body1_16_Bold),
        context: context,
        isBottom: true,
        backgroundColor: CoconutColors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _buildWalletIconShrinkButton(
                          () => setState(() => selectedIconSource = kCoconutVaultIconPath),
                          kCoconutVaultIconPath,
                        ),
                      ),
                      Expanded(
                        child: _buildWalletIconShrinkButton(
                          () => setState(() => selectedIconSource = kKeystoneIconPath),
                          kKeystoneIconPath,
                        ),
                      ),
                      Expanded(
                        child: _buildWalletIconShrinkButton(
                          () => setState(() => selectedIconSource = kSeedSignerIconPath),
                          kSeedSignerIconPath,
                        ),
                      ),
                    ],
                  ),
                  CoconutLayout.spacing_300h,
                  Row(
                    children: [
                      Expanded(
                        child: _buildWalletIconShrinkButton(
                          () => setState(() => selectedIconSource = kJadeIconPath),
                          kJadeIconPath,
                        ),
                      ),
                      Expanded(
                        child: _buildWalletIconShrinkButton(
                          () => setState(() => selectedIconSource = kColdCardIconPath),
                          kColdCardIconPath,
                        ),
                      ),
                      Expanded(
                        child: _buildWalletIconShrinkButton(
                          () => setState(() => selectedIconSource = kKruxIconPath),
                          kKruxIconPath,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            FixedBottomButton(
              text: t.complete,
              showGradient: false,
              onButtonClicked: () {
                final signerSource = _getSignerSourceByIconSource();
                String hwwName = '';
                switch (signerSource) {
                  case SignerSource.coconutvault:
                    hwwName = t.multi_sig_setting_screen.add_icon.coconut_vault;
                    break;
                  case SignerSource.keystone3pro:
                    hwwName = t.multi_sig_setting_screen.add_icon.keystone3pro;
                    break;
                  case SignerSource.seedsigner:
                    hwwName = t.multi_sig_setting_screen.add_icon.seed_signer;
                    break;
                  case SignerSource.jade:
                    hwwName = t.multi_sig_setting_screen.add_icon.jade;
                    break;
                  case SignerSource.coldcard:
                    hwwName = t.multi_sig_setting_screen.add_icon.cold_card;
                    break;
                  case SignerSource.krux:
                    hwwName = t.multi_sig_setting_screen.add_icon.krux;
                    break;
                  case null:
                    hwwName = '';
                    break;
                }
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return CoconutPopup(
                      insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
                      title: t.multi_sig_setting_screen.add_icon_complete,
                      description: t.multi_sig_setting_screen.add_icon_complete_description(name: hwwName),
                      rightButtonText: t.confirm,
                      onTapRight: () {
                        Navigator.pop(context);
                        Navigator.pop(context, signerSource);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  SignerSource? _getSignerSourceByIconSource() {
    switch (selectedIconSource) {
      case kCoconutVaultIconPath:
        return SignerSource.coconutvault;
      case kKeystoneIconPath:
        return SignerSource.keystone3pro;
      case kSeedSignerIconPath:
        return SignerSource.seedsigner;
      case kJadeIconPath:
        return SignerSource.jade;
      case kColdCardIconPath:
        return SignerSource.coldcard;
      case kKruxIconPath:
        return SignerSource.krux;
      default:
        return null;
    }
  }

  Widget _buildWalletIconShrinkButton(VoidCallback onPressed, String iconSource) {
    String iconName = '';
    switch (iconSource) {
      case kCoconutVaultIconPath:
        iconName = t.multi_sig_setting_screen.add_icon.coconut_vault;
        break;
      case kKeystoneIconPath:
        iconName = t.multi_sig_setting_screen.add_icon.keystone3pro;
        break;
      case kSeedSignerIconPath:
        iconName = t.multi_sig_setting_screen.add_icon.seed_signer;
        break;
      case kJadeIconPath:
        iconName = t.multi_sig_setting_screen.add_icon.jade;
        break;
      case kColdCardIconPath:
        iconName = t.multi_sig_setting_screen.add_icon.cold_card;
        break;
      case kKruxIconPath:
        iconName = t.multi_sig_setting_screen.add_icon.krux;
        break;
    }
    return ShrinkAnimationButton(
      border: Border.all(
        color: selectedIconSource == iconSource ? CoconutColors.gray700 : CoconutColors.white,
        width: 1.5,
      ),
      borderRadius: 12,
      onPressed: () => onPressed(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            SvgPicture.asset(iconSource),
            CoconutLayout.spacing_100h,
            MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: Text(iconName, style: CoconutTypography.body2_14, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
