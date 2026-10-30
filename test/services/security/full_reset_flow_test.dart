import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/usecases/reset_credentials_and_wallets_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class ResetWallets implements WalletProvider {
  final List<String> events;
  bool fail = false;
  ResetWallets(this.events);
  @override
  Future<void> reset() async {
    events.add('wallets');
    if (fail) throw StateError('test-only wallet deletion failure');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class ResetPreferences implements PreferenceProvider {
  final List<String> events;
  ResetPreferences(this.events);
  @override
  Future<void> resetVaultOrderAndFavorites() async {
    events.add('preferences');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class ResetAuth implements AuthProvider {
  final List<String> events;
  bool? preserve;
  bool? afterDeletion;
  ResetAuth(this.events);
  @override
  Future<void> resetCredentials({bool preservePermanentLock = false, bool afterWalletDeletion = false}) async {
    events.add('credentials');
    preserve = preservePermanentLock;
    afterDeletion = afterWalletDeletion;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('full reset enables recovery only after wallet and preference cleanup', () async {
    final events = <String>[];
    final auth = ResetAuth(events);
    await ResetCredentialsAndWalletsUsecase.execute(
      walletProvider: ResetWallets(events),
      authProvider: auth,
      preferenceProvider: ResetPreferences(events),
      preservePermanentLock: true,
    );
    expect(events, ['wallets', 'preferences', 'credentials']);
    expect(auth.afterDeletion, true);
    expect(auth.preserve, true);
  });

  test('wallet deletion failure never enables credential recovery', () async {
    final events = <String>[];
    final auth = ResetAuth(events);
    final wallets = ResetWallets(events)..fail = true;
    await expectLater(
      ResetCredentialsAndWalletsUsecase.execute(
        walletProvider: wallets,
        authProvider: auth,
        preferenceProvider: ResetPreferences(events),
      ),
      throwsStateError,
    );
    expect(events, ['wallets']);
    expect(auth.afterDeletion, null);
  });
}
