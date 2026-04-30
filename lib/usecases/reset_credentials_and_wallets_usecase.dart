import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/repository/wallet_storage_cleaner.dart';

/// 사용자 신원(PIN/biometric)과 모든 vault 데이터를 초기화하는 usecase.
///
/// 정리 대상:
/// - 모든 vault 데이터: SecureZone alias, FlutterSecureStorage, SharedPrefs vault 메타
///   (`kVaultListField`, `vaultListLength`, `kNextIdField`)
/// - 인증 상태: PIN, biometric 토글, lockout 기록
/// - vault 정렬 정보: vault 순서, 즐겨찾기
///
/// 보존 항목 (사용자 UX 설정):
/// - 패스프레이즈 사용 여부 (`kPassphraseUseEnabled`)
/// - 계정 변경 사용 여부 (`kChangeAccountEnabled`)
/// - 언어, BTC 단위, vault 모드, edge panel 위치 등
///
/// 사용처 예시:
/// - 비밀번호 분실 후 초기화 (PinCheckScreen)
/// - PIN 시도 횟수 초과 (PinCheckScreen)
/// - 보안 영역 접근 불가 -> 데이터 삭제 (precheck 화면들)
class ResetCredentialsAndWalletsUsecase {
  ResetCredentialsAndWalletsUsecase._();

  /// 서명 전용 모드로 지갑 추가해서 사용 중
  /// 앱 백그라운드 갔다가 돌아왔을 때 JailBreak 감지 또는 기기 비번 해제 후 재설정 된 경우
  /// [walletProvider]가 위젯 트리에 등록된 상태면 전달하세요.
  /// 인메모리 vault list까지 함께 정리되고 listener가 통지됩니다.
  /// null이면 [WalletStorageCleaner.clearAll]로 영속 데이터만 직접 정리합니다.
  /// 화면 reload(`reloadRelatedToVault` 등)가 필요하면 호출 측에서 별도로 수행하세요.
  static Future<void> execute({
    WalletProvider? walletProvider,
    required AuthProvider authProvider,
    required PreferenceProvider preferenceProvider,
  }) async {
    if (walletProvider != null) {
      await walletProvider.reset();
    } else {
      await WalletStorageCleaner.clearAll();
    }
    await preferenceProvider.resetVaultOrderAndFavorites();
    await authProvider.resetCredentials();
  }
}
