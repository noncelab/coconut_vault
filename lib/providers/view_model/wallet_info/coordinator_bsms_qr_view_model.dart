import 'dart:convert';
import 'dart:typed_data';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/bb_qr/bb_qr_encoder.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/packages/bc-ur-dart/lib/cbor_lite.dart';
import 'package:ur/ur.dart';
import 'package:ur/ur_encoder.dart';

enum CoordinatorViewMode { coconutVaultOnly, backupAll }

class CoordinatorBsmsQrViewModel extends ChangeNotifier {
  late String qrData;
  Map<String, String> walletQrDataMap = {};
  Map<String, String> walletTextDataMap = {};
  late String walletName;

  CoordinatorBsmsQrViewModel(WalletProvider walletProvider, int id, {required CoordinatorViewMode mode}) {
    _init(walletProvider, id, mode);
  }

  void _init(WalletProvider walletProvider, int id, CoordinatorViewMode mode) {
    final vaultListItem = walletProvider.getVaultById(id) as MultisigVaultListItem;
    walletName = vaultListItem.name;

    _generateBsmsJson(vaultListItem);

    if (mode == CoordinatorViewMode.backupAll) {
      _generateAllFormats(vaultListItem);
    }

    notifyListeners();
  }

  void _generateBsmsJson(MultisigVaultListItem vaultListItem) {
    final coordinatorBsms = vaultListItem.coordinatorBsms;
    Map<String, dynamic> walletSyncString = jsonDecode(vaultListItem.getWalletSyncString());

    Map<String, String> namesMap = {};
    for (var signer in vaultListItem.signers) {
      namesMap[signer.keyStore.masterFingerprint] = signer.name ?? '-';
    }

    qrData = jsonEncode(
      MultisigImportDetail(
        name: walletSyncString['name'],
        colorIndex: walletSyncString['colorIndex'],
        iconIndex: walletSyncString['iconIndex'],
        namesMap: namesMap,
        coordinatorBsms: coordinatorBsms,
      ),
    );
  }

  void _generateAllFormats(MultisigVaultListItem vaultListItem) {
    String outputDescriptor = _generateDescriptor(vaultListItem);
    String bsmsText = vaultListItem.coordinatorBsms;
    String coldcardText = _generateColdcardTextFormat(vaultListItem);
    String keystoneText = _generateKeystoneTextFormat(vaultListItem);

    String bsmsUr = _encodeToUrBytes(bsmsText);
    String coldcardQr = _encodeColdcardQr(coldcardText);
    String keystoneUr = _encodeToUrBytes(keystoneText);

    walletQrDataMap = {
      'BSMS': bsmsUr,
      'BlueWallet Vault Multisig': _generateBlueWalletFormat(vaultListItem),
      'Coldcard Multisig': coldcardQr,
      'Keystone Multisig': keystoneUr,
      'Output Descriptor': outputDescriptor,
      'Specter Desktop': _generateSpecterFormat(vaultListItem, outputDescriptor),
    };

    walletTextDataMap = {
      'BSMS': bsmsText,
      'BlueWallet Vault Multisig': walletQrDataMap['BlueWallet Vault Multisig']!,
      'Coldcard Multisig': coldcardText,
      'Keystone Multisig': keystoneText,
      'Output Descriptor': outputDescriptor,
      'Specter Desktop': walletQrDataMap['Specter Desktop']!,
    };
  }

  String _encodeToUrBytes(String text) {
    try {
      Uint8List utf8Data = Uint8List.fromList(utf8.encode(text));
      final cborEncoder = CBOREncoder();
      cborEncoder.encodeBytes(utf8Data);
      final ur = UR('bytes', cborEncoder.getBytes());
      final urEncoder = UREncoder(ur, 2000);
      return urEncoder.nextPart();
    } catch (e) {
      return "Error encoding UR: $e";
    }
  }

  String _encodeColdcardQr(String text) {
    try {
      List<String> qrFragments = BbQrEncoder.encode(data: text);
      if (qrFragments.isNotEmpty) {
        return qrFragments.first;
      } else {
        return "Error: Empty QR result";
      }
    } catch (e) {
      return "Error encoding Coldcard QR: $e";
    }
  }

  String _generateKeystoneTextFormat(MultisigVaultListItem vault) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("# Keystone Multisig setup file (created by Coconut Vault)");
    buffer.writeln("#\n");
    buffer.writeln("Name: coconut vault");
    buffer.writeln("Policy: ${vault.requiredSignatureCount} of ${vault.signers.length}");

    String derivation = vault.signers.first.getSignerDerivationPath();
    if (!derivation.startsWith("m/")) derivation = "m/$derivation";
    buffer.writeln("Derivation: $derivation");
    buffer.writeln("Format: P2WSH\n");

    for (var signer in vault.signers) {
      String fingerprint = signer.keyStore.masterFingerprint.toUpperCase();
      String xpub = signer.keyStore.extendedPublicKey.serialize(toXpub: true);
      buffer.writeln("$fingerprint: $xpub");
    }

    return buffer.toString();
  }

  String _generateColdcardTextFormat(MultisigVaultListItem vault) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("Name: coconut vault");
    buffer.writeln("Policy: ${vault.requiredSignatureCount} of ${vault.signers.length}");
    buffer.writeln("Format: P2WSH");

    String path = vault.signers.first.getSignerDerivationPath();
    if (!path.startsWith('m/')) path = 'm/$path';
    path = path.trim();
    buffer.writeln("Derivation: $path");

    for (var signer in vault.signers) {
      String xpub = signer.keyStore.extendedPublicKey.serialize(toXpub: true);
      String fingerprint = signer.keyStore.masterFingerprint.toUpperCase();
      buffer.writeln("$fingerprint: $xpub");
    }

    return buffer.toString().trim();
  }

  String _generateBlueWalletFormat(MultisigVaultListItem vault) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("# Blue Wallet Vault Multisig setup file (created by Coconut Vault)\n#");
    buffer.writeln("Name: ${vault.name}");
    buffer.writeln("Policy: ${vault.requiredSignatureCount} of ${vault.signers.length}");
    buffer.writeln("Derivation: ${vault.signers.first.getSignerDerivationPath()}");
    buffer.writeln("Format: P2WSH\n");
    for (var signer in vault.signers) {
      String xpub = signer.keyStore.extendedPublicKey.serialize(toXpub: true);
      buffer.writeln("${signer.keyStore.masterFingerprint}: $xpub");
    }
    return buffer.toString();
  }

  String _generateDescriptor(MultisigVaultListItem vault) {
    String derivationPath = vault.signers.first.getSignerDerivationPath().replaceAll('m/', '').replaceAll("'", "h");

    List<String> publicKeyList =
        vault.signers.map((signer) => signer.keyStore.extendedPublicKey.serialize(toXpub: true)).toList();

    List<String> fingerprintList =
        vault.signers.map((signer) => signer.keyStore.masterFingerprint.toLowerCase()).toList();

    Descriptor descriptor = Descriptor.forMultisignature(
      AddressType.p2wsh,
      publicKeyList,
      derivationPath,
      fingerprintList,
      vault.requiredSignatureCount,
    );

    return descriptor.serialize();
  }

  String _generateSpecterFormat(MultisigVaultListItem vault, String descriptor) {
    final Map<String, dynamic> data = {"label": vault.name, "blockheight": 0, "descriptor": descriptor};
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}
