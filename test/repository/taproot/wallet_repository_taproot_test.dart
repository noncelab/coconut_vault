import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/taproot/inheritance_leaf.dart';
import 'package:coconut_vault/model/taproot/seed_source.dart';
import 'package:coconut_vault/model/taproot/taproot_participant.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/model/taproot/taproot_wallet_create_dto.dart';
import 'package:coconut_vault/repository/model/taproot_wallet_input.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/secure_zone_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/repository/wallet_persistence_strategy/wallet_persistence_strategy.dart';
import 'package:coconut_vault/repository/wallet_repository.dart';
import 'package:coconut_vault/services/secure_zone/secure_zone_payload_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WalletRepository TaprootWallet CRUD', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SharedPrefsRepository().init();
    });

    test('SecureStorage / persists taproot secrets without passphrases and privacy info', () async {
      final storage = _FakeSecureStorageRepository();
      final secureZone = _FakeSecureZoneRepository();
      final repository = WalletRepository(storageService: storage, secureZoneRepository: secureZone);
      final keyPathSeed = _seedSource(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        'key-passphrase',
      );
      final beneficiarySeed = _seedSource(
        'legal winner thank year wave sausage worth useful legal winner thank yellow',
        'beneficiary-passphrase',
      );
      final walletCreateDto = TaprootWalletCreateDto(
        null,
        'taproot wallet',
        1,
        2,
        [keyPathSeed],
        null,
        [InheritanceLeaf(secret: beneficiarySeed, lockTime: 500000000)],
      );

      final result = await repository.addTaprootWallet(walletCreateDto);

      expect(result.id, 1);
      expect(result.name, 'taproot wallet');
      expect(result.vaultType, WalletType.taproot);
      expect(result.keyPathParticipants, hasLength(1));
      expect(result.beneficiaryParticipants, hasLength(1));
      expect(result.keyPathParticipants[0].isSeedStored, isTrue);
      expect(result.keyPathParticipants[0].isPassphraseSet, isTrue);
      expect(result.keyPathParticipants[0].type, TaprootParticipantType.keyPath);
      expect(result.beneficiaryParticipants[0].isSeedStored, isTrue);
      expect(result.beneficiaryParticipants[0].isPassphraseSet, isTrue);
      expect(result.beneficiaryParticipants[0].type, TaprootParticipantType.beneficiary);
      expect(repository.vaultList, hasLength(1));
      expect(repository.vaultList.single, same(result));
      expect(walletCreateDto.id, 1);
      expect(SharedPrefsRepository().getInt(SharedPrefsKeys.kNextIdField), 2);
      expect(secureZone.generatedAliases, hasLength(2));
      expect(secureZone.encryptedPlaintexts, hasLength(2));
      expect(storage.values.values.where((value) => value == 'true'), hasLength(2));
      expect(storage.values.keys.where((key) => key.contains('privacy')), isNotEmpty);

      final keyPathPlaintext = secureZone.encryptedPlaintexts[secureZone.generatedAliases.first]!;
      final keyPathPayload = SecureZonePayloadCodec.parsePlaintext(keyPathPlaintext);
      expect(keyPathPayload.secret, keyPathSeed.mnemonic);
      expect(keyPathPayload.passphrase, isNull);

      final beneficiaryPlaintext = secureZone.encryptedPlaintexts[secureZone.generatedAliases.last]!;
      final beneficiaryPayload = SecureZonePayloadCodec.parsePlaintext(beneficiaryPlaintext);
      expect(beneficiaryPayload.secret, beneficiarySeed.mnemonic);
      expect(beneficiaryPayload.passphrase, isNull);
    });

    test('SigningOnly / persists taproot secrets with passphrases and no public list', () async {
      final storage = _FakeSecureStorageRepository();
      final secureZone = _FakeSecureZoneRepository();
      final repository = WalletRepository(
        isSigningOnlyMode: true,
        storageService: storage,
        secureZoneRepository: secureZone,
      );
      final seed = _seedSource(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        'signing-only-passphrase',
      );
      final walletCreateDto = TaprootWalletCreateDto(null, 'taproot wallet', 1, 2, [seed], null, null);

      final result = await repository.addTaprootWallet(walletCreateDto);

      expect(result.id, 1);
      expect(result.name, 'taproot wallet');
      expect(result.vaultType, WalletType.taproot);
      expect(result.keyPathParticipants, hasLength(1));
      expect(result.beneficiaryParticipants, hasLength(0));
      expect(result.keyPathParticipants[0].isSeedStored, isTrue);
      expect(result.keyPathParticipants[0].isPassphraseSet, isTrue);
      expect(result.keyPathParticipants[0].type, TaprootParticipantType.keyPath);

      expect(repository.vaultList, hasLength(1));
      expect(repository.vaultList.single, same(result));
      expect(walletCreateDto.id, 1);
      expect(SharedPrefsRepository().getInt(SharedPrefsKeys.kNextIdField), 2);
      expect(secureZone.generatedAliases, hasLength(1));
      expect(secureZone.encryptedPlaintexts, hasLength(1));
      // hasPassphrase
      expect(storage.values.values.where((value) => value == 'true'), hasLength(0));
      expect(storage.values.keys.where((key) => key.contains('privacy')), isEmpty);
      expect(repository.vaultList, hasLength(1));
      expect(secureZone.generatedAliases, hasLength(1));
      expect(storage.values, hasLength(2));
      expect(storage.values.keys, contains(WalletStorageKeys.taprootSeedIndexKey(result.id)));
      expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), isEmpty);

      final plaintext = secureZone.encryptedPlaintexts[secureZone.generatedAliases.single]!;
      final payload = SecureZonePayloadCodec.parsePlaintext(plaintext);
      expect(payload.secret, seed.mnemonic);
      expect(payload.passphrase, seed.passphrase);
    });

    test('SecureStorage / persists taproot wallet with keyPathSignerBsmses', () async {
      final storage = _FakeSecureStorageRepository();
      final secureZone = _FakeSecureZoneRepository();
      final repository = WalletRepository(storageService: storage, secureZoneRepository: secureZone);
      final keyPathSeed = _seedSource(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        'key-passphrase',
      );
      final keyPathSignerBsms = _taprootSignerBsms(
        'legal winner thank year wave sausage worth useful legal winner thank yellow',
        'external-passphrase',
      );
      final walletCreateDto = TaprootWalletCreateDto(
        null,
        'taproot wallet with external signer',
        1,
        2,
        [keyPathSeed],
        [keyPathSignerBsms],
        null,
      );

      final result = await repository.addTaprootWallet(walletCreateDto);

      expect(result.id, 1);
      expect(result.name, 'taproot wallet with external signer');
      expect(result.vaultType, WalletType.taproot);
      expect(result.keyPathSeedInfos, hasLength(1));
      expect(result.keyPathParticipants, hasLength(2));
      expect(result.beneficiaryParticipants, hasLength(0));
      final seedStoredKeyPathIndex = result.keyPathParticipants.indexWhere((p) => p.isSeedStored);
      final noSeedKeyPathIndex = result.keyPathParticipants.indexWhere((p) => !p.isSeedStored);
      expect(result.keyPathParticipants[seedStoredKeyPathIndex].isSeedStored, isTrue);
      expect(result.keyPathParticipants[seedStoredKeyPathIndex].isPassphraseSet, isTrue);
      expect(result.keyPathParticipants[seedStoredKeyPathIndex].type, TaprootParticipantType.keyPath);
      expect(result.keyPathParticipants[noSeedKeyPathIndex].isSeedStored, isFalse);
      expect(result.keyPathParticipants[noSeedKeyPathIndex].isPassphraseSet, isFalse);
      expect(result.keyPathParticipants[noSeedKeyPathIndex].type, TaprootParticipantType.keyPath);

      expect(repository.vaultList, hasLength(1));
      expect(repository.vaultList.single, same(result));
      expect(SharedPrefsRepository().getInt(SharedPrefsKeys.kNextIdField), 2);
      expect(secureZone.generatedAliases, hasLength(1));
      expect(secureZone.encryptedPlaintexts, hasLength(1));
      expect(storage.values.values.where((value) => value == 'true'), hasLength(1));
      expect(storage.values.keys, contains(WalletStorageKeys.taprootSeedIndexKey(result.id)));
      expect(storage.values.keys.where((key) => key.contains('privacy')), isNotEmpty);

      final plaintext = secureZone.encryptedPlaintexts[secureZone.generatedAliases.single]!;
      final payload = SecureZonePayloadCodec.parsePlaintext(plaintext);
      expect(payload.secret, keyPathSeed.mnemonic);
      expect(payload.passphrase, isNull);
    });

    test('SigningOnly / persists taproot wallet with keyPathSignerBsmses', () async {
      final storage = _FakeSecureStorageRepository();
      final secureZone = _FakeSecureZoneRepository();
      final repository = WalletRepository(
        isSigningOnlyMode: true,
        storageService: storage,
        secureZoneRepository: secureZone,
      );
      final keyPathSeed = _seedSource(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        'signing-only-passphrase',
      );
      final keyPathSignerBsms = _taprootSignerBsms(
        'legal winner thank year wave sausage worth useful legal winner thank yellow',
        'external-passphrase',
      );
      final walletCreateDto = TaprootWalletCreateDto(
        null,
        'taproot wallet with external signer',
        1,
        2,
        [keyPathSeed],
        [keyPathSignerBsms],
        null,
      );

      final result = await repository.addTaprootWallet(walletCreateDto);

      expect(result.id, 1);
      expect(result.name, 'taproot wallet with external signer');
      expect(result.vaultType, WalletType.taproot);
      expect(result.keyPathSeedInfos, hasLength(1));
      expect(result.keyPathParticipants, hasLength(2));
      expect(result.beneficiaryParticipants, hasLength(0));
      final seedStoredKeyPathIndex = result.keyPathParticipants.indexWhere((p) => p.isSeedStored);
      final noSeedKeyPathIndex = result.keyPathParticipants.indexWhere((p) => !p.isSeedStored);
      expect(result.keyPathParticipants[seedStoredKeyPathIndex].isSeedStored, isTrue);
      expect(result.keyPathParticipants[seedStoredKeyPathIndex].isPassphraseSet, isTrue);
      expect(result.keyPathParticipants[seedStoredKeyPathIndex].type, TaprootParticipantType.keyPath);
      expect(result.keyPathParticipants[noSeedKeyPathIndex].isSeedStored, isFalse);
      expect(result.keyPathParticipants[noSeedKeyPathIndex].isPassphraseSet, isFalse);
      expect(result.keyPathParticipants[noSeedKeyPathIndex].type, TaprootParticipantType.keyPath);

      expect(repository.vaultList, hasLength(1));
      expect(repository.vaultList.single, same(result));
      expect(SharedPrefsRepository().getInt(SharedPrefsKeys.kNextIdField), 2);
      expect(secureZone.generatedAliases, hasLength(1));
      expect(secureZone.encryptedPlaintexts, hasLength(1));
      expect(storage.values.values.where((value) => value == 'true'), hasLength(0));
      expect(storage.values, hasLength(2));
      expect(storage.values.keys, contains(WalletStorageKeys.taprootSeedIndexKey(result.id)));
      expect(storage.values.keys.where((key) => key.contains('privacy')), isEmpty);
      expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), isEmpty);

      final plaintext = secureZone.encryptedPlaintexts[secureZone.generatedAliases.single]!;
      final payload = SecureZonePayloadCodec.parsePlaintext(plaintext);
      expect(payload.secret, keyPathSeed.mnemonic);
      expect(payload.passphrase, keyPathSeed.passphrase);
    });

    test('SecureStorage / persists taproot wallet with keyPathSignerBsmses and inheritanceLeaves', () async {
      final storage = _FakeSecureStorageRepository();
      final secureZone = _FakeSecureZoneRepository();
      final repository = WalletRepository(storageService: storage, secureZoneRepository: secureZone);
      final keyPathSeed = _seedSource(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        'key-passphrase',
      );
      final beneficiarySeed = _seedSource(
        'letter advice cage absurd amount doctor acoustic avoid letter advice cage above',
        'beneficiary-passphrase',
      );
      final keyPathSignerBsms = _taprootSignerBsms(
        'legal winner thank year wave sausage worth useful legal winner thank yellow',
        'external-passphrase',
      );
      final walletCreateDto = TaprootWalletCreateDto(
        null,
        'taproot inheritance wallet with external signer',
        1,
        2,
        [keyPathSeed],
        [keyPathSignerBsms],
        [InheritanceLeaf(secret: beneficiarySeed, lockTime: 500000000)],
      );

      final result = await repository.addTaprootWallet(walletCreateDto);

      expect(result.id, 1);
      expect(result.name, 'taproot inheritance wallet with external signer');
      expect(result.vaultType, WalletType.taproot);
      expect(result.keyPathSeedInfos, hasLength(1));
      expect(result.beneficiarySeedInfos, hasLength(1));
      expect(result.keyPathParticipants, hasLength(2));
      expect(result.beneficiaryParticipants, hasLength(1));
      final seedStoredKeyPathIndex = result.keyPathParticipants.indexWhere((p) => p.isSeedStored);
      final noSeedKeyPathIndex = result.keyPathParticipants.indexWhere((p) => !p.isSeedStored);
      expect(result.keyPathParticipants[seedStoredKeyPathIndex].isSeedStored, isTrue);
      expect(result.keyPathParticipants[seedStoredKeyPathIndex].isPassphraseSet, isTrue);
      expect(result.keyPathParticipants[seedStoredKeyPathIndex].type, TaprootParticipantType.keyPath);
      expect(result.keyPathParticipants[noSeedKeyPathIndex].isSeedStored, isFalse);
      expect(result.keyPathParticipants[noSeedKeyPathIndex].isPassphraseSet, isFalse);
      expect(result.keyPathParticipants[noSeedKeyPathIndex].type, TaprootParticipantType.keyPath);
      expect(result.beneficiaryParticipants.first.isSeedStored, isTrue);
      expect(result.beneficiaryParticipants.first.isPassphraseSet, isTrue);
      expect(result.beneficiaryParticipants.first.type, TaprootParticipantType.beneficiary);
      expect(result.beneficiaryParticipants.first.masterFingerprint, isNotEmpty);

      expect(repository.vaultList, hasLength(1));
      expect(repository.vaultList.single, same(result));
      expect(SharedPrefsRepository().getInt(SharedPrefsKeys.kNextIdField), 2);
      expect(secureZone.generatedAliases, hasLength(2));
      expect(secureZone.encryptedPlaintexts, hasLength(2));
      expect(storage.values.values.where((value) => value == 'true'), hasLength(2));
      expect(storage.values.keys, contains(WalletStorageKeys.taprootSeedIndexKey(result.id)));
      expect(storage.values.keys.where((key) => key.contains('privacy')), isNotEmpty);

      final keyPathPlaintext = secureZone.encryptedPlaintexts[secureZone.generatedAliases.first]!;
      final keyPathPayload = SecureZonePayloadCodec.parsePlaintext(keyPathPlaintext);
      expect(keyPathPayload.secret, keyPathSeed.mnemonic);
      expect(keyPathPayload.passphrase, isNull);

      final beneficiaryPlaintext = secureZone.encryptedPlaintexts[secureZone.generatedAliases.last]!;
      final beneficiaryPayload = SecureZonePayloadCodec.parsePlaintext(beneficiaryPlaintext);
      expect(beneficiaryPayload.secret, beneficiarySeed.mnemonic);
      expect(beneficiaryPayload.passphrase, isNull);
    });

    test('SecureStorage / loads taproot wallet with keyPathSignerBsmses and inheritanceLeaves', () async {
      final storage = _FakeSecureStorageRepository();
      final secureZone = _FakeSecureZoneRepository();
      final repository = WalletRepository(storageService: storage, secureZoneRepository: secureZone);
      final keyPathSeed = _seedSource(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        '',
      );
      final beneficiarySeed = _seedSource(
        'letter advice cage absurd amount doctor acoustic avoid letter advice cage above',
        'beneficiary-passphrase',
      );
      final keyPathSignerBsms = _taprootSignerBsms(
        'legal winner thank year wave sausage worth useful legal winner thank yellow',
        'external-passphrase',
      );
      final walletCreateDto = TaprootWalletCreateDto(
        null,
        'taproot inheritance wallet with external signer',
        1,
        2,
        [keyPathSeed],
        [keyPathSignerBsms],
        [InheritanceLeaf(secret: beneficiarySeed, lockTime: 500000000)],
      );

      final added = await repository.addTaprootWallet(walletCreateDto);
      final reloadedRepository = WalletRepository(storageService: storage, secureZoneRepository: secureZone);
      final jsonList = await reloadedRepository.loadVaultListJsonArrayString();
      final loaded = <TaprootVaultListItem>[];

      await reloadedRepository.loadAndEmitEachWallet(jsonList!, (wallet) => loaded.add(wallet as TaprootVaultListItem));

      expect(loaded, hasLength(1));
      expect(reloadedRepository.vaultList, hasLength(1));
      expect(loaded.single.id, added.id);
      expect(loaded.single.name, 'taproot inheritance wallet with external signer');
      expect(loaded.single.vaultType, WalletType.taproot);
      expect(loaded.single.descriptor, added.descriptor);
      expect(loaded.single.keyPathSeedInfos, hasLength(1));
      expect(loaded.single.beneficiarySeedInfos, hasLength(1));
      expect(loaded.single.keyPathSeedInfos.single.extendedPublicKey, added.keyPathSeedInfos.single.extendedPublicKey);
      expect(loaded.single.keyPathSeedInfos.single.isPassphraseSet, isFalse);
      expect(
        loaded.single.beneficiarySeedInfos.single.extendedPublicKey,
        added.beneficiarySeedInfos.single.extendedPublicKey,
      );
      expect(loaded.single.beneficiarySeedInfos.single.isPassphraseSet, isTrue);

      expect(loaded.single.keyPathParticipants, hasLength(2));
      expect(loaded.single.beneficiaryParticipants, hasLength(1));
      final seedStoredKeyPathIndex = loaded.single.keyPathParticipants.indexWhere((p) => p.isSeedStored);
      final noSeedKeyPathIndex = loaded.single.keyPathParticipants.indexWhere((p) => !p.isSeedStored);
      expect(loaded.single.keyPathParticipants[seedStoredKeyPathIndex].isSeedStored, isTrue);
      expect(loaded.single.keyPathParticipants[seedStoredKeyPathIndex].isPassphraseSet, isFalse);
      expect(loaded.single.keyPathParticipants[seedStoredKeyPathIndex].type, TaprootParticipantType.keyPath);
      expect(loaded.single.keyPathParticipants[noSeedKeyPathIndex].isSeedStored, isFalse);
      expect(loaded.single.keyPathParticipants[noSeedKeyPathIndex].isPassphraseSet, isFalse);
      expect(loaded.single.keyPathParticipants[noSeedKeyPathIndex].type, TaprootParticipantType.keyPath);
      expect(loaded.single.beneficiaryParticipants.first.isSeedStored, isTrue);
      expect(loaded.single.beneficiaryParticipants.first.isPassphraseSet, isTrue);
      expect(loaded.single.beneficiaryParticipants.first.type, TaprootParticipantType.beneficiary);
      expect(loaded.single.beneficiaryParticipants.first.lockTime, 500000000);
    });

    test('SigningOnly / persists taproot wallet with keyPathSignerBsmses and inheritanceLeaves', () async {
      final storage = _FakeSecureStorageRepository();
      final secureZone = _FakeSecureZoneRepository();
      final repository = WalletRepository(
        isSigningOnlyMode: true,
        storageService: storage,
        secureZoneRepository: secureZone,
      );
      final keyPathSeed = _seedSource(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        'signing-only-passphrase',
      );
      final beneficiarySeed = _seedSource(
        'letter advice cage absurd amount doctor acoustic avoid letter advice cage above',
        'beneficiary-passphrase',
      );
      final keyPathSignerBsms = _taprootSignerBsms(
        'legal winner thank year wave sausage worth useful legal winner thank yellow',
        'external-passphrase',
      );
      final walletCreateDto = TaprootWalletCreateDto(
        null,
        'taproot inheritance wallet with external signer',
        1,
        2,
        [keyPathSeed],
        [keyPathSignerBsms],
        [InheritanceLeaf(secret: beneficiarySeed, lockTime: 500000000)],
      );

      final result = await repository.addTaprootWallet(walletCreateDto);

      expect(result.id, 1);
      expect(result.name, 'taproot inheritance wallet with external signer');
      expect(result.vaultType, WalletType.taproot);
      expect(result.keyPathSeedInfos, hasLength(1));
      expect(result.beneficiarySeedInfos, hasLength(1));
      expect(result.keyPathParticipants, hasLength(2));
      expect(result.beneficiaryParticipants, hasLength(1));
      final seedStoredKeyPathIndex = result.keyPathParticipants.indexWhere((p) => p.isSeedStored);
      final noSeedKeyPathIndex = result.keyPathParticipants.indexWhere((p) => !p.isSeedStored);
      expect(result.keyPathParticipants[seedStoredKeyPathIndex].isSeedStored, isTrue);
      expect(result.keyPathParticipants[seedStoredKeyPathIndex].isPassphraseSet, isTrue);
      expect(result.keyPathParticipants[seedStoredKeyPathIndex].type, TaprootParticipantType.keyPath);
      expect(result.keyPathParticipants[noSeedKeyPathIndex].isSeedStored, isFalse);
      expect(result.keyPathParticipants[noSeedKeyPathIndex].isPassphraseSet, isFalse);
      expect(result.keyPathParticipants[noSeedKeyPathIndex].type, TaprootParticipantType.keyPath);
      expect(result.beneficiaryParticipants.first.isSeedStored, isTrue);
      expect(result.beneficiaryParticipants.first.isPassphraseSet, isTrue);
      expect(result.beneficiaryParticipants.first.type, TaprootParticipantType.beneficiary);
      expect(result.beneficiaryParticipants.first.masterFingerprint, isNotEmpty);

      expect(repository.vaultList, hasLength(1));
      expect(repository.vaultList.single, same(result));
      expect(SharedPrefsRepository().getInt(SharedPrefsKeys.kNextIdField), 2);
      expect(secureZone.generatedAliases, hasLength(2));
      expect(secureZone.encryptedPlaintexts, hasLength(2));
      expect(storage.values.values.where((value) => value == 'true'), hasLength(0));
      expect(storage.values, hasLength(3));
      expect(storage.values.keys, contains(WalletStorageKeys.taprootSeedIndexKey(result.id)));
      expect(storage.values.keys.where((key) => key.contains('privacy')), isEmpty);
      expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), isEmpty);

      final keyPathPlaintext = secureZone.encryptedPlaintexts[secureZone.generatedAliases.first]!;
      final keyPathPayload = SecureZonePayloadCodec.parsePlaintext(keyPathPlaintext);
      expect(keyPathPayload.secret, keyPathSeed.mnemonic);
      expect(keyPathPayload.passphrase, keyPathSeed.passphrase);

      final beneficiaryPlaintext = secureZone.encryptedPlaintexts[secureZone.generatedAliases.last]!;
      final beneficiaryPayload = SecureZonePayloadCodec.parsePlaintext(beneficiaryPlaintext);
      expect(beneficiaryPayload.secret, beneficiarySeed.mnemonic);
      expect(beneficiaryPayload.passphrase, beneficiarySeed.passphrase);
    });

    test('SecureStorage Only / loads added taproot inheritance wallet from a new repository', () async {
      final storage = _FakeSecureStorageRepository();
      final secureZone = _FakeSecureZoneRepository();
      final repository = WalletRepository(storageService: storage, secureZoneRepository: secureZone);
      final walletCreateDto = TaprootWalletCreateDto(
        null,
        'taproot inheritance wallet',
        1,
        2,
        [
          _seedSource(
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
            'key-passphrase',
          ),
        ],
        null,
        [
          InheritanceLeaf(
            secret: _seedSource('legal winner thank year wave sausage worth useful legal winner thank yellow', ''),
            lockTime: 500000000,
          ),
        ],
      );

      final added = await repository.addTaprootWallet(walletCreateDto);
      final reloadedRepository = WalletRepository(storageService: storage, secureZoneRepository: secureZone);
      final jsonList = await reloadedRepository.loadVaultListJsonArrayString();
      final loaded = <TaprootVaultListItem>[];

      await reloadedRepository.loadAndEmitEachWallet(jsonList!, (wallet) => loaded.add(wallet as TaprootVaultListItem));

      expect(loaded, hasLength(1));
      expect(reloadedRepository.vaultList, hasLength(1));
      expect(loaded.single.id, added.id);
      expect(loaded.single.name, 'taproot inheritance wallet');
      expect(loaded.single.vaultType, WalletType.taproot);
      expect(loaded.single.descriptor, added.descriptor);
      expect(loaded.single.keyPathSeedInfos, hasLength(1));
      expect(loaded.single.beneficiarySeedInfos, hasLength(1));
      expect(loaded.single.keyPathSeedInfos.single.extendedPublicKey, added.keyPathSeedInfos.single.extendedPublicKey);
      expect(
        loaded.single.beneficiarySeedInfos.single.extendedPublicKey,
        added.beneficiarySeedInfos.single.extendedPublicKey,
      );

      expect(loaded.single.keyPathParticipants, hasLength(1));
      expect(loaded.single.beneficiaryParticipants, hasLength(1));
      final seedStoredKeyPathIndex = loaded.single.keyPathParticipants.indexWhere((p) => p.isSeedStored);
      final noSeedKeyPathIndex = loaded.single.keyPathParticipants.indexWhere((p) => !p.isSeedStored);
      expect(seedStoredKeyPathIndex, equals(0));
      expect(noSeedKeyPathIndex, -1);
      expect(loaded.single.keyPathParticipants[seedStoredKeyPathIndex].isSeedStored, isTrue);
      expect(loaded.single.keyPathParticipants[seedStoredKeyPathIndex].isPassphraseSet, isTrue);
      expect(loaded.single.keyPathParticipants[seedStoredKeyPathIndex].type, TaprootParticipantType.keyPath);
      expect(loaded.single.beneficiaryParticipants.first.isSeedStored, isTrue);
      expect(loaded.single.beneficiaryParticipants.first.isPassphraseSet, isFalse);
      expect(loaded.single.beneficiaryParticipants.first.type, TaprootParticipantType.beneficiary);
      expect(loaded.single.beneficiaryParticipants.first.lockTime, 500000000);
    });

    test('SecureStorage / deletes loaded taproot inheritance wallet data', () async {
      final storage = _FakeSecureStorageRepository();
      final secureZone = _FakeSecureZoneRepository();
      final repository = WalletRepository(storageService: storage, secureZoneRepository: secureZone);
      final walletCreateDto = TaprootWalletCreateDto(
        null,
        'taproot inheritance wallet',
        1,
        2,
        [
          _seedSource(
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
            'key-passphrase',
          ),
        ],
        null,
        [
          InheritanceLeaf(
            secret: _seedSource(
              'legal winner thank year wave sausage worth useful legal winner thank yellow',
              'beneficiary-passphrase',
            ),
            lockTime: 500000000,
          ),
        ],
      );

      final added = await repository.addTaprootWallet(walletCreateDto);
      final reloadedRepository = WalletRepository(storageService: storage, secureZoneRepository: secureZone);
      final jsonList = await reloadedRepository.loadVaultListJsonArrayString();

      await reloadedRepository.loadAndEmitEachWallet(jsonList!, (_) {});

      final keyPathSeedKey = WalletStorageKeys.taprootSeedKey(
        added.id,
        TaprootSeedKeyIdentifierImpl(
          extendedPublicKey: added.keyPathSeedInfos.single.extendedPublicKey,
          role: TaprootSeedRole.keyPath,
        ),
      );
      final beneficiarySeedKey = WalletStorageKeys.taprootSeedKey(
        added.id,
        TaprootSeedKeyIdentifierImpl(
          extendedPublicKey: added.beneficiarySeedInfos.single.extendedPublicKey,
          role: TaprootSeedRole.beneficiary,
        ),
      );
      final walletKey = WalletStorageKeys.walletKey(added.id, WalletType.taproot);
      final privacyInfoKey = WalletStorageKeys.privacyInfoKey(walletKey);
      final seedIndexKey = WalletStorageKeys.taprootSeedIndexKey(added.id);

      final deleted = await reloadedRepository.deleteWallet(added.id);

      expect(deleted, isTrue);
      expect(reloadedRepository.vaultList, isEmpty);
      expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), '[]');
      expect(storage.deletedKeys, contains(keyPathSeedKey));
      expect(storage.deletedKeys, contains(WalletStorageKeys.taprootSeedPassphraseEnabledKey(keyPathSeedKey)));
      expect(storage.deletedKeys, contains(beneficiarySeedKey));
      expect(storage.deletedKeys, contains(WalletStorageKeys.taprootSeedPassphraseEnabledKey(beneficiarySeedKey)));
      expect(storage.deletedKeys, contains(privacyInfoKey));
      expect(storage.deletedKeys, contains(seedIndexKey));
      expect(secureZone.deletedAliases, contains(keyPathSeedKey));
      expect(secureZone.deletedAliases, contains(beneficiarySeedKey));
      expect(storage.values.containsKey(keyPathSeedKey), isFalse);
      expect(storage.values.containsKey(beneficiarySeedKey), isFalse);
      expect(storage.values.containsKey(privacyInfoKey), isFalse);
      expect(storage.values.containsKey(seedIndexKey), isFalse);
    });

    test('SigningOnly / deletes taproot inheritance wallet data', () async {
      final storage = _FakeSecureStorageRepository();
      final secureZone = _FakeSecureZoneRepository();
      final repository = WalletRepository(
        isSigningOnlyMode: true,
        storageService: storage,
        secureZoneRepository: secureZone,
      );
      final walletCreateDto = TaprootWalletCreateDto(
        null,
        'taproot inheritance wallet',
        1,
        2,
        [
          _seedSource(
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
            'key-passphrase',
          ),
        ],
        null,
        [
          InheritanceLeaf(
            secret: _seedSource(
              'legal winner thank year wave sausage worth useful legal winner thank yellow',
              'beneficiary-passphrase',
            ),
            lockTime: 500000000,
          ),
        ],
      );

      final added = await repository.addTaprootWallet(walletCreateDto);

      final keyPathSeedKey = WalletStorageKeys.taprootSeedKey(
        added.id,
        TaprootSeedKeyIdentifierImpl(
          extendedPublicKey: added.keyPathSeedInfos.single.extendedPublicKey,
          role: TaprootSeedRole.keyPath,
        ),
      );
      final beneficiarySeedKey = WalletStorageKeys.taprootSeedKey(
        added.id,
        TaprootSeedKeyIdentifierImpl(
          extendedPublicKey: added.beneficiarySeedInfos.single.extendedPublicKey,
          role: TaprootSeedRole.beneficiary,
        ),
      );
      final seedIndexKey = WalletStorageKeys.taprootSeedIndexKey(added.id);

      final deleted = await repository.deleteWallet(added.id);

      expect(deleted, isTrue);
      expect(repository.vaultList, isEmpty);
      expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), isEmpty);
      expect(storage.deletedKeys, contains(keyPathSeedKey));
      expect(storage.deletedKeys, contains(WalletStorageKeys.taprootSeedPassphraseEnabledKey(keyPathSeedKey)));
      expect(storage.deletedKeys, contains(beneficiarySeedKey));
      expect(storage.deletedKeys, contains(WalletStorageKeys.taprootSeedPassphraseEnabledKey(beneficiarySeedKey)));
      expect(storage.deletedKeys, contains(seedIndexKey));
      expect(secureZone.deletedAliases, contains(keyPathSeedKey));
      expect(secureZone.deletedAliases, contains(beneficiarySeedKey));
      expect(storage.values.containsKey(keyPathSeedKey), isFalse);
      expect(storage.values.containsKey(beneficiarySeedKey), isFalse);
      expect(storage.values.containsKey(seedIndexKey), isFalse);
    });

    test('SecureStorage / resetAll clears all taproot wallet data', () async {
      final storage = _FakeSecureStorageRepository();
      final secureZone = _FakeSecureZoneRepository();
      final repository = WalletRepository(storageService: storage, secureZoneRepository: secureZone);
      final walletCreateDto = TaprootWalletCreateDto(
        null,
        'taproot inheritance wallet',
        1,
        2,
        [
          _seedSource(
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
            'key-passphrase',
          ),
        ],
        [
          _taprootSignerBsms(
            'letter advice cage absurd amount doctor acoustic avoid letter advice cage above',
            'external-passphrase',
          ),
        ],
        [
          InheritanceLeaf(
            secret: _seedSource(
              'legal winner thank year wave sausage worth useful legal winner thank yellow',
              'beneficiary-passphrase',
            ),
            lockTime: 500000000,
          ),
        ],
      );

      final added = await repository.addTaprootWallet(walletCreateDto);
      final keyPathSeedKey = WalletStorageKeys.taprootSeedKey(
        added.id,
        TaprootSeedKeyIdentifierImpl(
          extendedPublicKey: added.keyPathSeedInfos.single.extendedPublicKey,
          role: TaprootSeedRole.keyPath,
        ),
      );
      final beneficiarySeedKey = WalletStorageKeys.taprootSeedKey(
        added.id,
        TaprootSeedKeyIdentifierImpl(
          extendedPublicKey: added.beneficiarySeedInfos.single.extendedPublicKey,
          role: TaprootSeedRole.beneficiary,
        ),
      );

      expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), isNotEmpty);

      await repository.resetAll();

      expect(storage.values, isEmpty);
      expect(secureZone.deletedAliases, hasLength(2));
      expect(secureZone.deletedAliases, contains(keyPathSeedKey));
      expect(secureZone.deletedAliases, contains(beneficiarySeedKey));
      expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), isEmpty);
      expect(SharedPrefsRepository().getInt(SharedPrefsKeys.kNextIdField), isNull);
    });

    test('SigningOnly / resetAll clears all taproot wallet data', () async {
      final storage = _FakeSecureStorageRepository();
      final secureZone = _FakeSecureZoneRepository();
      final repository = WalletRepository(
        isSigningOnlyMode: true,
        storageService: storage,
        secureZoneRepository: secureZone,
      );
      final walletCreateDto = TaprootWalletCreateDto(
        null,
        'taproot inheritance wallet',
        1,
        2,
        [
          _seedSource(
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
            'key-passphrase',
          ),
        ],
        null,
        [
          InheritanceLeaf(
            secret: _seedSource(
              'legal winner thank year wave sausage worth useful legal winner thank yellow',
              'beneficiary-passphrase',
            ),
            lockTime: 500000000,
          ),
        ],
      );

      final added = await repository.addTaprootWallet(walletCreateDto);
      final keyPathSeedKey = WalletStorageKeys.taprootSeedKey(
        added.id,
        TaprootSeedKeyIdentifierImpl(
          extendedPublicKey: added.keyPathSeedInfos.single.extendedPublicKey,
          role: TaprootSeedRole.keyPath,
        ),
      );
      final beneficiarySeedKey = WalletStorageKeys.taprootSeedKey(
        added.id,
        TaprootSeedKeyIdentifierImpl(
          extendedPublicKey: added.beneficiarySeedInfos.single.extendedPublicKey,
          role: TaprootSeedRole.beneficiary,
        ),
      );
      expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), isEmpty);
      expect(SharedPrefsRepository().getInt(SharedPrefsKeys.kNextIdField), isNotNull);

      await repository.resetAll();

      expect(storage.values, isEmpty);
      expect(secureZone.deletedAliases, contains(keyPathSeedKey));
      expect(secureZone.deletedAliases, contains(beneficiarySeedKey));
      expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), isEmpty);
      expect(SharedPrefsRepository().getInt(SharedPrefsKeys.kNextIdField), isNull);
    });

    test('SecureStorage / rolls back taproot secrets when privacy write fails', () async {
      final storage = _FakeSecureStorageRepository(throwOnPrivacyWrite: true);
      final secureZone = _FakeSecureZoneRepository();
      final repository = WalletRepository(storageService: storage, secureZoneRepository: secureZone);
      final walletCreateDto = TaprootWalletCreateDto(
        null,
        'taproot wallet',
        1,
        2,
        [
          _seedSource(
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
            '',
          ),
        ],
        null,
        null,
      );

      final seedIndexKey = WalletStorageKeys.taprootSeedIndexKey(1);

      await expectLater(repository.addTaprootWallet(walletCreateDto), throwsA(isA<StateError>()));

      expect(repository.vaultList, isEmpty);
      expect(storage.values, isEmpty);
      expect(storage.deletedKeys, isNotEmpty);
      expect(secureZone.deletedAliases, isNotEmpty);
      expect(storage.deletedKeys, contains(seedIndexKey));
      expect(SharedPrefsRepository().getInt(SharedPrefsKeys.kNextIdField), isNull);
    });
  });
}

