import 'dart:convert';
import 'dart:typed_data';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/packages/bc-ur-dart/lib/cbor_lite.dart';
import 'package:coconut_vault/packages/bc-ur-dart/lib/ur_encoder.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/bb_qr/bb_qr_encoder.dart';
import 'package:flutter/material.dart';
import 'package:ur/ur.dart';

class CoordinatorBsmsQrViewModel extends ChangeNotifier {
  late String qrData;
  late Map<String, String> walletQrDataMap;

  CoordinatorBsmsQrViewModel(WalletProvider walletProvider, int id) {
    _init(walletProvider, id);
  }

  void _init(WalletProvider walletProvider, int id) {
    final vaultListItem = walletProvider.getVaultById(id) as MultisigVaultListItem;
    String generatedBsms = _generateBsmsFormat(vaultListItem);
    Map<String, dynamic> walletSyncString = jsonDecode(vaultListItem.getWalletSyncString());

    Map<String, String> namesMap = {};
    for (var signer in vaultListItem.signers) {
      if (signer.name == null) continue;
      namesMap[signer.keyStore.masterFingerprint] = signer.name!;
    }

    qrData = jsonEncode(
      MultisigImportDetail(
        name: walletSyncString['name'],
        colorIndex: walletSyncString['colorIndex'],
        iconIndex: walletSyncString['iconIndex'],
        namesMap: namesMap,
        coordinatorBsms: generatedBsms,
      ),
    );

    walletQrDataMap = {
      'BSMS': generatedBsms,
      'BlueWallet Vault Multisig': _generateBlueWalletFormat(vaultListItem),
      'Coldcard Multisig': _generateColdcardCompressedFormat(vaultListItem),
      'Keystone Multisig': _generateKeystoneFormat(vaultListItem),
      'Output Descriptor': _generateDescriptor(vaultListItem),
      'Specter Desktop': _generateSpecterFormat(vaultListItem),
    };

    notifyListeners();
  }

  String _generateBsmsFormat(MultisigVaultListItem vault) {
    try {
      StringBuffer buffer = StringBuffer();
      buffer.writeln("BSMS 1.0");
      buffer.writeln("Descriptor: ${_generateDescriptor(vault)}");
      buffer.writeln("Derivation: ${vault.signers.first.getSignerDerivationPath()}");

      String bsmsText = buffer.toString();

      Uint8List utf8Data = Uint8List.fromList(utf8.encode(bsmsText));

      final cborEncoder = CBOREncoder();
      cborEncoder.encodeBytes(utf8Data);

      final ur = UR('bytes', cborEncoder.getBytes());

      final urEncoder = UREncoder(ur, 2000);

      return urEncoder.nextPart();
    } catch (e) {
      return "Error generating BSMS QR: $e";
    }
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

  String _generateColdcardCompressedFormat(MultisigVaultListItem vault) {
    try {
      StringBuffer buffer = StringBuffer();

      String safeName = vault.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      if (safeName.isEmpty) safeName = "Multisig";
      if (safeName.length > 20) safeName = safeName.substring(0, 20);
      buffer.writeln("Name: $safeName");

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

      String configText = buffer.toString().trim();

      List<String> qrFragments = BbQrEncoder.encode(data: configText);

      if (qrFragments.isNotEmpty) {
        return qrFragments.first;
      } else {
        return "error: empty result";
      }
    } catch (e) {
      return "error";
    }
  }

  String _generateKeystoneFormat(MultisigVaultListItem vault) {
    try {
      StringBuffer buffer = StringBuffer();

      buffer.writeln("# Keystone Multisig setup file (created by Coconut Vault)");
      buffer.writeln("#");
      buffer.writeln();

      String safeName = vault.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-');
      if (safeName.isEmpty) safeName = "Multisig";
      buffer.writeln("Name: $safeName");

      buffer.writeln("Policy: ${vault.requiredSignatureCount} of ${vault.signers.length}");

      String derivation = vault.signers.first.getSignerDerivationPath();
      if (!derivation.startsWith("m/")) derivation = "m/$derivation";
      buffer.writeln("Derivation: $derivation");

      buffer.writeln("Format: P2WSH");
      buffer.writeln();

      for (var signer in vault.signers) {
        String fingerprint = signer.keyStore.masterFingerprint.toUpperCase();
        String xpub = signer.keyStore.extendedPublicKey.serialize(toXpub: true);
        buffer.writeln("$fingerprint: $xpub");
      }

      String keystoneText = buffer.toString();

      Uint8List utf8Data = Uint8List.fromList(utf8.encode(keystoneText));

      final cborEncoder = CBOREncoder();
      cborEncoder.encodeBytes(utf8Data);

      final ur = UR('bytes', cborEncoder.getBytes());

      final urEncoder = UREncoder(ur, 2000);

      return urEncoder.nextPart();
    } catch (e) {
      return "Error generating Keystone QR: $e";
    }
  }

  String _generateDescriptor(MultisigVaultListItem vault) {
    List<String> keyItems =
        vault.signers.map((signer) {
          String path = signer.getSignerDerivationPath().replaceAll('m/', '').replaceAll("'", "h");
          String fingerprint = signer.keyStore.masterFingerprint;
          String xpub = signer.keyStore.extendedPublicKey.serialize(toXpub: true);

          return "[$fingerprint/$path]$xpub/<0;1>/*";
        }).toList();

    keyItems.sort();

    return "wsh(sortedmulti(${vault.requiredSignatureCount},${keyItems.join(',')}))";
  }

  String _generateSpecterFormat(MultisigVaultListItem vault) {
    final Map<String, dynamic> data = {"label": vault.name, "blockheight": 0, "descriptor": _generateDescriptor(vault)};

    const encoder = JsonEncoder.withIndent('  ');
    String jsonString = encoder.convert(data);
    jsonString = jsonString.replaceAll('“', '"').replaceAll('”', '"');

    return jsonString;
  }
}
