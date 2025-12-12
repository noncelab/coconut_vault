import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/packages/bc-ur-dart/lib/bytewords.dart' as base32;
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/material.dart';

class CoordinatorBsmsQrViewModel extends ChangeNotifier {
  late String qrData;
  late Map<String, String> walletQrDataMap;

  CoordinatorBsmsQrViewModel(WalletProvider walletProvider, int id) {
    _init(walletProvider, id);
  }

  void _init(WalletProvider walletProvider, int id) {
    final vaultListItem = walletProvider.getVaultById(id) as MultisigVaultListItem;
    String coordinatorBsms = vaultListItem.coordinatorBsms;
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
        coordinatorBsms: coordinatorBsms,
      ),
    );

    walletQrDataMap = {
      'BSMS': coordinatorBsms,
      'BlueWallet Vault Multisig': _generateBlueWalletFormat(vaultListItem),
      'Coldcard Multisig': _generateColdcardCompressedFormat(vaultListItem),
      'Keystone Multisig': coordinatorBsms,
      'Output Descriptor': _generateDescriptor(vaultListItem),
      'Specter Desktop': _generateSpecterFormat(vaultListItem),
    };

    notifyListeners();
  }

  String _generateBlueWalletFormat(MultisigVaultListItem vault) {
    StringBuffer buffer = StringBuffer();

    buffer.writeln("# Blue Wallet Vault Multisig setup file (created by Coconut Vault)\n#");
    buffer.writeln("Name: ${vault.name}");
    buffer.writeln("Policy: ${vault.requiredSignatureCount} of ${vault.signers.length}");
    buffer.writeln("Format: P2WSH\n");

    for (var signer in vault.signers) {
      buffer.writeln("${signer.keyStore.masterFingerprint}: ${signer.keyStore.extendedPublicKey}");
    }

    return buffer.toString();
  }

  String _generateColdcardCompressedFormat(MultisigVaultListItem vault) {
    try {
      String textConfig = _generateBlueWalletFormat(vault);

      List<int> bytes = utf8.encode(textConfig);

      List<int> compressedBytes = gzip.encode(bytes);

      String base32String = _encodeBase32(compressedBytes);

      return "B\$$base32String";
    } catch (e) {
      print("Coldcard compression failed: $e");

      return "error";
    }
  }

  String _encodeBase32(List<int> bytes) {
    const String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    var output = StringBuffer();
    int buffer = 0;
    int bitsLeft = 0;

    for (var byte in bytes) {
      buffer = (buffer << 8) | byte;
      bitsLeft += 8;
      while (bitsLeft >= 5) {
        output.write(alphabet[(buffer >> (bitsLeft - 5)) & 0x1F]);
        bitsLeft -= 5;
      }
    }

    if (bitsLeft > 0) {
      output.write(alphabet[(buffer << (5 - bitsLeft)) & 0x1F]);
    }

    return output.toString();
  }

  String _generateDescriptor(MultisigVaultListItem vault) {
    List<String> keyItems =
        vault.signers.map((signer) {
          String path = signer.getSignerDerivationPath().replaceAll('m/', '').replaceAll("'", "h");
          String fingerprint = signer.keyStore.masterFingerprint;
          String xpub = signer.keyStore.extendedPublicKey.toString();

          return "[$fingerprint/$path]$xpub";
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
