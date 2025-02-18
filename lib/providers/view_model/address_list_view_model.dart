import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/material.dart';

class AddressListViewModel extends ChangeNotifier {
  static const int kFirstCount = 20;
  final WalletProvider _walletProvider;
  final int _limit = 5;

  late final int _id;
  late int _receivingAddressPage;
  late int _changeAddressPage;
  late bool _isReceivingSelected;
  late String _name;
  late List<Address> _receivingAddressList;
  late List<Address> _changeAddressList;
  late VaultListItemBase _vaultListItem;
  late WalletBase _coconutVault;

  AddressListViewModel(this._walletProvider, this._id) {
    _receivingAddressPage = 0;
    _changeAddressPage = 0;
    _isReceivingSelected = true;
    _vaultListItem = _walletProvider.getVaultById(_id);
    _coconutVault = _vaultListItem.coconutVault;
    _name = _vaultListItem.name;

    _receivingAddressList = _coconutVault.getAddressList(0, kFirstCount, false);
    _changeAddressList = _coconutVault.getAddressList(0, kFirstCount, true);
  }
  List<Address> get changeAddressList => _changeAddressList;
  int get changeAddressPage => _changeAddressPage;
  bool get isReceivingSelected => _isReceivingSelected;
  String get name => _name;
  List<Address> get receivingAddressList => _receivingAddressList;

  int get receivingAddressPage => _receivingAddressPage;

  void nextLoad() {
    final newAddresses = _coconutVault.getAddressList(
        kFirstCount +
            (_isReceivingSelected
                    ? _receivingAddressPage
                    : _changeAddressPage) *
                _limit,
        _limit,
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
