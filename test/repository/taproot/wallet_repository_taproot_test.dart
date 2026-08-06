import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/taproot/creation/inheritance_leaf.dart';
import 'package:coconut_vault/model/taproot/seed_source.dart';
import 'package:coconut_vault/model/taproot/script_path_seed_info.dart';
import 'package:coconut_vault/model/taproot/taproot_seed_key_identifier.dart';
import 'package:coconut_vault/model/taproot/taproot_participant.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/model/taproot/creation/taproot_wallet_create_dto.dart';
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

    test(
      'SecureStorage / 1 stored key-path owner and 1 stored beneficiary / stores secrets without passphrases and writes privacy info',
      () async {
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
        expect(result.owners, hasLength(1));
        expect(result.beneficiaries, hasLength(1));
        expect(result.owners[0].isSeedStored, isTrue);
        expect(result.owners[0].isPassphraseSet, isTrue);
        expect(result.owners[0].type, TaprootParticipantType.keyPath);
        expect(result.beneficiaries[0].isSeedStored, isTrue);
        expect(result.beneficiaries[0].isPassphraseSet, isTrue);
        expect(result.beneficiaries[0].type, TaprootParticipantType.beneficiary);
        expect(repository.vaultList, hasLength(1));
        expect(repository.vaultList.single, same(result));
        expect(walletCreateDto.id, 1);
        expect(SharedPrefsRepository().getInt(SharedPrefsKeys.kNextIdField), 2);
        expect(secureZone.generatedAliases, hasLength(2));
        expect(secureZone.encryptedPlaintexts, hasLength(2));
        // taproot hasPassphrase 저장 로직 제거함 PrivacyInfo에 포함되어있음
        expect(storage.values.values.where((value) => value == 'true'), hasLength(0));
        expect(storage.values.keys.where((key) => key.contains('privacy')), isNotEmpty);

        final keyPathPlaintext = secureZone.encryptedPlaintexts[secureZone.generatedAliases.first]!;
        final keyPathPayload = SecureZonePayloadCodec.parsePlaintext(keyPathPlaintext);
        expect(keyPathPayload.secret, keyPathSeed.mnemonic);
        expect(keyPathPayload.passphrase, isNull);

        final beneficiaryPlaintext = secureZone.encryptedPlaintexts[secureZone.generatedAliases.last]!;
        final beneficiaryPayload = SecureZonePayloadCodec.parsePlaintext(beneficiaryPlaintext);
        expect(beneficiaryPayload.secret, beneficiarySeed.mnemonic);
        expect(beneficiaryPayload.passphrase, isNull);
      },
    );

    test(
      'SigningOnly / 1 stored key-path owner and no beneficiaries / stores secret with passphrase and skips public vault list',
      () async {
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
        expect(result.owners, hasLength(1));
        expect(result.beneficiaries, hasLength(0));
        expect(result.owners[0].isSeedStored, isTrue);
        expect(result.owners[0].isPassphraseSet, isTrue);
        expect(result.owners[0].type, TaprootParticipantType.keyPath);

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
      },
    );

    test(
      'SecureStorage / stored key-path owner plus external key-path owner / stores only local owner secret',
      () async {
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
        expect(result.owners, hasLength(2));
        expect(result.beneficiaries, hasLength(0));
        final seedStoredKeyPathIndex = result.owners.indexWhere((p) => p.isSeedStored);
        final noSeedKeyPathIndex = result.owners.indexWhere((p) => !p.isSeedStored);
        expect(result.owners[seedStoredKeyPathIndex].isSeedStored, isTrue);
        expect(result.owners[seedStoredKeyPathIndex].isPassphraseSet, isTrue);
        expect(result.owners[seedStoredKeyPathIndex].type, TaprootParticipantType.keyPath);
        expect(result.owners[noSeedKeyPathIndex].isSeedStored, isFalse);
        expect(result.owners[noSeedKeyPathIndex].isPassphraseSet, isFalse);
        expect(result.owners[noSeedKeyPathIndex].type, TaprootParticipantType.keyPath);

        expect(repository.vaultList, hasLength(1));
        expect(repository.vaultList.single, same(result));
        expect(SharedPrefsRepository().getInt(SharedPrefsKeys.kNextIdField), 2);
        expect(secureZone.generatedAliases, hasLength(1));
        expect(secureZone.encryptedPlaintexts, hasLength(1));
        // taproot hasPassphrase 저장 로직 제거함 PrivacyInfo에 포함되어있음
        expect(storage.values.values.where((value) => value == 'true'), hasLength(0));
        expect(storage.values.keys, contains(WalletStorageKeys.taprootSeedIndexKey(result.id)));
        expect(storage.values.keys.where((key) => key.contains('privacy')), isNotEmpty);

        final plaintext = secureZone.encryptedPlaintexts[secureZone.generatedAliases.single]!;
        final payload = SecureZonePayloadCodec.parsePlaintext(plaintext);
        expect(payload.secret, keyPathSeed.mnemonic);
        expect(payload.passphrase, isNull);
      },
    );

    test(
      'SigningOnly / stored key-path owner plus external key-path owner / stores local owner secret with passphrase only',
      () async {
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
        expect(result.owners, hasLength(2));
        expect(result.beneficiaries, hasLength(0));
        final seedStoredKeyPathIndex = result.owners.indexWhere((p) => p.isSeedStored);
        final noSeedKeyPathIndex = result.owners.indexWhere((p) => !p.isSeedStored);
        expect(result.owners[seedStoredKeyPathIndex].isSeedStored, isTrue);
        expect(result.owners[seedStoredKeyPathIndex].isPassphraseSet, isTrue);
        expect(result.owners[seedStoredKeyPathIndex].type, TaprootParticipantType.keyPath);
        expect(result.owners[noSeedKeyPathIndex].isSeedStored, isFalse);
        expect(result.owners[noSeedKeyPathIndex].isPassphraseSet, isFalse);
        expect(result.owners[noSeedKeyPathIndex].type, TaprootParticipantType.keyPath);

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
      },
    );

    test(
      'SecureStorage / stored key-path owner, external key-path owner, and stored beneficiary / stores local secrets without passphrases',
      () async {
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
        expect(result.scriptPathSeedInfos, hasLength(1));
        expect(result.owners, hasLength(2));
        expect(result.beneficiaries, hasLength(1));
        final seedStoredKeyPathIndex = result.owners.indexWhere((p) => p.isSeedStored);
        final noSeedKeyPathIndex = result.owners.indexWhere((p) => !p.isSeedStored);
        expect(result.owners[seedStoredKeyPathIndex].isSeedStored, isTrue);
        expect(result.owners[seedStoredKeyPathIndex].isPassphraseSet, isTrue);
        expect(result.owners[seedStoredKeyPathIndex].type, TaprootParticipantType.keyPath);
        expect(result.owners[noSeedKeyPathIndex].isSeedStored, isFalse);
        expect(result.owners[noSeedKeyPathIndex].isPassphraseSet, isFalse);
        expect(result.owners[noSeedKeyPathIndex].type, TaprootParticipantType.keyPath);
        expect(result.beneficiaries.first.isSeedStored, isTrue);
        expect(result.beneficiaries.first.isPassphraseSet, isTrue);
        expect(result.beneficiaries.first.type, TaprootParticipantType.beneficiary);
        expect(result.beneficiaries.first.masterFingerprint, isNotEmpty);

        expect(repository.vaultList, hasLength(1));
        expect(repository.vaultList.single, same(result));
        expect(SharedPrefsRepository().getInt(SharedPrefsKeys.kNextIdField), 2);
        expect(secureZone.generatedAliases, hasLength(2));
        expect(secureZone.encryptedPlaintexts, hasLength(2));
        // taproot hasPassphrase 저장 로직 제거함 PrivacyInfo에 포함되어있음
        expect(storage.values.values.where((value) => value == 'true'), hasLength(0));
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
      },
    );

    test(
      'SecureStorage / stored key-path owner, external key-path owner, and stored beneficiary / reloads participants from privacy info',
      () async {
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

        await reloadedRepository.loadAndEmitEachWallet(
          jsonList!,
          (wallet) => loaded.add(wallet as TaprootVaultListItem),
        );

        expect(loaded, hasLength(1));
        expect(reloadedRepository.vaultList, hasLength(1));
        expect(loaded.single.id, added.id);
        expect(loaded.single.name, 'taproot inheritance wallet with external signer');
        expect(loaded.single.vaultType, WalletType.taproot);
        expect(loaded.single.descriptor, added.descriptor);
        expect(loaded.single.keyPathSeedInfos, hasLength(1));
        expect(loaded.single.scriptPathSeedInfos, hasLength(1));
        expect(
          loaded.single.keyPathSeedInfos.single.extendedPublicKey,
          added.keyPathSeedInfos.single.extendedPublicKey,
        );
        expect(loaded.single.keyPathSeedInfos.single.isPassphraseSet, isFalse);
        expect(
          loaded.single.scriptPathSeedInfos.single.seedInfos.single.extendedPublicKey,
          added.scriptPathSeedInfos.single.seedInfos.single.extendedPublicKey,
        );
        expect(loaded.single.scriptPathSeedInfos.single.seedInfos.single.isPassphraseSet, isTrue);

        expect(loaded.single.owners, hasLength(2));
        expect(loaded.single.beneficiaries, hasLength(1));
        final seedStoredKeyPathIndex = loaded.single.owners.indexWhere((p) => p.isSeedStored);
        final noSeedKeyPathIndex = loaded.single.owners.indexWhere((p) => !p.isSeedStored);
        expect(loaded.single.owners[seedStoredKeyPathIndex].isSeedStored, isTrue);
        expect(loaded.single.owners[seedStoredKeyPathIndex].isPassphraseSet, isFalse);
        expect(loaded.single.owners[seedStoredKeyPathIndex].type, TaprootParticipantType.keyPath);
        expect(loaded.single.owners[noSeedKeyPathIndex].isSeedStored, isFalse);
        expect(loaded.single.owners[noSeedKeyPathIndex].isPassphraseSet, isFalse);
        expect(loaded.single.owners[noSeedKeyPathIndex].type, TaprootParticipantType.keyPath);
        expect(loaded.single.beneficiaries.first.isSeedStored, isTrue);
        expect(loaded.single.beneficiaries.first.isPassphraseSet, isTrue);
        expect(loaded.single.beneficiaries.first.type, TaprootParticipantType.beneficiary);
        expect(loaded.single.beneficiaries.first.lockTime, 500000000);
      },
    );

    test(
      'SigningOnly / stored key-path owner, external key-path owner, and stored beneficiary / stores local secrets with passphrases',
      () async {
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
        expect(result.scriptPathSeedInfos, hasLength(1));
        expect(result.owners, hasLength(2));
        expect(result.beneficiaries, hasLength(1));
        final seedStoredKeyPathIndex = result.owners.indexWhere((p) => p.isSeedStored);
        final noSeedKeyPathIndex = result.owners.indexWhere((p) => !p.isSeedStored);
        expect(result.owners[seedStoredKeyPathIndex].isSeedStored, isTrue);
        expect(result.owners[seedStoredKeyPathIndex].isPassphraseSet, isTrue);
        expect(result.owners[seedStoredKeyPathIndex].type, TaprootParticipantType.keyPath);
        expect(result.owners[noSeedKeyPathIndex].isSeedStored, isFalse);
        expect(result.owners[noSeedKeyPathIndex].isPassphraseSet, isFalse);
        expect(result.owners[noSeedKeyPathIndex].type, TaprootParticipantType.keyPath);
        expect(result.beneficiaries.first.isSeedStored, isTrue);
        expect(result.beneficiaries.first.isPassphraseSet, isTrue);
        expect(result.beneficiaries.first.type, TaprootParticipantType.beneficiary);
        expect(result.beneficiaries.first.masterFingerprint, isNotEmpty);

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
      },
    );

    test(
      'SecureStorage / stored key-path owner and stored beneficiary / reloads inheritance wallet from a new repository',
      () async {
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

        await reloadedRepository.loadAndEmitEachWallet(
          jsonList!,
          (wallet) => loaded.add(wallet as TaprootVaultListItem),
        );

        expect(loaded, hasLength(1));
        expect(reloadedRepository.vaultList, hasLength(1));
        expect(loaded.single.id, added.id);
        expect(loaded.single.name, 'taproot inheritance wallet');
        expect(loaded.single.vaultType, WalletType.taproot);
        expect(loaded.single.descriptor, added.descriptor);
        expect(loaded.single.keyPathSeedInfos, hasLength(1));
        expect(loaded.single.scriptPathSeedInfos, hasLength(1));
        expect(
          loaded.single.keyPathSeedInfos.single.extendedPublicKey,
          added.keyPathSeedInfos.single.extendedPublicKey,
        );
        expect(
          loaded.single.scriptPathSeedInfos.single.seedInfos.single.extendedPublicKey,
          added.scriptPathSeedInfos.single.seedInfos.single.extendedPublicKey,
        );

        expect(loaded.single.owners, hasLength(1));
        expect(loaded.single.beneficiaries, hasLength(1));
        final seedStoredKeyPathIndex = loaded.single.owners.indexWhere((p) => p.isSeedStored);
        final noSeedKeyPathIndex = loaded.single.owners.indexWhere((p) => !p.isSeedStored);
        expect(seedStoredKeyPathIndex, equals(0));
        expect(noSeedKeyPathIndex, -1);
        expect(loaded.single.owners[seedStoredKeyPathIndex].isSeedStored, isTrue);
        expect(loaded.single.owners[seedStoredKeyPathIndex].isPassphraseSet, isTrue);
        expect(loaded.single.owners[seedStoredKeyPathIndex].type, TaprootParticipantType.keyPath);
        expect(loaded.single.beneficiaries.first.isSeedStored, isTrue);
        expect(loaded.single.beneficiaries.first.isPassphraseSet, isFalse);
        expect(loaded.single.beneficiaries.first.type, TaprootParticipantType.beneficiary);
        expect(loaded.single.beneficiaries.first.lockTime, 500000000);
      },
    );

    test(
      'SecureStorage / stored key-path owner and stored beneficiary / deletes reloaded wallet secrets, privacy info, and seed index',
      () async {
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

        final TaprootVaultListItem added = await repository.addTaprootWallet(walletCreateDto);
        final reloadedRepository = WalletRepository(storageService: storage, secureZoneRepository: secureZone);
        final jsonList = await reloadedRepository.loadVaultListJsonArrayString();

        await reloadedRepository.loadAndEmitEachWallet(jsonList!, (_) {});

        final keyPathSeedKey = WalletStorageKeys.taprootSeedKey(
          added.id,
          added.keyPathSeedInfos.single.extendedPublicKey,
        );
        final beneficiarySeedKey = WalletStorageKeys.taprootSeedKey(
          added.id,
          added.scriptPathSeedInfos.single.seedInfos.single.extendedPublicKey,
        );
        final walletKey = WalletStorageKeys.walletKey(added.id, WalletType.taproot);
        final privacyInfoKey = WalletStorageKeys.privacyInfoKey(walletKey);
        final seedIndexKey = WalletStorageKeys.taprootSeedIndexKey(added.id);

        final deleted = await reloadedRepository.deleteWallet(added.id);

        expect(deleted, isTrue);
        expect(reloadedRepository.vaultList, isEmpty);
        expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), '[]');
        expect(storage.deletedKeys, contains(keyPathSeedKey));
        expect(storage.deletedKeys, contains(beneficiarySeedKey));
        expect(storage.deletedKeys, contains(privacyInfoKey));
        expect(storage.deletedKeys, contains(seedIndexKey));
        expect(secureZone.deletedAliases, contains(keyPathSeedKey));
        expect(secureZone.deletedAliases, contains(beneficiarySeedKey));
        expect(storage.values.containsKey(keyPathSeedKey), isFalse);
        expect(storage.values.containsKey(beneficiarySeedKey), isFalse);
        expect(storage.values.containsKey(privacyInfoKey), isFalse);
        expect(storage.values.containsKey(seedIndexKey), isFalse);
      },
    );

    test(
      'SigningOnly / stored key-path owner and stored beneficiary / deletes wallet secrets and seed index',
      () async {
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
          added.keyPathSeedInfos.single.extendedPublicKey,
        );
        final beneficiarySeedKey = WalletStorageKeys.taprootSeedKey(
          added.id,
          added.scriptPathSeedInfos.single.seedInfos.single.extendedPublicKey,
        );
        final seedIndexKey = WalletStorageKeys.taprootSeedIndexKey(added.id);

        final deleted = await repository.deleteWallet(added.id);

        expect(deleted, isTrue);
        expect(repository.vaultList, isEmpty);
        expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), isEmpty);
        expect(storage.deletedKeys, contains(keyPathSeedKey));
        expect(storage.deletedKeys, contains(beneficiarySeedKey));
        expect(storage.deletedKeys, contains(seedIndexKey));
        expect(secureZone.deletedAliases, contains(keyPathSeedKey));
        expect(secureZone.deletedAliases, contains(beneficiarySeedKey));
        expect(storage.values.containsKey(keyPathSeedKey), isFalse);
        expect(storage.values.containsKey(beneficiarySeedKey), isFalse);
        expect(storage.values.containsKey(seedIndexKey), isFalse);
      },
    );

    test(
      'SecureStorage / stored key-path owner, external key-path owner, and stored beneficiary / resetAll clears secrets and public metadata',
      () async {
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
          added.keyPathSeedInfos.single.extendedPublicKey,
        );
        final beneficiarySeedKey = WalletStorageKeys.taprootSeedKey(
          added.id,
          added.scriptPathSeedInfos.single.seedInfos.single.extendedPublicKey,
        );

        expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), isNotEmpty);

        await repository.resetAll();

        expect(storage.values, isEmpty);
        expect(secureZone.deletedAliases, hasLength(2));
        expect(secureZone.deletedAliases, contains(keyPathSeedKey));
        expect(secureZone.deletedAliases, contains(beneficiarySeedKey));
        expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), isEmpty);
        expect(SharedPrefsRepository().getInt(SharedPrefsKeys.kNextIdField), isNull);
      },
    );

    test(
      'SigningOnly / stored key-path owner and stored beneficiary / resetAll clears secrets and id counter',
      () async {
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
          added.keyPathSeedInfos.single.extendedPublicKey,
        );
        final beneficiarySeedKey = WalletStorageKeys.taprootSeedKey(
          added.id,
          added.scriptPathSeedInfos.single.seedInfos.single.extendedPublicKey,
        );
        expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), isEmpty);
        expect(SharedPrefsRepository().getInt(SharedPrefsKeys.kNextIdField), isNotNull);

        await repository.resetAll();

        expect(storage.values, isEmpty);
        expect(secureZone.deletedAliases, contains(keyPathSeedKey));
        expect(secureZone.deletedAliases, contains(beneficiarySeedKey));
        expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), isEmpty);
        expect(SharedPrefsRepository().getInt(SharedPrefsKeys.kNextIdField), isNull);
      },
    );

    test(
      'SecureStorage / stored key-path owner only / rolls back secret writes when privacy info write fails',
      () async {
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
      },
    );

    /// isolate에서 만들어진 save 모델의 (xpub / scriptKey) ↔ secret 매핑이
    /// 입력 SeedSource 그대로 짝지어지는지 확인. index 정합성이 깨지면 이 테스트가 잡아낸다.
    test(
      'SecureStorage / multiple stored key-path owners and beneficiaries / maps each save model to its derived xpub or scriptKey',
      () async {
        final storage = _FakeSecureStorageRepository();
        final secureZone = _FakeSecureZoneRepository();
        final repository = WalletRepository(storageService: storage, secureZoneRepository: secureZone);

        final keyPathSeedA = _seedSource(
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
          'kp-a',
        );
        final keyPathSeedB = _seedSource(
          'legal winner thank year wave sausage worth useful legal winner thank yellow',
          '', // passphrase 없음 → save 모델에서 null 정규화 경로 검증
        );
        final beneficiarySeedA = _seedSource(
          'letter advice cage absurd amount doctor acoustic avoid letter advice cage above',
          'bn-a',
        );
        final beneficiarySeedB = _seedSource('zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong', 'bn-b');

        final walletCreateDto = TaprootWalletCreateDto(
          null,
          'taproot multi-seed mapping',
          1,
          2,
          [keyPathSeedA, keyPathSeedB],
          null,
          [
            InheritanceLeaf(secret: beneficiarySeedA, lockTime: 500000000),
            InheritanceLeaf(secret: beneficiarySeedB, lockTime: 500000001),
          ],
        );

        final added = await repository.addTaprootWallet(walletCreateDto);

        // 각 입력 seed에서 독립적으로 xpub을 재유도하여 strategy가 사용한 storage key를 예측한다.
        void expectSeedStoredAt(String storageKey, Uint8List expectedSecret) {
          final plaintext = secureZone.encryptedPlaintexts[storageKey];
          expect(plaintext, isNotNull, reason: 'no encrypted payload at $storageKey');
          final payload = SecureZonePayloadCodec.parsePlaintext(plaintext!);
          expect(payload.secret, expectedSecret);
        }

        String xpubOf(SeedSource s) =>
            KeyStore.fromSeed(
              Seed.fromMnemonic(s.mnemonic, passphrase: s.passphrase),
              AddressType.p2tr,
            ).extendedPublicKey.serialize();

        final kpAKey = WalletStorageKeys.taprootSeedKey(added.id, xpubOf(keyPathSeedA));
        final kpBKey = WalletStorageKeys.taprootSeedKey(added.id, xpubOf(keyPathSeedB));
        expectSeedStoredAt(kpAKey, keyPathSeedA.mnemonic);
        expectSeedStoredAt(kpBKey, keyPathSeedB.mnemonic);

        final bnAKey = WalletStorageKeys.taprootSeedKey(added.id, xpubOf(beneficiarySeedA));
        final bnBKey = WalletStorageKeys.taprootSeedKey(added.id, xpubOf(beneficiarySeedB));
        expectSeedStoredAt(bnAKey, beneficiarySeedA.mnemonic);
        expectSeedStoredAt(bnBKey, beneficiarySeedB.mnemonic);

        // 네 시드가 모두 인덱스에 등록되었는지도 확인 (롤백 등 후속 정리에서 사용됨).
        final indexJson = storage.values[WalletStorageKeys.taprootSeedIndexKey(added.id)];
        expect(indexJson, isNotNull);
        final keys = List<String>.from(jsonDecode(indexJson!));
        expect(keys, containsAll([kpAKey, kpBKey, bnAKey, bnBKey]));
      },
    );

    /// secret-bearing leaves에 대해서만 scriptPath save 모델이 생성되는지.
    test(
      'SecureStorage / stored key-path owner, external beneficiary, and stored beneficiary / saves only secret-bearing script paths',
      () async {
        final storage = _FakeSecureStorageRepository();
        final secureZone = _FakeSecureZoneRepository();
        final repository = WalletRepository(storageService: storage, secureZoneRepository: secureZone);

        final keyPathSeed = _seedSource(
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
          '',
        );
        // 외부 beneficiary는 descriptor-only로 들어온다 → scriptPath save 모델 생성 X.
        final externalBeneficiary = _externalInheritancePolicyDescriptor(
          'legal winner thank year wave sausage worth useful legal winner thank yellow',
          '',
          500000000,
        );
        final ownBeneficiarySeed = _seedSource(
          'letter advice cage absurd amount doctor acoustic avoid letter advice cage above',
          'bn',
        );

        final walletCreateDto = TaprootWalletCreateDto(
          null,
          'taproot mixed inheritance',
          1,
          2,
          [keyPathSeed],
          null,
          [
            InheritanceLeaf(descriptor: externalBeneficiary, lockTime: 500000000),
            InheritanceLeaf(secret: ownBeneficiarySeed, lockTime: 500000001),
          ],
        );

        final added = await repository.addTaprootWallet(walletCreateDto);

        // SZR에는 keyPath seed 1개 + ownBeneficiarySeed 1개 = 2개만 저장되어야 한다.
        expect(secureZone.generatedAliases, hasLength(2));
        expect(secureZone.encryptedPlaintexts, hasLength(2));

        // ownBeneficiarySeed가 정확한 storage key에 들어갔는지.
        final ks = KeyStore.fromSeed(
          Seed.fromMnemonic(ownBeneficiarySeed.mnemonic, passphrase: ownBeneficiarySeed.passphrase),
          AddressType.p2tr,
        );
        final ownKey = WalletStorageKeys.taprootSeedKey(added.id, ks.extendedPublicKey.serialize());
        expect(secureZone.encryptedPlaintexts.keys, contains(ownKey));
      },
    );

    test(
      'SecureStorage / stored key-path owner and stored beneficiary / getTaprootSecret returns both local secrets',
      () async {
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

        final added = await repository.addTaprootWallet(walletCreateDto);
        final keyPathSecret = await repository.getTaprootSecret(added.id, added.owners.single.seedKeyIdentifier);
        final scriptPathSecret = await repository.getTaprootSecret(
          added.id,
          added.beneficiaries.single.seedKeyIdentifier,
        );

        expect(keyPathSecret, keyPathSeed.mnemonic);
        expect(scriptPathSecret, beneficiarySeed.mnemonic);
      },
    );

    test(
      'SigningOnly / stored key-path owner and stored beneficiary / getTaprootSeedInSigningOnlyMode restores seeds with passphrases',
      () async {
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

        final added = await repository.addTaprootWallet(walletCreateDto);
        final restoredSeed = await repository.getTaprootSeedInSigningOnlyMode(
          added.id,
          added.owners.single.seedKeyIdentifier,
        );
        final restoredKeyStore = KeyStore.fromSeed(restoredSeed, AddressType.p2tr);
        final expectedKeyStore = KeyStore.fromSeed(
          Seed.fromMnemonic(keyPathSeed.mnemonic, passphrase: keyPathSeed.passphrase),
          AddressType.p2tr,
        );

        expect(restoredKeyStore.extendedPublicKey.serialize(), expectedKeyStore.extendedPublicKey.serialize());

        final restoredBeneficiarySeed = await repository.getTaprootSeedInSigningOnlyMode(
          added.id,
          added.beneficiaries.single.seedKeyIdentifier,
        );
        final restoredBeneficiaryKeyStore = KeyStore.fromSeed(restoredBeneficiarySeed, AddressType.p2tr);
        final expectedBeneficiaryKeyStore = KeyStore.fromSeed(
          Seed.fromMnemonic(beneficiarySeed.mnemonic, passphrase: beneficiarySeed.passphrase),
          AddressType.p2tr,
        );

        expect(
          restoredBeneficiaryKeyStore.extendedPublicKey.serialize(),
          expectedBeneficiaryKeyStore.extendedPublicKey.serialize(),
        );
      },
    );
  });

  group('WalletRepository test when changing mode (taproot)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SharedPrefsRepository().init();
    });

    test(
      'SigningOnly -> SecureStorage / two taproot wallets / migrates only stored seed infos and drops passphrases',
      () async {
        final storage = _FakeSecureStorageRepository();
        final secureZone = _FakeSecureZoneRepository();
        final repository = WalletRepository(
          isSigningOnlyMode: true,
          storageService: storage,
          secureZoneRepository: secureZone,
        );

        final firstKeyPathSeed = _seedSource(
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
          'first-key-passphrase',
        );
        final firstBeneficiarySeed = _seedSource(
          'letter advice cage absurd amount doctor acoustic avoid letter advice cage above',
          'first-beneficiary-passphrase',
        );
        final firstExternalKeyPathSigner = _taprootSignerBsms(
          'legal winner thank year wave sausage worth useful legal winner thank yellow',
          'external-key-passphrase',
        );
        final secondKeyPathSeed = _seedSource(
          'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong',
          'second-key-passphrase',
        );
        final secondExternalBeneficiary = _externalInheritancePolicyDescriptor(
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
          'external-beneficiary-passphrase',
          500000001,
        );

        final firstWallet = await repository.addTaprootWallet(
          TaprootWalletCreateDto(
            null,
            'taproot with stored beneficiary',
            1,
            2,
            [firstKeyPathSeed],
            [firstExternalKeyPathSigner],
            [InheritanceLeaf(secret: firstBeneficiarySeed, lockTime: 500000000)],
          ),
        );
        final secondWallet = await repository.addTaprootWallet(
          TaprootWalletCreateDto(
            null,
            'taproot with external beneficiary',
            3,
            4,
            [secondKeyPathSeed],
            null,
            [InheritanceLeaf(descriptor: secondExternalBeneficiary, lockTime: 500000001)],
          ),
        );

        // 전환 전: signing-only 모드는 공개 vault list를 저장하지 않고, seed payload에 passphrase를 함께 보관한다.
        // 첫 번째 지갑은 local key-path + external key-path + local beneficiary 구성이다.
        // 두 번째 지갑은 local key-path + descriptor-only beneficiary 구성이라 scriptPathSeedInfo가 없어야 한다.
        expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), isEmpty);
        expect(firstWallet.keyPathSeedInfos, hasLength(1));
        expect(firstWallet.scriptPathSeedInfos, hasLength(1));
        expect(firstWallet.owners, hasLength(2));
        expect(firstWallet.beneficiaries, hasLength(1));
        expect(secondWallet.keyPathSeedInfos, hasLength(1));
        expect(secondWallet.scriptPathSeedInfos, isEmpty);
        expect(secondWallet.owners, hasLength(1));
        expect(secondWallet.beneficiaries, hasLength(1));
        expect(secondWallet.beneficiaries.single.isSeedStored, isFalse);

        // signing-only에서 secure-storage 모드로 전환하며 Taproot seed와 privacy info를 다시 저장한다.
        await repository.updateIsSigningOnlyMode(false);

        // 전환 후: secure-storage 모드는 public json을 SharedPreferences에 저장하되,
        // descriptor와 seed info 같은 privacy 필드는 public json에 포함하지 않는다.
        final publicVaultListJson = SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField);
        expect(publicVaultListJson, isNotEmpty);
        final publicVaultList = jsonDecode(publicVaultListJson) as List<dynamic>;
        expect(publicVaultList, hasLength(2));
        expect(
          publicVaultList.any(
            (json) =>
                (json as Map<String, dynamic>).containsKey(TaprootVaultListItem.fieldDescriptor) ||
                json.containsKey(TaprootVaultListItem.fieldKeyPathSeedInfos) ||
                json.containsKey(TaprootVaultListItem.fieldScriptPathSeedInfos),
          ),
          isFalse,
        );

        final firstWalletKey = WalletStorageKeys.walletKey(firstWallet.id, WalletType.taproot);
        final secondWalletKey = WalletStorageKeys.walletKey(secondWallet.id, WalletType.taproot);
        expect(storage.values.keys, contains(WalletStorageKeys.privacyInfoKey(firstWalletKey)));
        expect(storage.values.keys, contains(WalletStorageKeys.privacyInfoKey(secondWalletKey)));

        // 저장 대상 seed key를 TaprootVaultListItem의 seed info에서 계산한다.
        // seed info가 없는 external key-path signer와 descriptor-only beneficiary는 저장 대상이 아니다.
        final firstKeyPathSeedKey = WalletStorageKeys.taprootSeedKey(
          firstWallet.id,
          firstWallet.keyPathSeedInfos.single.extendedPublicKey,
        );
        final firstBeneficiarySeedKey = WalletStorageKeys.taprootSeedKey(
          firstWallet.id,
          firstWallet.scriptPathSeedInfos.single.seedInfos.single.extendedPublicKey,
        );
        final secondKeyPathSeedKey = WalletStorageKeys.taprootSeedKey(
          secondWallet.id,
          secondWallet.keyPathSeedInfos.single.extendedPublicKey,
        );

        // seed index에는 실제로 저장된 seed key만 들어가야 한다.
        // 첫 번째 지갑은 key-path 1개 + beneficiary 1개, 두 번째 지갑은 key-path 1개만 저장한다.
        final firstSeedIndex = List<String>.from(
          jsonDecode(storage.values[WalletStorageKeys.taprootSeedIndexKey(firstWallet.id)]!),
        );
        final secondSeedIndex = List<String>.from(
          jsonDecode(storage.values[WalletStorageKeys.taprootSeedIndexKey(secondWallet.id)]!),
        );
        expect(firstSeedIndex, unorderedEquals([firstKeyPathSeedKey, firstBeneficiarySeedKey]));
        expect(secondSeedIndex, unorderedEquals([secondKeyPathSeedKey]));

        void expectSecretMigratedWithoutPassphrase(String key, Uint8List expectedSecret) {
          final plaintext = secureZone.encryptedPlaintexts[key];
          expect(plaintext, isNotNull, reason: 'no encrypted payload at $key');
          final payload = SecureZonePayloadCodec.parsePlaintext(plaintext!);
          expect(payload.secret, expectedSecret);
          expect(payload.passphrase, isNull);
        }

        // secure-storage 모드로 옮긴 Taproot seed payload에는 mnemonic만 남기고 passphrase는 저장하지 않는다.
        expectSecretMigratedWithoutPassphrase(firstKeyPathSeedKey, firstKeyPathSeed.mnemonic);
        expectSecretMigratedWithoutPassphrase(firstBeneficiarySeedKey, firstBeneficiarySeed.mnemonic);
        expectSecretMigratedWithoutPassphrase(secondKeyPathSeedKey, secondKeyPathSeed.mnemonic);
        expect(
          secureZone.encryptedPlaintexts.keys,
          unorderedEquals([firstKeyPathSeedKey, firstBeneficiarySeedKey, secondKeyPathSeedKey]),
        );
        expect(storage.values.values.where((value) => value == 'true'), isEmpty);

        // 백업 키와 전환 마커는 정리되어야 한다.
        expect(storage.values.keys.where((k) => k.startsWith('appModeTransitionBackup_')), isEmpty);
        expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultModeTransitionMarker), isEmpty);
      },
    );

    test('SigningOnly -> SecureStorage / two taproot wallets / rolls back when privacy write fails', () async {
      final storage = _FakeSecureStorageRepository();
      final secureZone = _FakeSecureZoneRepository();
      final repository = WalletRepository(
        isSigningOnlyMode: true,
        storageService: storage,
        secureZoneRepository: secureZone,
      );

      final firstKeyPathSeed = _seedSource(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        'first-key-passphrase',
      );
      final firstKeyPathPassphrase = Uint8List.fromList(firstKeyPathSeed.passphrase);
      final firstBeneficiarySeed = _seedSource(
        'letter advice cage absurd amount doctor acoustic avoid letter advice cage above',
        'first-beneficiary-passphrase',
      );
      final firstBeneficiaryPassphrase = Uint8List.fromList(firstBeneficiarySeed.passphrase);
      final firstExternalKeyPathSigner = _taprootSignerBsms(
        'legal winner thank year wave sausage worth useful legal winner thank yellow',
        'external-key-passphrase',
      );
      final secondKeyPathSeed = _seedSource(
        'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong',
        'second-key-passphrase',
      );
      final secondKeyPathPassphrase = Uint8List.fromList(secondKeyPathSeed.passphrase);
      final secondExternalBeneficiary = _externalInheritancePolicyDescriptor(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        'external-beneficiary-passphrase',
        500000001,
      );

      final firstWallet = await repository.addTaprootWallet(
        TaprootWalletCreateDto(
          null,
          'taproot with stored beneficiary',
          1,
          2,
          [firstKeyPathSeed],
          [firstExternalKeyPathSigner],
          [InheritanceLeaf(secret: firstBeneficiarySeed, lockTime: 500000000)],
        ),
      );
      final secondWallet = await repository.addTaprootWallet(
        TaprootWalletCreateDto(
          null,
          'taproot with external beneficiary',
          3,
          4,
          [secondKeyPathSeed],
          null,
          [InheritanceLeaf(descriptor: secondExternalBeneficiary, lockTime: 500000001)],
        ),
      );

      // 두 번째 지갑의 privacy info 저장에서 실패하면 전환 전체가 롤백되어야 한다.
      storage.setThrowOnPrivacyWrite(true);
      await expectLater(repository.updateIsSigningOnlyMode(false), throwsStateError);

      // 원본 암호문이 복원되어 passphrase를 포함한 seed를 다시 복호화할 수 있어야 한다.
      final restoredFirstKeyPathSeed = await repository.getTaprootSeedInSigningOnlyMode(
        firstWallet.id,
        TaprootSeedKeyIdentifier(extendedPublicKey: firstWallet.keyPathSeedInfos.single.extendedPublicKey),
      );
      final restoredFirstBeneficiarySeed = await repository.getTaprootSeedInSigningOnlyMode(
        firstWallet.id,
        TaprootSeedKeyIdentifier(
          extendedPublicKey: firstWallet.scriptPathSeedInfos.single.seedInfos.single.extendedPublicKey,
        ),
      );
      final restoredSecondKeyPathSeed = await repository.getTaprootSeedInSigningOnlyMode(
        secondWallet.id,
        TaprootSeedKeyIdentifier(extendedPublicKey: secondWallet.keyPathSeedInfos.single.extendedPublicKey),
      );
      expect(restoredFirstKeyPathSeed.mnemonic, firstKeyPathSeed.mnemonic);
      expect(restoredFirstKeyPathSeed.passphrase, firstKeyPathPassphrase);
      expect(restoredFirstBeneficiarySeed.mnemonic, firstBeneficiarySeed.mnemonic);
      expect(restoredFirstBeneficiarySeed.passphrase, firstBeneficiaryPassphrase);
      expect(restoredSecondKeyPathSeed.mnemonic, secondKeyPathSeed.mnemonic);
      expect(restoredSecondKeyPathSeed.passphrase, secondKeyPathPassphrase);

      // 보안저장모드 전용 항목은 삭제되어야 한다.
      final firstWalletKey = WalletStorageKeys.walletKey(firstWallet.id, WalletType.taproot);
      final secondWalletKey = WalletStorageKeys.walletKey(secondWallet.id, WalletType.taproot);
      expect(storage.values.keys, isNot(contains(WalletStorageKeys.privacyInfoKey(firstWalletKey))));
      expect(storage.values.keys, isNot(contains(WalletStorageKeys.privacyInfoKey(secondWalletKey))));

      // 백업 키와 전환 마커는 정리되어야 한다.
      expect(storage.values.keys.where((k) => k.startsWith('appModeTransitionBackup_')), isEmpty);
      expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultModeTransitionMarker), isEmpty);

      // 공개 vault list는 여전히 비어 있어야 한다 (서명전용모드 상태 유지).
      expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), isEmpty);
    });

    test('SecureStorage -> SigningOnly / two taproot wallets / deletes all existing wallet data', () async {
      final storage = _FakeSecureStorageRepository();
      final secureZone = _FakeSecureZoneRepository();
      final repository = WalletRepository(storageService: storage, secureZoneRepository: secureZone);

      final firstKeyPathSeed = _seedSource(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        'first-key-passphrase',
      );
      final firstBeneficiarySeed = _seedSource(
        'letter advice cage absurd amount doctor acoustic avoid letter advice cage above',
        'first-beneficiary-passphrase',
      );
      final firstExternalKeyPathSigner = _taprootSignerBsms(
        'legal winner thank year wave sausage worth useful legal winner thank yellow',
        'external-key-passphrase',
      );
      final secondKeyPathSeed = _seedSource(
        'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong',
        'second-key-passphrase',
      );
      final secondExternalBeneficiary = _externalInheritancePolicyDescriptor(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        'external-beneficiary-passphrase',
        500000001,
      );

      final firstWallet = await repository.addTaprootWallet(
        TaprootWalletCreateDto(
          null,
          'taproot with stored beneficiary',
          1,
          2,
          [firstKeyPathSeed],
          [firstExternalKeyPathSigner],
          [InheritanceLeaf(secret: firstBeneficiarySeed, lockTime: 500000000)],
        ),
      );
      final secondWallet = await repository.addTaprootWallet(
        TaprootWalletCreateDto(
          null,
          'taproot with external beneficiary',
          3,
          4,
          [secondKeyPathSeed],
          null,
          [InheritanceLeaf(descriptor: secondExternalBeneficiary, lockTime: 500000001)],
        ),
      );

      final firstWalletKey = WalletStorageKeys.walletKey(firstWallet.id, WalletType.taproot);
      final secondWalletKey = WalletStorageKeys.walletKey(secondWallet.id, WalletType.taproot);
      final firstKeyPathSeedKey = WalletStorageKeys.taprootSeedKey(
        firstWallet.id,
        firstWallet.keyPathSeedInfos.single.extendedPublicKey,
      );
      final firstBeneficiarySeedKey = WalletStorageKeys.taprootSeedKey(
        firstWallet.id,
        firstWallet.scriptPathSeedInfos.single.seedInfos.single.extendedPublicKey,
      );
      final secondKeyPathSeedKey = WalletStorageKeys.taprootSeedKey(
        secondWallet.id,
        secondWallet.keyPathSeedInfos.single.extendedPublicKey,
      );
      final firstPrivacyInfoKey = WalletStorageKeys.privacyInfoKey(firstWalletKey);
      final secondPrivacyInfoKey = WalletStorageKeys.privacyInfoKey(secondWalletKey);
      final firstSeedIndexKey = WalletStorageKeys.taprootSeedIndexKey(firstWallet.id);
      final secondSeedIndexKey = WalletStorageKeys.taprootSeedIndexKey(secondWallet.id);

      // 전환 전: secure-storage 모드는 public vault list와 Taproot privacy info, local seed만 저장한다.
      // external key-path signer와 descriptor-only beneficiary는 seed info가 없어 저장 대상이 아니다.
      expect(repository.vaultList, hasLength(2));
      expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), isNotEmpty);
      expect(storage.values.keys, contains(firstPrivacyInfoKey));
      expect(storage.values.keys, contains(secondPrivacyInfoKey));
      expect(storage.values.keys, contains(firstSeedIndexKey));
      expect(storage.values.keys, contains(secondSeedIndexKey));
      expect(storage.values.keys, contains(firstKeyPathSeedKey));
      expect(storage.values.keys, contains(firstBeneficiarySeedKey));
      expect(storage.values.keys, contains(secondKeyPathSeedKey));

      // secure-storage에서 signing-only 모드로 전환하면 기존 지갑 목록을 모두 삭제한다.
      // 이때 지갑별 seed, seed index, privacy info, public vault list가 함께 정리되어야 한다.
      await repository.updateIsSigningOnlyMode(true);

      expect(repository.vaultList, isEmpty);
      expect(SharedPrefsRepository().getString(SharedPrefsKeys.kVaultListField), '[]');
      expect(storage.values, isEmpty);
      expect(storage.deletedKeys, contains(firstPrivacyInfoKey));
      expect(storage.deletedKeys, contains(secondPrivacyInfoKey));
      expect(storage.deletedKeys, contains(firstSeedIndexKey));
      expect(storage.deletedKeys, contains(secondSeedIndexKey));
      expect(storage.deletedKeys, contains(firstKeyPathSeedKey));
      expect(storage.deletedKeys, contains(firstBeneficiarySeedKey));
      expect(storage.deletedKeys, contains(secondKeyPathSeedKey));
      expect(secureZone.deletedAliases, contains(firstKeyPathSeedKey));
      expect(secureZone.deletedAliases, contains(firstBeneficiarySeedKey));
      expect(secureZone.deletedAliases, contains(secondKeyPathSeedKey));
      expect(secureZone.encryptedPlaintexts, isEmpty);
    });
  });

  // coconut_lib toMiniscript()에 의존하므로 라이브러리 업데이트 이후 변경되지 않았는지 확인
  group('ScriptKey 불변 확인', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SharedPrefsRepository().init();
    });

    test('Stored beneficiary / ScriptPathSeedInfo.generateKey stays stable for a recreated inheritance policy', () async {
      final storage = _FakeSecureStorageRepository();
      final secureZone = _FakeSecureZoneRepository();
      final repository = WalletRepository(storageService: storage, secureZoneRepository: secureZone);
      final keyPathSeed = _seedSource(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        '',
      );
      final beneficiarySeed = _seedSource(
        'legal winner thank year wave sausage worth useful legal winner thank yellow',
        'beneficiary-passphrase',
      );
      const lockTime = 500000000;
      final walletCreateDto = TaprootWalletCreateDto(
        null,
        'taproot script key stability',
        1,
        2,
        [keyPathSeed],
        null,
        [InheritanceLeaf(secret: beneficiarySeed, lockTime: lockTime)],
      );

      final added = await repository.addTaprootWallet(walletCreateDto);
      final storedScriptPathSeedInfo = added.scriptPathSeedInfos.single;
      final beneficiaryKeyStore = KeyStore.fromSeed(
        Seed.fromMnemonic(beneficiarySeed.mnemonic, passphrase: beneficiarySeed.passphrase),
        AddressType.p2tr,
      );
      final beneficiaryDescriptor = TaprootVault.fromKeyStoreList([beneficiaryKeyStore], []).descriptor;
      final recreatedPolicyA = InheritancePolicy.fromDescriptorAndLocktime(beneficiaryDescriptor, lockTime);
      final recreatedPolicyB = InheritancePolicy.fromDescriptorAndLocktime(beneficiaryDescriptor, lockTime);
      final differentPolicy = InheritancePolicy.fromDescriptorAndLocktime(beneficiaryDescriptor, lockTime + 1);
      final scriptKeyA = ScriptPathSeedInfo.generateKey(recreatedPolicyA);
      final scriptKeyB = ScriptPathSeedInfo.generateKey(recreatedPolicyB);
      final expectedStorageKey = WalletStorageKeys.taprootSeedKey(
        added.id,
        beneficiaryKeyStore.extendedPublicKey.serialize(),
      );

      final scriptKeyC = ScriptPathSeedInfo.generateKey(differentPolicy);
      expect(
        recreatedPolicyA.toMiniscript(),
        "and_v(v:pk([70C4E9DE/86'/1'/0']tpubDCp2emt17Ng6ujD8BC6ScL4vfwhN3nAJQ8kCqLjRQHxcFhWt6YK5Ws6UcKD6HgLCZuwU8DryKo7h2gpieLa7Q9YF1AqfL9XiF7349nHaLi8/<0;1>/*),older(500000000))",
      );
      expect(scriptKeyA, '0f4b50131aa61179141f7475d9cf74339a1ecd5f760d2e1ca7bb8c57e0ead4eb');
      expect(scriptKeyA, scriptKeyB);
      expect(scriptKeyA, added.beneficiaries.single.scriptKey);
      expect(scriptKeyA, storedScriptPathSeedInfo.key);
      expect(scriptKeyC, '890b2a8bedc5da899ca0a49a57819c71bc6490ec6dfe0a5b5e35f2cfa52bb618');
      expect(secureZone.encryptedPlaintexts.keys, contains(expectedStorageKey));
    });
  });
}

