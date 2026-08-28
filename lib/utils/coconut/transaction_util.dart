import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/utils/hex_util.dart';

const String rawTxVersion1Field = '01000000';
const String rawTxVersion2Field = '02000000';
const String rawTxSegwitField = '0001';

/// Compares two Transaction objects for equality.
/// Checks transaction hash, input/output counts, and serialized inputs/outputs.
bool isSameTransactionBody(Transaction tx1, Transaction tx2) {
  if (tx1.transactionHash != tx2.transactionHash) {
    return false;
  }
  if (tx1.outputs.length != tx2.outputs.length || tx1.inputs.length != tx2.inputs.length) {
    return false;
  }
  for (int i = 0; i < tx1.outputs.length; i++) {
    if (tx1.outputs[i].serialize() != tx2.outputs[i].serialize()) {
      return false;
    }
  }
  for (int i = 0; i < tx1.inputs.length; i++) {
    if (tx1.inputs[i].serialize() != tx2.inputs[i].serialize()) {
      return false;
    }
  }
  return true;
}

/// ColdCard에서 최종화된 TXN으로 전달된 경우에 이 형식으로 분류될 수 있습니다.
bool isRawTransactionHexString(String data) {
  try {
    if (!isHexString(data)) return false;
    if (!data.startsWith(rawTxVersion1Field) && !data.startsWith(rawTxVersion2Field)) return false;
    return true;
  } catch (_) {
    return false;
  }
}
