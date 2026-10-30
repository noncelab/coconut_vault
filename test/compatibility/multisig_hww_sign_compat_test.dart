import 'dart:convert';
import 'dart:io';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/multisig_sign_view_model.dart';
import 'package:coconut_vault/providers/view_model/airgap/psbt_scanner_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// 와치온리 월렛 → coconut_vault → 타사 하드웨어 월렛(HWW) → coconut_vault 순서의
/// 2-of-2 멀티시그 공동서명 플로우가 호환되는지 검증한다.
///
/// ## 시나리오
/// 1. 와치온리 월렛(코코넛 월렛)이 서명 없는 PSBT를 만든다.
/// 2. coconut_vault가 PSBT를 스캔해 vault를 식별한다. (`PsbtScannerViewModel.setMatchingVault`)
/// 3. 서명 화면(MultisigSignScreen)에서 PSBT QR을 HWW에 보여주고, HWW가 2개 키 중 1개로 서명한다.
/// 4. coconut_vault가 HWW 서명 PSBT를 스캔해 병합한다. (`MultisigSignViewModel.onScannedPsbt`)
/// 5. coconut_vault가 나머지 1개 키로 서명한다. (`SignIsolates.addSignatureToPsbtWithMultisigVault`와 동일 경로)
/// 6. 최종 PSBT가 threshold를 충족하고, finalize한 트랜잭션이 유효한 witness를 갖는지 확인한다.
///
/// ## 테스트 지갑 구성 (2-of-2 P2WSH)
/// - signer별 니모닉은 fixture의 mnemonicKeys로 선택한다.
/// - signer별 passphrase는 같은 인덱스의 passphrases로 지정한다.
/// Krux는 같은 니모닉에 서로 다른 passphrase를, Jade는 서로 다른 니모닉을 사용한다.
/// HWW가 어느 signer로 서명했는지는 partialSig의 공개키로 자동 판별한다.
///
/// ## fixture 추가 방법
/// HWW에 전달한 PSBT와 HWW가 서명해서 돌려준 PSBT를 `_fixtures`에 넣는다.
/// - `unsignedPsbtBase64`: HWW에 보여준 서명 없는 PSBT
/// - `hwwSignedPsbtBase64`: HWW가 서명해서 돌려준 PSBT
/// - `networkType`, `accountIndex`는 실제 지갑 생성 조건에 맞게 수정한다.
/// - witness script 불일치로 실패하면 코디네이터의 서명자 순서가 다른 것이므로
///   `passphrases: ['1', '']`로 순서를 바꿔 본다.
/// - PSBT가 비어 있으면 skip된다.
///
/// ## 니모닉 설정
/// - `test/test.env` 파일에 `SKIRT_MNEMONIC`, `ABANDON_MNEMONIC` 등으로 설정 (커밋 금지).
Map<String, String> _loadMnemonics() {
  final result = <String, String>{};
  final envFile = File('test/test.env');
  if (envFile.existsSync()) {
    for (final line in envFile.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eqIndex = trimmed.indexOf('=');
      if (eqIndex <= 0) continue;
      final key = trimmed.substring(0, eqIndex).trim();
      var value = trimmed.substring(eqIndex + 1).trim();
      if ((value.startsWith("'") && value.endsWith("'")) || (value.startsWith('"') && value.endsWith('"'))) {
        value = value.substring(1, value.length - 1);
      }
      if (value.isNotEmpty) result[key] = value;
    }
  }
  return result;
}

class _HwwPsbtFixture {
  _HwwPsbtFixture({
    required this.name,
    required this.networkType,
    this.unsignedPsbtBase64 = '',
    this.hwwSignedPsbtBase64 = '',
    this.accountIndex = 0,
    this.passphrases = const ['', '1'],
    this.mnemonicKeys = const ['SKIRT_MNEMONIC', 'SKIRT_MNEMONIC'],
  });

  final String name;
  final NetworkType networkType;

  /// 와치온리 월렛이 만든 서명 없는 PSBT (= 볼트가 HWW에 보여준 PSBT)
  final String unsignedPsbtBase64;

  /// HWW가 2개 중 1개 키로 서명해서 돌려준 PSBT
  final String hwwSignedPsbtBase64;
  final int accountIndex;

  /// signer 순서. 기본 ['', '1'] = [passphrase 없음, passphrase '1'].
  final List<String> passphrases;

  /// test.env에서 사용할 니모닉 키 이름.
  final List<String> mnemonicKeys;

  bool get hasData => unsignedPsbtBase64.isNotEmpty && hwwSignedPsbtBase64.isNotEmpty;
}

