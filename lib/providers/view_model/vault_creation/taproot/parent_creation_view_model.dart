import 'package:flutter/foundation.dart';

enum ParentWalletType { singleSig, multisig }

class ParentCreationViewModel extends ChangeNotifier {
  ParentWalletType? _selectedWalletType;

  ParentWalletType? get selectedWalletType => _selectedWalletType;
  bool get isSingleSigSelected => _selectedWalletType == ParentWalletType.singleSig;
  bool get isMultisigSelected => _selectedWalletType == ParentWalletType.multisig;

  void toggleWalletType(ParentWalletType type) {
    _selectedWalletType = _selectedWalletType == type ? null : type;
    notifyListeners();
  }
}
