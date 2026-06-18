import 'dart:convert';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/material.dart';

class TaprootSyncQrViewModel extends ChangeNotifier {
  final WalletProvider _walletProvider;
  final int _id;
  String _qrData = '';
  bool _hasError = false;

  TaprootSyncQrViewModel(this._walletProvider, this._id) {
    _initialize();
  }

  String get qrData => _qrData;
  bool get hasError => _hasError;

  void _initialize() {
    try {
      _hasError = false;
      final vault = _walletProvider.getVaultById(_id);
      if (vault is TaprootVaultListItem) {
        final syncData = {
          'name': vault.name,
          'colorIndex': vault.colorIndex,
          'iconIndex': vault.iconIndex,
          'descriptor': vault.descriptor,
          'createdAt': vault.createdAt.toIso8601String(),
        };
        _qrData = jsonEncode(syncData);
      } else {
        _hasError = true;
      }
    } catch (e) {
      _qrData = '';
      _hasError = true;
    }
    notifyListeners();
  }
}