final _fixtures = <_HwwPsbtFixture>[
  _HwwPsbtFixture(
    name: 'Krux',
    networkType: NetworkType.regtest,
    unsignedPsbtBase64:
        'cHNidP8K/Adjb2NvbnV0ASDtQiLewSz768m8HE3dfeHngxeT0CxRTNn/InYVRxzKEgEAhwIAAAACQfogaBWrl8MYmn+QuzHLZ3C58cSSZi31CCoMG+M7v1AAAAAAAP////9SVCUBi9rWIPsI0wWrd1jXCU7b8DR6SjPSLc4uKKDdmQAAAAAA/////wHaBgAAAAAAACIAIOtE2Ybfgb2rVJomQJ2zk4yAgG8dXNo65yWEOqJKubgMAAAAAE8BBDWHzwTb7CP7gAAAApdHV5wQ7aMrr6LJiR2pMpOMQ9hEFcHnA4tT3HEaqF1SA0Nkq/kh4uqpAGlZyJatcRpLqNeGQDkGfSCMJ+TBvvijFKOy63AwAACAAQAAgAAAAIACAACATwEENYfPBLfG0SSAAAACrfimj1fn5sFFdMhR/oPrLPt6H1S6bQa1UeDdDrqOlasCcL4mO+NM+8h3UkLMnQ2g1FAojvkAUTu+ff9OiGYz0SAUYhPZHjAAAIABAACAAAAAgAIAAIAAAQEr6AMAAAAAAAAiACDG17lZVQbbOdDYXeBrUVdcnjBVUiVRGxcICePVsyAWWQEDBAEAAAAiBgK05onik2sIV1uT4Pak40t7veXo80MMWSZMaj8MjxC+qRyjsutwMAAAgAEAAIAAAACAAgAAgAAAAAAIAAAAIgYDg1iresHYcYOmS5/KSEJHfmTcZekOw32jb2X61I5fuOUcYhPZHjAAAIABAACAAAAAgAIAAIAAAAAACAAAAAEFR1IhArTmieKTawhXW5Pg9qTjS3u95ejzQwxZJkxqPwyPEL6pIQODWKt6wdhxg6ZLn8pIQkd+ZNxl6Q7DfaNvZfrUjl+45VKuAAEBK+gDAAAAAAAAIgAgKoJighn0oGntrxmmgJkHrxu4+IwR0EeS5vNyBIbkje0BAwQBAAAAIgYDZnNO2Adx0sX4e/nNIGgJyn6jwh/D2YpKkNJLYibAnYsco7LrcDAAAIABAACAAAAAgAIAAIAAAAAABgAAACIGArQF/1eIlWTV0y6Ggx5p1Gb6/COjYgh0Xxx8pr7CgKOqHGIT2R4wAACAAQAAgAAAAIACAACAAAAAAAYAAAABBUdSIQK0Bf9XiJVk1dMuhoMeadRm+vwjo2IIdF8cfKa+woCjqiEDZnNO2Adx0sX4e/nNIGgJyn6jwh/D2YpKkNJLYibAnYtSrgAA',
    hwwSignedPsbtBase64:
        'cHNidP8BAIcCAAAAAkH6IGgVq5fDGJp/kLsxy2dwufHEkmYt9QgqDBvjO79QAAAAAAD/////UlQlAYva1iD7CNMFq3dY1wlO2/A0ekoz0i3OLiig3ZkAAAAAAP////8B2gYAAAAAAAAiACDrRNmG34G9q1SaJkCds5OMgIBvHVzaOuclhDqiSrm4DAAAAAAAAQEr6AMAAAAAAAAiACDG17lZVQbbOdDYXeBrUVdcnjBVUiVRGxcICePVsyAWWSICA4NYq3rB2HGDpkufykhCR35k3GXpDsN9o29l+tSOX7jlRzBEAiA3R8Q+7mLmU3SQv1LbsX1QtsaIVW4DTU93E+Tn2DGUTAIgb8n4IymxQ6TP+gWDRi1rqtPrZtWJfVXID3Q/u0rjvh8BAQVHUiECtOaJ4pNrCFdbk+D2pONLe73l6PNDDFkmTGo/DI8QvqkhA4NYq3rB2HGDpkufykhCR35k3GXpDsN9o29l+tSOX7jlUq4AAQEr6AMAAAAAAAAiACAqgmKCGfSgae2vGaaAmQevG7j4jBHQR5Lm83IEhuSN7SICArQF/1eIlWTV0y6Ggx5p1Gb6/COjYgh0Xxx8pr7CgKOqRzBEAiBOk4pAD11Moq/TXBtjbwpgMBkfCypAjluS0sNW7FAPJwIgJuqEcz902MjilRprnGMgK9K03Ir3digEO8EtYJF8RUwBAQVHUiECtAX/V4iVZNXTLoaDHmnUZvr8I6NiCHRfHHymvsKAo6ohA2ZzTtgHcdLF+Hv5zSBoCcp+o8Ifw9mKSpDSS2ImwJ2LUq4AAA==',
    accountIndex: 0,
    passphrases: const ['', '1'],
  ),
  _HwwPsbtFixture(
    name: 'SeedSigner',
    networkType: NetworkType.regtest,
    unsignedPsbtBase64:
        'cHNidP8K/Adjb2NvbnV0ASDtQiLewSz768m8HE3dfeHngxeT0CxRTNn/InYVRxzKEgEAhwIAAAACQfogaBWrl8MYmn+QuzHLZ3C58cSSZi31CCoMG+M7v1AAAAAAAP////9SVCUBi9rWIPsI0wWrd1jXCU7b8DR6SjPSLc4uKKDdmQAAAAAA/////wHaBgAAAAAAACIAIOtE2Ybfgb2rVJomQJ2zk4yAgG8dXNo65yWEOqJKubgMAAAAAE8BBDWHzwTb7CP7gAAAApdHV5wQ7aMrr6LJiR2pMpOMQ9hEFcHnA4tT3HEaqF1SA0Nkq/kh4uqpAGlZyJatcRpLqNeGQDkGfSCMJ+TBvvijFKOy63AwAACAAQAAgAAAAIACAACATwEENYfPBLfG0SSAAAACrfimj1fn5sFFdMhR/oPrLPt6H1S6bQa1UeDdDrqOlasCcL4mO+NM+8h3UkLMnQ2g1FAojvkAUTu+ff9OiGYz0SAUYhPZHjAAAIABAACAAAAAgAIAAIAAAQEr6AMAAAAAAAAiACDG17lZVQbbOdDYXeBrUVdcnjBVUiVRGxcICePVsyAWWQEDBAEAAAAiBgK05onik2sIV1uT4Pak40t7veXo80MMWSZMaj8MjxC+qRyjsutwMAAAgAEAAIAAAACAAgAAgAAAAAAIAAAAIgYDg1iresHYcYOmS5/KSEJHfmTcZekOw32jb2X61I5fuOUcYhPZHjAAAIABAACAAAAAgAIAAIAAAAAACAAAAAEFR1IhArTmieKTawhXW5Pg9qTjS3u95ejzQwxZJkxqPwyPEL6pIQODWKt6wdhxg6ZLn8pIQkd+ZNxl6Q7DfaNvZfrUjl+45VKuAAEBK+gDAAAAAAAAIgAgKoJighn0oGntrxmmgJkHrxu4+IwR0EeS5vNyBIbkje0BAwQBAAAAIgYDZnNO2Adx0sX4e/nNIGgJyn6jwh/D2YpKkNJLYibAnYsco7LrcDAAAIABAACAAAAAgAIAAIAAAAAABgAAACIGArQF/1eIlWTV0y6Ggx5p1Gb6/COjYgh0Xxx8pr7CgKOqHGIT2R4wAACAAQAAgAAAAIACAACAAAAAAAYAAAABBUdSIQK0Bf9XiJVk1dMuhoMeadRm+vwjo2IIdF8cfKa+woCjqiEDZnNO2Adx0sX4e/nNIGgJyn6jwh/D2YpKkNJLYibAnYtSrgAA',
    hwwSignedPsbtBase64:
        'cHNidP8BAIcCAAAAAkH6IGgVq5fDGJp/kLsxy2dwufHEkmYt9QgqDBvjO79QAAAAAAD/////UlQlAYva1iD7CNMFq3dY1wlO2/A0ekoz0i3OLiig3ZkAAAAAAP////8B2gYAAAAAAAAiACDrRNmG34G9q1SaJkCds5OMgIBvHVzaOuclhDqiSrm4DAAAAAAAIgICtOaJ4pNrCFdbk+D2pONLe73l6PNDDFkmTGo/DI8QvqlHMEQCIEjG3t43EpPX6FFNvSJIZY45Xv3K4H8HU5RJMwdeboGwAiAF6Q+Pa5+1ShrDCqM73q77/S9jJpoZCCs+L6ix83yzFAEAIgIDZnNO2Adx0sX4e/nNIGgJyn6jwh/D2YpKkNJLYibAnYtHMEQCIAXpCdwd1LyqZeF04iUrSHcfv9Cl0v2HTodX5RtYq9BdAiBhCnwM3JJtoAGCFwuocC6OY2T4cc/Iz1rLg7psoEPWAQEAAA==',
    accountIndex: 0,
    passphrases: const ['', '1'],
  ),
  _HwwPsbtFixture(
    name: 'ColdCard',
    networkType: NetworkType.regtest,
    unsignedPsbtBase64:
        'cHNidP8K/Adjb2NvbnV0ASCW3AH0+NcO8s5K/G7lpwkNcJvPyWWB7hSRSxw5dQy4FgEAXgIAAAAB95q3sWQaRN58pbOV/tXrridgCJCLpEffSYXpBtb5+N0AAAAAAP////8BclEAAAAAAAAiACCrs5T1vsbmB4gtKImJGt9AZgCq6T3EZoAj6Yx/1VETqAAAAABPAQQ1h88E2+wj+4AAAAKXR1ecEO2jK6+iyYkdqTKTjEPYRBXB5wOLU9xxGqhdUgNDZKv5IeLqqQBpWciWrXEaS6jXhkA5Bn0gjCfkwb74oxSjsutwMAAAgAEAAIAAAACAAgAAgE8BBDWHzwS6wUg5gAAAAh1Pvr3ZZ+GvcUwJl9OPz2cLXOnTAcBEC7zDtqIOt3IcA1aOofNgUZFu0baQw54SqOcGA7KAvTDOXygfKRilU2OqFHPF2gowAACAAQAAgAAAAIACAACAAAEBKwhSAAAAAAAAIgAgEbNJRpyYK/VdcGrcHcQjF6H6hZMLLwllGDhfIlrxg0MBAwQBAAAAIgYClEVPXmDO7BRGz7ZUuh6avSy1s6t52xuZUyZVNcsWJTAco7LrcDAAAIABAACAAAAAgAIAAIAAAAAABwAAACIGA5SIcTDQi+4iCIU7c3MNkDStKGNJpHJuYSH3kEfh8ahhHHPF2gowAACAAQAAgAAAAIACAACAAAAAAAcAAAABBUdSIQKURU9eYM7sFEbPtlS6Hpq9LLWzq3nbG5lTJlU1yxYlMCEDlIhxMNCL7iIIhTtzcw2QNK0oY0mkcm5hIfeQR+HxqGFSrgAA',
    hwwSignedPsbtBase64:
        'cHNidP8BAF4CAAAAAfeat7FkGkTefKWzlf7V664nYAiQi6RH30mF6QbW+fjdAAAAAAD/////AXJRAAAAAAAAIgAgq7OU9b7G5geILSiJiRrfQGYAquk9xGaAI+mMf9VRE6gAAAAATwEENYfPBNvsI/uAAAACl0dXnBDtoyuvosmJHakyk4xD2EQVwecDi1PccRqoXVIDQ2Sr+SHi6qkAaVnIlq1xGkuo14ZAOQZ9IIwn5MG++KMUo7LrcDAAAIABAACAAAAAgAIAAIBPAQQ1h88EusFIOYAAAAIdT7692Wfhr3FMCZfTj89nC1zp0wHARAu8w7aiDrdyHANWjqHzYFGRbtG2kMOeEqjnBgOygL0wzl8oHykYpVNjqhRzxdoKMAAAgAEAAIAAAACAAgAAgAr8B2NvY29udXQBIJbcAfT41w7yzkr8buWnCQ1wm8/JZYHuFJFLHDl1DLgWAAEBKwhSAAAAAAAAIgAgEbNJRpyYK/VdcGrcHcQjF6H6hZMLLwllGDhfIlrxg0MiAgOUiHEw0IvuIgiFO3NzDZA0rShjSaRybmEh95BH4fGoYUcwRAIgXk8KKKh5Ootnkd3Eo0wfpiFOE1KL7vAcKrf80++/cPcCIB39xc7KAxDCuv+4PY3Qgw/v6R8wkRCjFKyDsA4sBkddASIGA5SIcTDQi+4iCIU7c3MNkDStKGNJpHJuYSH3kEfh8ahhHHPF2gowAACAAQAAgAAAAIACAACAAAAAAAcAAAAiBgKURU9eYM7sFEbPtlS6Hpq9LLWzq3nbG5lTJlU1yxYlMByjsutwMAAAgAEAAIAAAACAAgAAgAAAAAAHAAAAAQVHUiEClEVPXmDO7BRGz7ZUuh6avSy1s6t52xuZUyZVNcsWJTAhA5SIcTDQi+4iCIU7c3MNkDStKGNJpHJuYSH3kEfh8ahhUq4AAA==',
    accountIndex: 0,
    passphrases: const ['', ''],
    mnemonicKeys: const ['SKIRT_MNEMONIC', 'ABANDON_MNEMONIC'],
  ),
  _HwwPsbtFixture(
    name: 'Keystone',
    networkType: NetworkType.mainnet,
    unsignedPsbtBase64:
        'cHNidP8K/Adjb2NvbnV0ASDPSiBRUdNOU6I5AYohiAFdYmUwVd3MtKLqwM+zS34kvwEAUgIAAAABVurTSjy9U2ifWJCwQ/raopg4e8wmSARli21m3S0B6BMBAAAAAP////8B9R0AAAAAAAAWABSFGalkOR7or/Epforl+vGUszVq1QAAAABPAQSIsh4EMI+wLIAAAAJhqYYNWNbIGWbPFb35UxZvQJiX+6VMLWxB80mViCAA9gOejHVFMB+skMPpbVmGnUbkJ5fBCNSpeudCPQBvpm3GeRSg9roAMAAAgAAAAIAAAACAAgAAgE8BBIiyHgRUZIFKgAAAAjoaa0fvpOtltmr4IYXfGsRnwWfJyLzbbOd5ECyBHmUkAlMRGdUMDI1HVhD+F5w1BKUgXrAGPBjndMu/NUpTKF/1FKOy63AwAACAAAAAgAAAAIACAACAAAEBK0weAAAAAAAAIgAgnqdtRqC/5g+/YB2y1mKoQrUwZALv4glfe3/hdvKG4Z4BAwQBAAAAIgYCKS+SZT5BXQVquXzyxGnRmiGv3lju1H5GBsn1bcdoxsIcoPa6ADAAAIAAAACAAAAAgAIAAIABAAAAAQAAACIGAs8UG5DCgiGrEJiPYiQth9JN+EP/z30vWh/6QDvfdDUdHKOy63AwAACAAAAAgAAAAIACAACAAQAAAAEAAAABBUdSIQIpL5JlPkFdBWq5fPLEadGaIa/eWO7UfkYGyfVtx2jGwiECzxQbkMKCIasQmI9iJC2H0k34Q//PfS9aH/pAO990NR1SrgAA',
    hwwSignedPsbtBase64:
        'cHNidP8BAFICAAAAAVbq00o8vVNon1iQsEP62qKYOHvMJkgEZYttZt0tAegTAQAAAAD/////AfUdAAAAAAAAFgAUhRmpZDke6K/xKX6K5frxlLM1atUAAAAATwEEiLIeBDCPsCyAAAACYamGDVjWyBlmzxW9+VMWb0CYl/ulTC1sQfNJlYggAPYDnox1RTAfrJDD6W1Zhp1G5CeXwQjUqXrnQj0Ab6ZtxnkUoPa6ADAAAIAAAACAAAAAgAIAAIBPAQSIsh4EVGSBSoAAAAI6GmtH76TrZbZq+CGF3xrEZ8Fnyci822zneRAsgR5lJAJTERnVDAyNR1YQ/hecNQSlIF6wBjwY53TLvzVKUyhf9RSjsutwMAAAgAAAAIAAAACAAgAAgAr8B2NvY29udXQBIM9KIFFR005TojkBiiGIAV1iZTBV3cy0ourAz7NLfiS/AAEBK0weAAAAAAAAIgAgnqdtRqC/5g+/YB2y1mKoQrUwZALv4glfe3/hdvKG4Z4iAgIpL5JlPkFdBWq5fPLEadGaIa/eWO7UfkYGyfVtx2jGwkgwRQIhAPexL3ZdG+1V9DZdscFh2me6yT8AGEke7o/GoVrcqYuGAiA/wRvQZTJDRpe/Eot3hbFOPuyFYJp0402jqqbWm+RLwgEBAwQBAAAAAQVHUiECKS+SZT5BXQVquXzyxGnRmiGv3lju1H5GBsn1bcdoxsIhAs8UG5DCgiGrEJiPYiQth9JN+EP/z30vWh/6QDvfdDUdUq4iBgIpL5JlPkFdBWq5fPLEadGaIa/eWO7UfkYGyfVtx2jGwhyg9roAMAAAgAAAAIAAAACAAgAAgAEAAAABAAAAIgYCzxQbkMKCIasQmI9iJC2H0k34Q//PfS9aH/pAO990NR0co7LrcDAAAIAAAACAAAAAgAIAAIABAAAAAQAAAAAA',
    accountIndex: 0,
    passphrases: const ['', ''],
    mnemonicKeys: const ['SKIRT_MNEMONIC', 'PRISON_MNEMONIC'],
  ),
  _HwwPsbtFixture(
    name: 'Jade',
    networkType: NetworkType.regtest,
    unsignedPsbtBase64:
        'cHNidP8K/Adjb2NvbnV0ASCW3AH0+NcO8s5K/G7lpwkNcJvPyWWB7hSRSxw5dQy4FgEAXgIAAAAB95q3sWQaRN58pbOV/tXrridgCJCLpEffSYXpBtb5+N0AAAAAAP////8BclEAAAAAAAAiACCrs5T1vsbmB4gtKImJGt9AZgCq6T3EZoAj6Yx/1VETqAAAAABPAQQ1h88E2+wj+4AAAAKXR1ecEO2jK6+iyYkdqTKTjEPYRBXB5wOLU9xxGqhdUgNDZKv5IeLqqQBpWciWrXEaS6jXhkA5Bn0gjCfkwb74oxSjsutwMAAAgAEAAIAAAACAAgAAgE8BBDWHzwS6wUg5gAAAAh1Pvr3ZZ+GvcUwJl9OPz2cLXOnTAcBEC7zDtqIOt3IcA1aOofNgUZFu0baQw54SqOcGA7KAvTDOXygfKRilU2OqFHPF2gowAACAAQAAgAAAAIACAACAAAEBKwhSAAAAAAAAIgAgEbNJRpyYK/VdcGrcHcQjF6H6hZMLLwllGDhfIlrxg0MBAwQBAAAAIgYClEVPXmDO7BRGz7ZUuh6avSy1s6t52xuZUyZVNcsWJTAco7LrcDAAAIABAACAAAAAgAIAAIAAAAAABwAAACIGA5SIcTDQi+4iCIU7c3MNkDStKGNJpHJuYSH3kEfh8ahhHHPF2gowAACAAQAAgAAAAIACAACAAAAAAAcAAAABBUdSIQKURU9eYM7sFEbPtlS6Hpq9LLWzq3nbG5lTJlU1yxYlMCEDlIhxMNCL7iIIhTtzcw2QNK0oY0mkcm5hIfeQR+HxqGFSrgAA',
    hwwSignedPsbtBase64:
        'cHNidP8BAF4CAAAAAfeat7FkGkTefKWzlf7V664nYAiQi6RH30mF6QbW+fjdAAAAAAD/////AXJRAAAAAAAAIgAgq7OU9b7G5geILSiJiRrfQGYAquk9xGaAI+mMf9VRE6gAAAAATwEENYfPBNvsI/uAAAACl0dXnBDtoyuvosmJHakyk4xD2EQVwecDi1PccRqoXVIDQ2Sr+SHi6qkAaVnIlq1xGkuo14ZAOQZ9IIwn5MG++KMUo7LrcDAAAIABAACAAAAAgAIAAIBPAQQ1h88EusFIOYAAAAIdT7692Wfhr3FMCZfTj89nC1zp0wHARAu8w7aiDrdyHANWjqHzYFGRbtG2kMOeEqjnBgOygL0wzl8oHykYpVNjqhRzxdoKMAAAgAEAAIAAAACAAgAAgAr8B2NvY29udXQBIJbcAfT41w7yzkr8buWnCQ1wm8/JZYHuFJFLHDl1DLgWAAEBKwhSAAAAAAAAIgAgEbNJRpyYK/VdcGrcHcQjF6H6hZMLLwllGDhfIlrxg0MiAgOUiHEw0IvuIgiFO3NzDZA0rShjSaRybmEh95BH4fGoYUcwRAIgXk8KKKh5Ootnkd3Eo0wfpiFOE1KL7vAcKrf80++/cPcCIB39xc7KAxDCuv+4PY3Qgw/v6R8wkRCjFKyDsA4sBkddAQEDBAEAAAABBUdSIQKURU9eYM7sFEbPtlS6Hpq9LLWzq3nbG5lTJlU1yxYlMCEDlIhxMNCL7iIIhTtzcw2QNK0oY0mkcm5hIfeQR+HxqGFSriIGApRFT15gzuwURs+2VLoemr0stbOredsbmVMmVTXLFiUwHKOy63AwAACAAQAAgAAAAIACAACAAAAAAAcAAAAiBgOUiHEw0IvuIgiFO3NzDZA0rShjSaRybmEh95BH4fGoYRxzxdoKMAAAgAEAAIAAAACAAgAAgAAAAAAHAAAAAAA=',
    accountIndex: 0,
    passphrases: const ['', ''],
    mnemonicKeys: const ['SKIRT_MNEMONIC', 'ABANDON_MNEMONIC'],
  ),
];

