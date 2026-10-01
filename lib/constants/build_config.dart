import 'package:coconut_lib/coconut_lib.dart';

/// Compile-time build variant flag for the lite (signing-only) app.
///
/// True when the Flutter flavor is a lite variant (`liteMainnet`/`liteRegtest`).
/// `FLUTTER_APP_FLAVOR` is injected automatically by the Flutter tool when
/// `--flavor` is passed. Used together with the lite entrypoint
/// (`lib/main_lite.dart`) so that secure-storage-only code paths can be
/// tree-shaken away.
const String _appFlavor = String.fromEnvironment('FLUTTER_APP_FLAVOR');

const bool kIsLiteBuild = _appFlavor == 'liteMainnet' || _appFlavor == 'liteRegtest';

/// 패스프레이즈를 NFKD로 정규화하지 않고 지갑을 만들던 마지막 앱 버전.
/// 그 방식으로 만든 지갑을 가져올 수 있는 full 빌드에서만 값이 있고, 그 외에는 null이다.
const String? kLastUnnormalizedPassphraseVersion =
    _appFlavor == 'fullMainnet' ? '3.2.0' : (_appFlavor == 'fullRegtest' ? '5.2.0' : null);

/// 컴파일 타임 앱 flavor로 글로벌 [NetworkType]을 설정합니다.
///
/// flavor 이름이 `fullMainnet`/`liteMainnet`처럼 camelCase 조합이므로
/// 소문자로 변환 후 비교합니다. isolate 간 static 상태가 공유되지 않으므로
/// 각 isolate 엔트리포인트에서도 호출해야 합니다.
void setNetworkTypeFromAppFlavor() {
  NetworkType.setNetworkType(_appFlavor.toLowerCase().contains('mainnet') ? NetworkType.mainnet : NetworkType.regtest);
}
