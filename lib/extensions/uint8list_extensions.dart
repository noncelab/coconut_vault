import 'dart:typed_data';

extension Uint8ListWipeX on Uint8List {
  /// Zero out the entire buffer in-place.
  void wipe() {
    if (isEmpty) return;
    fillRange(0, length, 0);
  }
}

extension NullableUint8ListWipeX on Uint8List? {
  /// Safe wipe for nullable buffers.
  void wipe() {
    final data = this;
    if (data == null || data.isEmpty) return;
    data.fillRange(0, data.length, 0);
  }
}