void main() {
  final mnemonics = _loadMnemonics();

  group('와치온리 → 볼트 → HWW(1/2 서명) → 볼트(2/2 서명) 공동서명 호환성', () {
    test('자체 생성 PSBT sanity check (signer 0을 HWW로 가정, fixture 없이 항상 실행)', () async {
      NetworkType.setNetworkType(NetworkType.regtest);
      const testMnemonic = 'machine crack daughter fish credit glare raven fever tunnel delay fish record';
      final vault = _create2of2Vault([testMnemonic, testMnemonic], passphrases: const ['', '1']);
      final utxos = [
        Utxo(Codec.encodeHex(Hash.sha256('hww-compat-utxo-0')), 0, 100000, "m/48'/1'/0'/2'/0/0"),
        Utxo(Codec.encodeHex(Hash.sha256('hww-compat-utxo-1')), 0, 110000, "m/48'/1'/0'/2'/0/1"),
      ];
      final tx = Transaction.forSinglePayment(
        utxos,
        vault.getAddress(1),
        '${vault.derivationPath}/1/1',
        15000,
        3,
        vault,
      );
      final unsignedPsbtBase64 = Psbt.fromTransaction(tx, vault).serialize();
      // HWW 서명 흉내: signer 0 키로만 서명
      final hwwSignedPsbtBase64 = vault.keyStoreList[0].addSignatureToPsbt(unsignedPsbtBase64, AddressType.p2wsh);

      await _runHwwCosignFlow(
        name: 'self-generated',
        vault: vault,
        unsignedPsbtBase64: unsignedPsbtBase64,
        hwwSignedPsbtBase64: hwwSignedPsbtBase64,
      );
    });

    for (final fixture in _fixtures) {
      _hwwSignCompatTest(fixture: fixture, mnemonics: mnemonics);
    }
  });
}

