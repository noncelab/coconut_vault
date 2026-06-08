import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/vault_creation/vault_type_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TaprootCreationOptionScreen extends StatefulWidget {
  const TaprootCreationOptionScreen({super.key});

  @override
  State<TaprootCreationOptionScreen> createState() => _TaprootCreationOptionScreenState();
}

class _TaprootCreationOptionScreenState extends State<TaprootCreationOptionScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: CoconutColors.white,
          appBar: CoconutAppBar.build(title: t.select_vault_type_screen.title, context: context),
          body: SafeArea(
            minimum: const EdgeInsets.only(top: 10, right: 16, left: 16),
            child: Stack(
              children: [
                Column(
                  children: [
                    buildCreationOptionButton(
                      t.taproot.taproot_creation_option.parent_creation_title,
                      t.taproot.taproot_creation_option.parent_creation_description,
                      onTapParentCreation(),
                      true,
                    ),
                    CoconutLayout.spacing_300h,
                    buildCreationOptionButton(
                      t.taproot.taproot_creation_option.child_creation_title,
                      t.taproot.taproot_creation_option.child_creation_description,
                      onTapChildCreation(),
                      true,
                    ),
                    CoconutLayout.spacing_300h,
                    buildCreationOptionButton(
                      t.taproot.taproot_creation_option.prepared_creation_title,
                      t.taproot.taproot_creation_option.prepared_creation_description,
                      onTapPreparedCreation(),
                      true,
                    ),
                    CoconutLayout.spacing_300h,
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  VoidCallback onTapParentCreation() {
    return () {
      Navigator.pushNamed(context, AppRoutes.taprootParentCreation);
    };
  }

  VoidCallback onTapChildCreation() {
    return () {
      Navigator.pushNamed(context, AppRoutes.taprootChildCreation);
    };
  }

  VoidCallback onTapPreparedCreation() {
    return () {
      Navigator.pushNamed(context, AppRoutes.taprootPreparedCreation);
    };
  }
}
