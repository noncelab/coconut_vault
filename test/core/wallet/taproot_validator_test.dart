import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/core/wallet/taproot_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    NetworkType.setNetworkType(NetworkType.mainnet);
  });

  group('TaprootValidator.validateSignerBsms', () {
    test('validates P2TR signer BSMS data', () {
      final keyStore = _randomTaprootKeyStore();
      final signerBsms = _signerBsmsFromKeyStore(keyStore);

      final validatedKeyStore = TaprootValidator.validateSignerBsms(signerBsms);

      expect(validatedKeyStore.masterFingerprint, keyStore.masterFingerprint);
      expect(validatedKeyStore.extendedPublicKey.serialize(), keyStore.extendedPublicKey.serialize());
    });

    test('throws when signer derivation path is not P2TR', () {
      final keyStore = _randomTaprootKeyStore();
      final invalidSignerBsms =
          Bsms.fromSigner(
            keyStore.masterFingerprint,
            "84'/0'/0'",
            keyStore.extendedPublicKey.serialize(),
            '',
          ).serializeSigner();

      expect(() => TaprootValidator.validateSignerBsms(invalidSignerBsms), throwsA(isA<FormatException>()));
    });
  });

  group('TaprootValidator.hasMatchingExtendedPublicKeyInDescriptors', () {
    test('returns true when descriptors contain the same extended public key', () {
      final keyStore = _randomTaprootKeyStore();
      final leftDescriptor = TaprootVault.fromKeyStoreList([keyStore], []).descriptor;
      final rightDescriptor = TaprootVault.fromKeyStoreList([keyStore], []).descriptor;

      final isMatched = TaprootValidator.hasMatchingExtendedPublicKeyInDescriptors(leftDescriptor, rightDescriptor);

      expect(isMatched, isTrue);
    });

    test('returns false when descriptors do not share extended public keys', () {
      final leftDescriptor = TaprootVault.fromKeyStoreList([_randomTaprootKeyStore()], []).descriptor;
      final rightDescriptor = TaprootVault.fromKeyStoreList([_randomTaprootKeyStore()], []).descriptor;

      final isMatched = TaprootValidator.hasMatchingExtendedPublicKeyInDescriptors(leftDescriptor, rightDescriptor);

      expect(isMatched, isFalse);
    });
  });

  group('TaprootValidator.validateInheritanceDescriptor', () {
    test('validates inheritance descriptor with up to two parents and one child', () {
      final fixture = _inheritanceFixture(parentCount: 2);

      final vault = TaprootValidator.parseInheritanceVaultDescriptor(fixture.descriptor);

      expect(vault.keyStoreList.length, 2);
      expect(vault.policyList.whereType<InheritancePolicy>().length, 1);
    });

    test('throws when descriptor has more than two parents', () {
      final fixture = _inheritanceFixture(parentCount: 3);

      expect(() => TaprootValidator.parseInheritanceVaultDescriptor(fixture.descriptor), throwsA(isA<FormatException>()));
    });

    test('throws when descriptor has no child inheritance policy', () {
      final descriptor = TaprootVault.fromKeyStoreList([_randomTaprootKeyStore()], []).descriptor;

      expect(() => TaprootValidator.parseInheritanceVaultDescriptor(descriptor), throwsA(isA<FormatException>()));
    });
  });

  group('TaprootValidator.isInheritanceDescriptorChildMatched', () {
    test('returns true when descriptor child matches generated child P2TR signer BSMS', () {
      final fixture = _inheritanceFixture(parentCount: 2);
      final childSignerBsms = _signerBsmsFromKeyStore(fixture.childKeyStore);

      final isMatched = TaprootValidator.isInheritanceDescriptorChildMatched(
        inheritanceDescriptor: fixture.descriptor,
        childSignerBsms: childSignerBsms,
      );

      expect(isMatched, isTrue);
    });

    test('returns false when descriptor child does not match generated child P2TR signer BSMS', () {
      final fixture = _inheritanceFixture(parentCount: 2);
      final otherChildSignerBsms = _signerBsmsFromKeyStore(_randomTaprootKeyStore());

      final isMatched = TaprootValidator.isInheritanceDescriptorChildMatched(
        inheritanceDescriptor: fixture.descriptor,
        childSignerBsms: otherChildSignerBsms,
      );

      expect(isMatched, isFalse);
    });

    test('matches child descriptor through helper', () {
      final fixture = _inheritanceFixture(parentCount: 2);
      final childDescriptor = TaprootVault.fromKeyStoreList([fixture.childKeyStore], []).descriptor;

      final isMatched = TaprootValidator.isInheritanceDescriptorChildDescriptorMatched(
        inheritanceDescriptor: fixture.descriptor,
        childDescriptor: childDescriptor,
      );

      expect(isMatched, isTrue);
    });
  });
}

({String descriptor, KeyStore childKeyStore}) _inheritanceFixture({required int parentCount}) {
  final parents = List.generate(parentCount, (_) => _randomTaprootKeyStore());
  final childKeyStore = _randomTaprootKeyStore();
  final descriptor = TaprootVault.fromKeyStoreList(parents, [InheritancePolicy(childKeyStore, 1779863880)]).descriptor;

  return (descriptor: descriptor, childKeyStore: childKeyStore);
}

KeyStore _randomTaprootKeyStore() {
  return KeyStore.random(AddressType.p2tr);
}

String _signerBsmsFromKeyStore(KeyStore keyStore) {
  return Bsms.fromSigner(
    keyStore.masterFingerprint,
    WalletUtility.getDerivationPath(AddressType.p2tr, 0).replaceAll('m/', ''),
    keyStore.extendedPublicKey.serialize(),
    '',
  ).serializeSigner();
}