void _hwwSignCompatTest({required _HwwPsbtFixture fixture, required Map<String, String> mnemonics}) {
  test('${fixture.name}: HWW 1개 서명 PSBT 스캔 → 볼트가 나머지 서명 → 서명 완료', () async {
    if (!fixture.hasData) {
      markTestSkipped('${fixture.name} PSBT 데이터(unsigned / hww-signed)가 아직 입력되지 않음');
      return;
    }
    expect(fixture.mnemonicKeys, hasLength(2));
    expect(fixture.passphrases, hasLength(2));
    final missingKeys = fixture.mnemonicKeys.where((key) => mnemonics[key]?.trim().isNotEmpty != true).toSet();
    if (missingKeys.isNotEmpty) {
      markTestSkipped('test/test.env에 ${missingKeys.join(', ')}이 설정되지 않음');
      return;
    }

    NetworkType.setNetworkType(fixture.networkType);

    final vault = _create2of2Vault(
      fixture.mnemonicKeys.map((key) => mnemonics[key]!).toList(),
      passphrases: fixture.passphrases,
      accountIndex: fixture.accountIndex,
    );

    await _runHwwCosignFlow(
      name: fixture.name,
      vault: vault,
      unsignedPsbtBase64: fixture.unsignedPsbtBase64,
      hwwSignedPsbtBase64: fixture.hwwSignedPsbtBase64,
    );
  });
}

