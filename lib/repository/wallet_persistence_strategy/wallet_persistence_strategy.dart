import 'dart:typed_data';

import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/repository/model/taproot_wallet_input.dart';
import 'package:coconut_vault/utils/hash_util.dart';

/// Storage key derivation helpers shared by repository & strategies.
class WalletStorageKeys {
  static String _passphraseEnabledFlagKey(String key) => hashString("$key - passphraseEnabled");

  static String walletKey(int id, WalletType type) => hashString("${id.toString()} - ${type.name}");
  static String passphraseEnabledKey(String walletKey) => _passphraseEnabledFlagKey(walletKey);
  static String privacyInfoKey(String walletKey) => "privacy_${hashString(walletKey)}";

  // Taproot seed 관련
  static String taprootSeedKey(int walletId, String extendedPublicKey) =>
      hashString('$walletId - $extendedPublicKey');

  // 탭루트 지갑 구성하는 SeedKey 목록을 저장하는 키
  static String taprootSeedIndexKey(int walletId) => hashString("$walletId - taprootSeedIndex");
}

/// Persistence behavior that differs between secure-storage mode and signing-only mode.
///
/// Wallet-list mutations MUST go through [mutate], which guarantees the public vault list is
/// persisted exactly once after the body succeeds. This makes it impossible to forget the
/// `savePublicVaultList` call and naturally batches multiple writes (e.g., bulk delete) into
/// a single public list save.
abstract class WalletPersistenceStrategy {
  bool get isSigningOnlyMode;

  /// Whether the singlesig secret payload carries the passphrase.
  bool get passphraseStoredWithSecret;

  Future<bool> hasPassphrase(int walletId);

  /// Single entry point for any mutation that affects the wallet list.
  ///
  /// [execute] performs writes through [WalletWriteOps]. When it returns successfully,
  /// the public vault list is persisted exactly once using the result of [snapshot] (lazily
  /// evaluated so it observes mutations made inside [execute]).
  ///
  /// If [execute] throws, [snapshot] is NOT called and no public list save occurs; callers are
  /// responsible for reverting in-memory state and (if needed) calling [mutate] again to clean
  /// up partial disk writes.
  Future<T> mutate<T>({
    required Future<T> Function(WalletWriteOps ops) execute,
    required List<VaultListItemBase> Function() snapshot,
  });

  /// Update privacy info for an existing singlesig wallet (e.g., after account derivation change).
  /// Caller is responsible for following up with [savePublicVaultList] if the public json changed.
  Future<void> updateSinglesigPrivacy(int id, SingleSigVaultListItem item);

  /// Persist the public vault list snapshot. No-op in signing-only mode by policy.
  Future<void> savePublicVaultList(List<VaultListItemBase> items);
}

/// Wallet-level write operations available inside a [WalletPersistenceStrategy.mutate] body.
///
/// Implementations are library-private and can only be obtained via [WalletPersistenceStrategy.mutate],
/// which guarantees the public vault list save runs after the body.
abstract class WalletWriteOps {
  /// Atomically persist a new singlesig wallet (secret + privacy info).
  /// On a partial failure, rolls back internally before rethrowing.
  Future<void> persistSinglesigAdd({
    required int id,
    required Uint8List secret,
    Uint8List? passphrase,
    required SingleSigVaultListItem item,
  });

  /// Atomically persist a new multisig wallet (privacy info only).
  Future<void> persistMultisigAdd({required int id, required MultisigVaultListItem item});

  /// Atomically persist a new taproot wallet (secret + privacy info).
  /// On a partial failure, rolls back internally before rethrowing.
  Future<void> persistTaprootAdd({
    required int id,
    required List<TaprootSeedInfoForSave> seedInfosForAdd,
    required TaprootVaultListItem item,
  });

  /// Remove all data for the wallet (secret if singlesig + privacy info). Idempotent.
  Future<void> deleteWalletData(int id, WalletType type);
}
