import 'package:coconut_vault/providers/app_lifecycle_state_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class MainRouteGuard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onAppGoBackground;
  final VoidCallback? onAppGoInactive;
  final VoidCallback? onAppGoActive;

  const MainRouteGuard({
    super.key,
    required this.child,
    required this.onAppGoBackground,
    required this.onAppGoInactive,
    required this.onAppGoActive,
  });

  @override
  State<MainRouteGuard> createState() => _MainRouteGuardState();
}

class _MainRouteGuardState extends State<MainRouteGuard> {
  final AppLifecycleStateProvider _lifecycleProvider = AppLifecycleStateProvider();

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();

    _lifecycleProvider.onAppGoBackground = _handleAppGoBackground;
    _lifecycleProvider.onAppGoInactive = _handleAppGoInactive;
    _lifecycleProvider.onAppGoActive = _handleAppGoActive;
  }

  void _handleAppGoBackground() {
    final vaultModel = Provider.of<WalletProvider>(context, listen: false);
    final walletCount = SharedPrefsRepository().getInt(SharedPrefsKeys.vaultListLength) ?? 0;
    if (walletCount > 0 && widget.onAppGoBackground != null) {
      vaultModel.dispose();
      widget.onAppGoBackground!();
    }
  }

  void _handleAppGoInactive() {
    if (widget.onAppGoInactive != null) {
      Logger.log('-->Inactive');
      widget.onAppGoInactive!();
    }
  }

  void _handleAppGoActive() {
    if (widget.onAppGoActive != null) {
      Logger.log('-->Active');
      widget.onAppGoActive!();
    }
  }
}