Future<void> _runHwwCosignFlow({
  required String name,
  required MultisignatureVault vault,
  required String unsignedPsbtBase64,
  required String hwwSignedPsbtBase64,
}) async {
  final unsignedPsbt = Psbt.parse(unsignedPsbtBase64);
  final hwwSignedPsbt = Psbt.parse(hwwSignedPsbtBase64);

  // ── Step 1. 와치온리 PSBT 스캔: vault 식별 ──
  bool matchesVaultResult = false;
  Object? matchesVaultError;
  try {
    matchesVaultResult = unsignedPsbt.matchesVault(vault);
  } catch (e) {
    matchesVaultError = e;
  }
  expect(
    matchesVaultResult,
    isTrue,
    reason:
        matchesVaultError != null
            ? 'matchesVault 예외 발생: $matchesVaultError'
            : 'matchesVault가 false. 와치온리 PSBT가 vault 정책 검증을 충족하지 않음.',
  );
  expect(
    unsignedPsbt.inputs.every((input) => (input.partialSig ?? const []).isEmpty),
    isTrue,
    reason: 'unsignedPsbtBase64에 이미 서명이 들어 있음. 와치온리 월렛이 만든 원본 PSBT를 넣어야 함.',
  );

  final vaultItem = MultisigVaultListItem(
    id: 1,
    name: '$name compat vault',
    colorIndex: 0,
    iconIndex: 0,
    signers:
        vault.keyStoreList.indexed
            .map((entry) => MultisigSigner(id: entry.$1, name: 'signer ${entry.$1}', keyStore: entry.$2))
            .toList(),
    requiredSignatureCount: 2,
    createdAt: DateTime(2026),
  );
  final signProvider = SignProvider();
  final scannerViewModel = PsbtScannerViewModel(_FakeWalletProvider([vaultItem]), signProvider);
  scannerViewModel.saveUnsignedPsbt(unsignedPsbtBase64);
  await scannerViewModel.setMatchingVault(unsignedPsbtBase64);
  expect(signProvider.vaultListItem, same(vaultItem));
  // psbt_confirmation 단계에서 저장하는 값
  signProvider.savePsbt(unsignedPsbt);

  // ── Step 2. 서명 화면 진입 ──
  // isSigningOnlyMode=true: passphrase 조회(WalletProvider.hasPassphrase)를 건너뛰기 위함
  final signViewModel = MultisigSignViewModel(_FakeWalletProvider([vaultItem]), signProvider, true);
  signViewModel.initPsbtSignState();
  expect(signViewModel.signersApproved, everyElement(isFalse));
  expect(signViewModel.remainingSignatures, 2);

  // ── Step 3. HWW가 서명한 PSBT 검증 ──
  expect(
    signViewModel.hasSameTransactionBody(hwwSignedPsbtBase64),
    isTrue,
    reason: 'HWW가 돌려준 PSBT의 트랜잭션 본문이 볼트가 보여준 PSBT와 다름.',
  );
  // HWW가 서명한 signer 식별: bip32Derivation이 있으면 mfp로, 없으면 pubkey로 vault signer와 대조
  final hwwSignerIndexes = _findSignedSignerIndexes(vault, hwwSignedPsbt, unsignedPsbt: unsignedPsbt);
  expect(hwwSignerIndexes, hasLength(1), reason: 'HWW PSBT에는 정확히 1개 signer의 서명만 있어야 함.');
  for (int i = 0; i < hwwSignedPsbt.inputs.length; i++) {
    final sigs = hwwSignedPsbt.inputs[i].partialSig ?? const <Signature>[];
    expect(sigs, hasLength(1), reason: 'input[$i]의 partialSig 개수가 1이 아님.');
    expect(
      unsignedPsbt.validateSignature(i, sigs.first.signature, sigs.first.publicKey),
      isTrue,
      reason: 'input[$i]의 HWW 서명이 유효하지 않음 (sighash 불일치 가능).',
    );
  }

  // ── Step 4. 볼트에서 HWW PSBT 스캔 → 서명 병합 ──
  signViewModel.onScannedPsbt(hwwSignedPsbtBase64);
  final hwwSignerIndex = hwwSignerIndexes.single;
  for (int i = 0; i < vault.keyStoreList.length; i++) {
    expect(signViewModel.signersApproved[i], i == hwwSignerIndex, reason: 'signer $i 승인 상태가 예상과 다름.');
  }
  expect(signViewModel.remainingSignatures, 1);
  expect(signViewModel.isSignatureCompleted, isFalse);

  // ── Step 5. 볼트가 나머지 signer로 서명 ──
  // MultisigSignViewModel.sign은 compute + 앱 flavor 기반 네트워크 설정을 타므로,
  // isolate 내부와 동일한 keyStore.addSignatureToPsbt 경로를 직접 호출한다.
  final vaultSignerIndex = List.generate(vault.keyStoreList.length, (i) => i).firstWhere((i) => i != hwwSignerIndex);
  expect(Psbt.parse(signViewModel.psbtForSigning).matchesVault(vaultItem.coconutVault), isTrue);
  final fullySignedPsbtBase64 = vault.keyStoreList[vaultSignerIndex].addSignatureToPsbt(
    signViewModel.psbtForSigning,
    AddressType.p2wsh,
  );
  signViewModel.updatePsbt(fullySignedPsbtBase64);
  signViewModel.updateSignState(vaultSignerIndex);
  expect(signViewModel.isSignatureCompleted, isTrue);

  // ── Step 6. 최종 PSBT 검증 ──
  final fullySignedPsbt = Psbt.parse(fullySignedPsbtBase64);
  expect(
    fullySignedPsbt.inputs.every((input) => input.signedCount >= input.requiredSignature),
    isTrue,
    reason: '볼트 서명 후에도 서명 수가 threshold에 미달.',
  );
  expect(_findSignedSignerIndexes(vault, fullySignedPsbt), {0, 1});

  final signedTx = fullySignedPsbt.getSignedTransaction(AddressType.p2wsh);
  final prevouts = fullySignedPsbt.inputs.map((input) => input.witnessUtxo!).toList();
  expect(signedTx.validateSpend(prevouts), isTrue, reason: 'finalize한 트랜잭션의 witness 검증 실패.');
}

