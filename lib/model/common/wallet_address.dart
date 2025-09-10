/// Represents an address information in a wallet.
class WalletAddress {
  final String _address;
  final String _derivationPath;
  final int _index;

  /// The address string.
  String get address => _address;

  /// The derivation path of the address.
  String get derivationPath => _derivationPath;

  /// The index of the address.
  int get index => _index;

  /// Creates a new address object.
  WalletAddress(this._address, this._derivationPath, this._index);

  /// @nodoc
  @override
  int get hashCode => address.hashCode;

  /// @nodoc
  @override
  bool operator ==(Object other) {
    if (other is! WalletAddress) {
      return false;
    } else {
      return address == other.address;
    }
  }
}