/// 외부 beneficiary 시뮬레이션: 시드로부터 single-sig taproot descriptor를 만들어
/// descriptor-only 모드로 들어오는 InheritanceLeaf 입력을 흉내낸다.
/// 입력 시점에는 lockTime이 따로 전달되므로 descriptor에 lockTime을 합칠 필요는 없다.
String _externalInheritancePolicyDescriptor(String mnemonic, String passphrase, int lockTime) {
  final ks = KeyStore.fromSeed(
    Seed.fromMnemonic(
      Uint8List.fromList(utf8.encode(mnemonic)),
      passphrase: Uint8List.fromList(utf8.encode(passphrase)),
    ),
    AddressType.p2tr,
  );
  return TaprootVault.fromKeyStoreList([ks], []).descriptor;
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
  bool throwOnPrivacyWrite;
  final Map<String, String> values = {};
  final List<String> deletedKeys = [];

  _FakeSecureStorageRepository({this.throwOnPrivacyWrite = false});

  void setThrowOnPrivacyWrite(bool value) => throwOnPrivacyWrite = value;

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
  final Map<String, Uint8List> _ciphertextToPlaintext = {};
  final List<String> deletedAliases = [];

  @override
  Future<void> generateKey({required String alias, bool userAuthRequired = false, bool perUseAuth = false}) async {
    generatedAliases.add(alias);
  }

  @override
  Future<void> deleteKey({required String alias}) async {
    deletedAliases.add(alias);
    encryptedPlaintexts.remove(alias);
  }

  @override
  Future<void> deleteKeys({required List<String> aliasList}) async {
    deletedAliases.addAll(aliasList);
    for (final alias in aliasList) {
      encryptedPlaintexts.remove(alias);
    }
  }

  @override
  Future<EncryptResult> encrypt({required String alias, required Uint8List plaintext}) async {
    encryptedPlaintexts[alias] = plaintext;
    final ciphertext = Uint8List.fromList(base64Encode(plaintext).codeUnits);
    _ciphertextToPlaintext[base64Encode(ciphertext)] = plaintext;
    return EncryptResult(ciphertext: ciphertext, iv: Uint8List.fromList([4, 5, 6]), extra: null);
  }

  @override
  Future<Uint8List?> decrypt({
    required String alias,
    required Uint8List ciphertext,
    required Uint8List iv,
    bool autoAuth = true,
  }) async {
    return _ciphertextToPlaintext[base64Encode(ciphertext)];
  }
}