/// input[0]의 partialSig 공개키를 vault signer와 대조해 서명한 signer index를 찾는다.
/// bip32Derivation이 있으면 mfp+path로, 없으면(Krux 등) unsignedPsbt의 pubkey로 대조한다.
Set<int> _findSignedSignerIndexes(MultisignatureVault vault, Psbt psbt, {Psbt? unsignedPsbt}) {
  final input = psbt.inputs.first;
  final result = <int>{};
  for (final sig in input.partialSig ?? const <Signature>[]) {
    // 1) signed PSBT에 bip32Derivation이 있으면 mfp로 식별
    final derivation = input.bip32Derivation?.where((d) => d.publicKey == sig.publicKey).firstOrNull;
    if (derivation != null) {
      final index = vault.keyStoreList.indexWhere(
        (keyStore) => keyStore.masterFingerprint.toUpperCase() == derivation.masterFingerprint,
      );
      if (index != -1) result.add(index);
      continue;
    }
    // 2) bip32Derivation이 없으면 unsignedPsbt의 derivation에서 pubkey → vault signer 매핑
    if (unsignedPsbt != null) {
      final unsignedInput = unsignedPsbt.inputs.first;
      final unsignedDerivation = unsignedInput.bip32Derivation?.where((d) => d.publicKey == sig.publicKey).firstOrNull;
      if (unsignedDerivation != null) {
        final index = vault.keyStoreList.indexWhere(
          (keyStore) => keyStore.masterFingerprint.toUpperCase() == unsignedDerivation.masterFingerprint,
        );
        if (index != -1) result.add(index);
      }
    }
  }
  return result;
}

