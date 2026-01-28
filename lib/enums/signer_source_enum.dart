import 'package:coconut_vault/constants/icon_path.dart';

enum SignerSource { coconutvault, keystone3pro, seedsigner, jade, coldCard, krux }

/// 외부지갑 기기 종류에 따른 아이콘 경로 매핑
class SignerSourceIconMap {
  static const Map<SignerSource, String> signerIconMap = {
    SignerSource.coconutvault: kCoconutVaultIconPath,
    SignerSource.keystone3pro: kKeystoneIconPath,
    SignerSource.seedsigner: kSeedSignerIconPath,
    SignerSource.jade: kJadeIconPath,
    SignerSource.coldCard: kColdCardIconPath,
    SignerSource.krux: kKruxIconPath,
  };

  static String getIconSource(SignerSource? signerSource) {
    return signerIconMap[signerSource] ?? kAddCircleOutlinedIconPath;
  }

  static SignerSource? getSignerSourceByIconPath(String iconPath) {
    return signerIconMap.entries.firstWhere((element) => element.value == iconPath).key as SignerSource?;
  }
}
