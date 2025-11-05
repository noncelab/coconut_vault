import 'package:coconut_vault/providers/app_lifecycle_state_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// INFO: vault_home이 최상단인 메인 루트에서만 사용하세요.
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
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final walletCount = SharedPrefsRepository().getInt(SharedPrefsKeys.vaultListLength) ?? 0;
    if (walletCount > 0 && widget.onAppGoBackground != null) {
      walletProvider.dispose();
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

  @override
  void dispose() {
    _lifecycleProvider.onAppGoBackground = _lifecycleProvider.onAppGoInactive = _lifecycleProvider.onAppGoActive = null;
    super.dispose();
  }
}
