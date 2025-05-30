import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class MainRouteGuard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onAppGoBackground;

  const MainRouteGuard({super.key, required this.child, required this.onAppGoBackground});

  @override
  State<MainRouteGuard> createState() => _MainRouteGuardState();
}

class _MainRouteGuardState extends State<MainRouteGuard> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final vaultModel = Provider.of<WalletProvider>(
        context,
        listen: false,
      );
      final walletCount = SharedPrefsRepository().getInt(SharedPrefsKeys.vaultListLength) ?? 0;
      if (walletCount > 0 && widget.onAppGoBackground != null) {
        vaultModel.dispose();
        widget.onAppGoBackground!();
      }
    }
  }
}
