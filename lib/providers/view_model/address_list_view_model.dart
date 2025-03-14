import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/common/wallet_address.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/material.dart';

class AddressListViewModel extends ChangeNotifier {
  static const int kAddressFetchCount = 20;

  late int _receivingAddressPage;
  late int _changeAddressPage;
  late bool _isReceivingSelected;
  late List<WalletAddress> _receivingAddressList;
  late List<WalletAddress> _changeAddressList;
  late VaultListItemBase _vaultListItem;
  late WalletBase _coconutVault;

  AddressListViewModel(WalletProvider walletProvider, int id) {
    _receivingAddressPage = 0;
    _changeAddressPage = 0;
    _isReceivingSelected = true;
    _vaultListItem = walletProvider.getVaultById(id);
    _coconutVault = _vaultListItem.coconutVault;

    _receivingAddressList = _getAddressList(0, kAddressFetchCount, false);
    _changeAddressList = _getAddressList(0, kAddressFetchCount, true);
  }

  int get changeAddressPage => _changeAddressPage;
  int get receivingAddressPage => _receivingAddressPage;
  bool get isReceivingSelected => _isReceivingSelected;
  String get name => _vaultListItem.name;
  List<WalletAddress> get receivingAddressList => _receivingAddressList;
  List<WalletAddress> get changeAddressList => _changeAddressList;

  List<WalletAddress> _getAddressList(
      int startIndex, int count, bool isChange) {
    List<WalletAddress> result = [];
    for (int i = startIndex; i < startIndex + count; i++) {
      result.add(_generateAddress(_coconutVault, i, isChange));
    }

    return result;
  }

  /// 단일 주소 생성
  WalletAddress _generateAddress(WalletBase wallet, int index, bool isChange) {
    String address = wallet.getAddress(index, isChange: isChange);
    String derivationPath =
        '${wallet.derivationPath}${isChange ? '/1' : '/0'}/$index';

    return WalletAddress(
      address,
      derivationPath,
      index,
    );
  }

  void nextLoad() {
    final newAddresses = _getAddressList(
        kAddressFetchCount +
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