SeedSource _seedSource(String mnemonic, String passphrase) {
  return SeedSource(
    mnemonic: Uint8List.fromList(utf8.encode(mnemonic)),
    passphrase: Uint8List.fromList(utf8.encode(passphrase)),
  );
}

String _taprootSignerBsms(String mnemonic, String passphrase) {
  final seed = Seed.fromMnemonic(
    Uint8List.fromList(utf8.encode(mnemonic)),
    passphrase: Uint8List.fromList(utf8.encode(passphrase)),
  );
  final keyStore = KeyStore.fromSeed(seed, AddressType.p2tr);
  final taprootVault = TaprootVault.fromKeyStoreList([keyStore], []);
  return taprootVault.getSignerBsms('');
}

class _FakeSecureStorageRepository implements SecureStorageRepositoryContract {
  final bool throwOnPrivacyWrite;
  final Map<String, String> values = {};
  final List<String> deletedKeys = [];

  _FakeSecureStorageRepository({this.throwOnPrivacyWrite = false});

  @override
  Future<void> write({required String key, required String value}) async {
    if (throwOnPrivacyWrite && key.contains('privacy')) {
      throw StateError('privacy write failed');
    }
    values[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> writeBytes({required String key, required Uint8List value}) async {
    values[key] = utf8.decode(value);
  }

  @override
  Future<Uint8List?> readBytes({required String key}) async {
    final value = values[key];
    if (value == null) return null;
    return Uint8List.fromList(utf8.encode(value));
  }

  @override
  Future<void> delete({required String key}) async {
    deletedKeys.add(key);
    values.remove(key);
  }

  @override
  Future<List<String>> getAllKeys() async => values.keys.toList();

  @override
  Future<void> deleteAll() async {
    deletedKeys.addAll(values.keys);
    values.clear();
  }
}

class _FakeSecureZoneRepository implements SecureZoneRepositoryContract {
  final List<String> generatedAliases = [];
  final Map<String, Uint8List> encryptedPlaintexts = {};
  final List<String> deletedAliases = [];

  @override
  Future<void> generateKey({required String alias, bool userAuthRequired = false, bool perUseAuth = false}) async {
    generatedAliases.add(alias);
  }

  @override
  Future<void> deleteKey({required String alias}) async {
    deletedAliases.add(alias);
  }

  @override
  Future<void> deleteKeys({required List<String> aliasList}) async {
    deletedAliases.addAll(aliasList);
  }

  @override
  Future<EncryptResult> encrypt({required String alias, required Uint8List plaintext}) async {
    encryptedPlaintexts[alias] = plaintext;
    return EncryptResult(ciphertext: Uint8List.fromList([1, 2, 3]), iv: Uint8List.fromList([4, 5, 6]), extra: null);
  }

  @override
  Future<Uint8List?> decrypt({
    required String alias,
    required Uint8List ciphertext,
    required Uint8List iv,
    bool autoAuth = true,
  }) async {
    return null;
  }
}