MultisignatureVault _create2of2Vault(
  List<String> mnemonics, {
  required List<String> passphrases,
  int accountIndex = 0,
}) {
  if (mnemonics.length != 2 || passphrases.length != 2) {
    throw ArgumentError('2-of-2 vault에는 signer별 니모닉과 passphrase가 각각 2개 필요함');
  }
  final keyStores =
      passphrases.indexed.map((entry) {
        final passphrase = entry.$2;
        final seed = Seed.fromMnemonic(
          utf8.encode(mnemonics[entry.$1]),
          passphrase: passphrase.isEmpty ? null : utf8.encode(passphrase),
        );
        return KeyStore.fromSeed(seed, AddressType.p2wsh, accountIndex: accountIndex);
      }).toList();
  return MultisignatureVault.fromKeyStoreList(keyStores, 2);
}

class _FakeWalletProvider implements WalletProvider {
  _FakeWalletProvider(this._vaultList) : _isLoaded = true;

  final List<VaultListItemBase> _vaultList;
  final bool _isLoaded;

  @override
  bool get isVaultsLoaded => _isLoaded;

  @override
  List<VaultListItemBase> get vaultList => _vaultList;

  @override
  VaultListItemBase getVaultById(int id) => _vaultList.firstWhere((vault) => vault.id == id);

  @override
  Future<void> loadVaultList() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
