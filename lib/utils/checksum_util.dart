class ChecksumUtil {
  static const String _inputCharset =
      '0123456789()[],\'/*abcdefgh@:\$%{}IJKLMNOPQRSTUVWXYZ&+-.;<=>?!^_|~ijklmnopqrstuvwxyzABCDEFGH`#"\\ ';
  static const _checksumCharset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
  static final _generator = [0xf5dee51989, 0xa9fdca3312, 0x1bab10e32d, 0x3706b1677a, 0x644d626ffd];

  static int _calculatePolyMod(List<int> symbols) {
    int chk = 1;
    for (var value in symbols) {
      var top = chk >> 35;
      chk = (chk & 0x7ffffffff) << 5 ^ value;
      for (var i = 0; i < 5; i++) {
        chk ^= ((top >> i) & 1) != 0 ? _generator[i] : 0;
      }
    }
    return chk;
  }

  static List<int> _transformSymbols(String s) {
    var groups = <int>[];
    var symbols = <int>[];
    for (var c in s.split('')) {
      if (!_inputCharset.contains(c)) {
        return [];
      }
      var v = _inputCharset.indexOf(c);
      symbols.add(v & 31);
      groups.add(v >> 5);
      if (groups.length == 3) {
        symbols.add(groups[0] * 9 + groups[1] * 3 + groups[2]);
        groups = [];
      }
    }
    if (groups.length == 1) {
      symbols.add(groups[0]);
    } else if (groups.length == 2) {
      symbols.add(groups[0] * 3 + groups[1]);
    }
    return symbols;
  }

  static bool isValidChecksum(String s) {
    if (s[s.length - 9] != '#') {
      return false;
    }
    if (!s.substring(s.length - 8).split('').every((x) => _checksumCharset.contains(x))) {
      return false;
    }
    var symbols =
        _transformSymbols(s.substring(0, s.length - 9)).toList()
          ..addAll(s.substring(s.length - 8).split('').map((x) => _checksumCharset.indexOf(x)));
    return _calculatePolyMod(symbols) == 1;
  }
}
