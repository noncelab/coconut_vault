import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/wallet_isolates.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/common/wallet_address.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AddressListViewModel extends ChangeNotifier {
  static const int kAddressFetchCount = 20;

  late int _receivingAddressPage;
  late int _changeAddressPage;
  late bool _isReceivingSelected;
  late VaultListItemBase _vaultListItem;
  late WalletBase _coconutVault;
  late WalletProvider _walletProvider;
  List<WalletAddress>? _receivingAddressList;
  List<WalletAddress>? _changeAddressList;

  AddressListViewModel(WalletProvider walletProvider, int id) {
    _walletProvider = walletProvider;
    _isReceivingSelected = true;
    _vaultListItem = walletProvider.getVaultById(id);
    _initialize();
  }

  int get changeAddressPage => _changeAddressPage;
  int get receivingAddressPage => _receivingAddressPage;
  int get vaultId => _vaultListItem.id;
  int get vaultCount => _walletProvider.vaultList.length;
  bool get isReceivingSelected => _isReceivingSelected;
  String get name => _vaultListItem.name;
  List<WalletAddress>? get receivingAddressList => _receivingAddressList;
  List<WalletAddress>? get changeAddressList => _changeAddressList;

  Future<List<WalletAddress>> _getAddressList(int startIndex, int count, bool isChange) async {
    final result = await compute(WalletIsolates.getAddressList, {
      'startIndex': startIndex,
      'count': count,
      'isChange': isChange,
      'walletBase': _coconutVault,
    });

    return result;
  }

  void _initialize() {
    _receivingAddressPage = 0;
    _changeAddressPage = 0;
    _coconutVault = _vaultListItem.coconutVault;
  }

  Future<void> initializeAddress() async {
    _receivingAddressList = await _getAddressList(0, kAddressFetchCount, false);
    _changeAddressList = await _getAddressList(0, kAddressFetchCount, true);
  }

  Future<void> nextLoad() async {
    final newAddresses = await _getAddressList(
      kAddressFetchCount + (_isReceivingSelected ? _receivingAddressPage : _changeAddressPage) * kAddressFetchCount,
      kAddressFetchCount,
      !_isReceivingSelected,
    );
    if (_isReceivingSelected) {
      if (_receivingAddressList == null) return;
      _receivingAddressList!.addAll(newAddresses);
      _receivingAddressPage += 1;
    } else {
      if (_changeAddressList == null) return;
      _changeAddressList!.addAll(newAddresses);
      _changeAddressPage += 1;
    }
    notifyListeners();
  }

  void setReceivingSelected(bool value) {
    _isReceivingSelected = value;
    notifyListeners();
  }

  Future<void> changeVaultById(int id) async {
    _vaultListItem = _walletProvider.getVaultById(id);
    _initialize();
    await initializeAddress();
    notifyListeners();
  }
}
