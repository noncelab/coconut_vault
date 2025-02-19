import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/material.dart';

class AddressListViewModel extends ChangeNotifier {
  static const int kFirstCount = 20;
  static const int kAddressFetchCount = 20;
  final WalletProvider _walletProvider;

  late int _receivingAddressPage;
  late int _changeAddressPage;
  late bool _isReceivingSelected;
  late List<Address> _receivingAddressList;
  late List<Address> _changeAddressList;
  late VaultListItemBase _vaultListItem;
  late WalletBase _coconutVault;

  AddressListViewModel(this._walletProvider, id) {
    _receivingAddressPage = 0;
    _changeAddressPage = 0;
    _isReceivingSelected = true;
    _vaultListItem = _walletProvider.getVaultById(id);
    _coconutVault = _vaultListItem.coconutVault;

    _receivingAddressList = _coconutVault.getAddressList(0, kFirstCount, false);
    _changeAddressList = _coconutVault.getAddressList(0, kFirstCount, true);
  }
  int get changeAddressPage => _changeAddressPage;
  int get receivingAddressPage => _receivingAddressPage;
  bool get isReceivingSelected => _isReceivingSelected;
  String get name => _vaultListItem.name;
  List<Address> get receivingAddressList => _receivingAddressList;
  List<Address> get changeAddressList => _changeAddressList;

  void nextLoad() {
    final newAddresses = _coconutVault.getAddressList(
        kFirstCount +
            (_isReceivingSelected
                    ? _receivingAddressPage
                    : _changeAddressPage) *
                kAddressFetchCount,
        kAddressFetchCount,
        !_isReceivingSelected);
    if (_isReceivingSelected) {
      _receivingAddressList.addAll(newAddresses);
      _receivingAddressPage += 1;
    } else {
      _changeAddressList.addAll(newAddresses);
      _changeAddressPage += 1;
    }
    notifyListeners();
  }

  void setReceivingSelected(bool value) {
    _isReceivingSelected = value;
    notifyListeners();
  }
}
